#!/usr/bin/env python3
"""
Grok/JSON parse-failure golden-file tests (pipeline-tests, Workstream H).

SCOPE: this is a re-implementation of the sshd auth.log grok pattern and the
Zeek ndjson parsing behavior from scripts/setup/configs/logstash/logstash.conf,
for fast fixture tests without a live Logstash. It validates parsing
LOGIC/intent, NOT the actual compiled grok engine that runs in the container —
a syntax drift between this regex and the real pattern would not be caught
here. The sshd regex below is a direct manual translation of the exact grok
pattern in logstash.conf's auth.log block; keep them in sync by hand.

Covers both parse-failure classes the pipeline tags (Category 3, "Operational
Metadata Enrichment" -> [pipeline][error] -> quarantine-index routing):
  * _grokparsefailure — sshd auth.log lines that don't match the anchored
    grok pattern (logstash.conf, auth.log block)
  * _jsonparsefailure  — malformed Zeek ndjson lines (the Category 1 json filter)

Run:  python tests/pipeline/test_grok_parse_failures.py  (or: pytest tests/pipeline)
"""

import json
import re
import unittest

# Direct translation of logstash.conf's sshd grok pattern:
#   ^%{SYSLOGTIMESTAMP:timestamp} %{HOSTNAME:host.name} sshd(?:-session|-auth)?\[%{POSINT:process.pid}\]:
#   %{WORD:event.outcome} %{NOTSPACE:system.auth.method} for (?:invalid user )?
#   %{GREEDYDATA:user.name} from %{IP:source.ip} port %{POSINT:source.port}
#   (?:\s+ssh2)?\s*$
# sshd(?:-session|-auth)? covers the classic single `sshd` process AND
# OpenSSH 9.8+'s re-exec'd `sshd-session` / 10.0+'s pre-auth `sshd-auth`.
_IPV4 = r"(?:(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)\.){3}(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)"
_IPV6 = r"(?:[0-9a-fA-F]{0,4}:){2,7}[0-9a-fA-F]{0,4}"
SSHD_PATTERN = re.compile(
    r"^(?P<timestamp>[A-Z][a-z]{2}\s+\d{1,2}\s\d{2}:\d{2}:\d{2})\s"
    r"(?P<host_name>[a-zA-Z0-9.-]+)\ssshd(?:-session|-auth)?\[(?P<pid>[1-9][0-9]*)\]:\s"
    r"(?P<outcome>\w+)\s(?P<auth_method>\S+)\sfor\s(?:invalid user )?"
    rf"(?P<user_name>.*)\sfrom\s(?P<source_ip>{_IPV4}|{_IPV6})\sport\s"
    r"(?P<source_port>[1-9][0-9]*)(?:\s+ssh2)?\s*$"
)

# The pipeline's cheap pre-filter (logstash.conf's auth.log block) — grok
# never even runs unless this matches, regardless of the rest of the line.
AUTH_LOG_PATH = "auth.log"
SSHD_TAG = re.compile(r"sshd(-session|-auth)?\[")


def sshd_grok_match(message: str, log_path: str = AUTH_LOG_PATH):
    """Mirrors the pipeline's two-stage gate: path pre-filter, sshd
    process-tag pre-filter, then grok.

    Returns "skipped" (a pre-filter excluded it — never reaches grok, e.g. a
    non-sshd auth.log line like sudo/cron/PAM, or a non-auth.log path),
    "match" (grok succeeded), or "grokparsefailure" (reached grok, didn't
    match — what the pipeline tags _grokparsefailure)."""
    if AUTH_LOG_PATH not in log_path or not SSHD_TAG.search(message):
        return "skipped"
    return "match" if SSHD_PATTERN.match(message) else "grokparsefailure"


def zeek_json_parse(line: str):
    """Mirrors the Category 1 json filter (source => "message") reading a
    network_logs-tagged line — returns "match" or "jsonparsefailure" (what
    the pipeline tags)."""
    try:
        json.loads(line)
        return "match"
    except (json.JSONDecodeError, ValueError):
        return "jsonparsefailure"


class SshdGrokTests(unittest.TestCase):
    def test_valid_failed_password(self):
        msg = "Jul  8 10:15:23 dragon-zord sshd[12345]: Failed password for admin from 203.0.113.7 port 51422 ssh2"
        self.assertEqual(sshd_grok_match(msg), "match")

    def test_valid_accepted_publickey(self):
        msg = "Jul  8 10:16:01 dragon-zord sshd[12346]: Accepted publickey for tjlam from 198.51.100.4 port 22 ssh2"
        self.assertEqual(sshd_grok_match(msg), "match")

    def test_valid_failed_password_invalid_user(self):
        # "invalid user" phrasing INSIDE the verb+for structure — the
        # (?:invalid user )? optional group captures brute-force attempts
        # against non-existent accounts.
        msg = "Jul  8 10:17:45 dragon-zord sshd[12347]: Failed password for invalid user root from 203.0.113.9 port 51500 ssh2"
        self.assertEqual(sshd_grok_match(msg), "match")

    def test_valid_ipv6_source(self):
        msg = "Jul  8 10:18:02 dragon-zord sshd[12348]: Failed password for admin from 2001:db8::dead:beef port 51501 ssh2"
        self.assertEqual(sshd_grok_match(msg), "match")

    def test_standalone_invalid_user_line_not_parsed(self):
        # sshd's OTHER "Invalid user X from Y port Z" log line has no verb
        # ("Failed"/"Accepted") and no auth method — a structurally different
        # message the pattern was never written to match. This is a REAL,
        # currently-unhandled grok parse failure, not a hypothetical.
        msg = "Jul  8 10:19:10 dragon-zord sshd[12349]: Invalid user backup from 203.0.113.11 port 51600"
        self.assertEqual(sshd_grok_match(msg), "grokparsefailure")

    def test_truncated_line_missing_port(self):
        msg = "Jul  8 10:20:00 dragon-zord sshd[12350]: Failed password for admin from 203.0.113.12"
        self.assertEqual(sshd_grok_match(msg), "grokparsefailure")

    def test_empty_message_is_skipped_not_failed(self):
        # No sshd process tag -> excluded by the pre-filter before grok ever runs.
        self.assertEqual(sshd_grok_match(""), "skipped")

    def test_modern_openssh_sshd_session_tag(self):
        # OpenSSH 9.8+ re-execs into a per-connection sshd-session process;
        # auth events land under this tag instead of bare sshd[PID]. Must
        # still reach grok and match — this is the regression the pre-filter
        # broadening fixes (a literal "sshd[" check misses this entirely).
        msg = "Jul  8 10:24:00 dragon-zord sshd-session[12353]: Failed password for admin from 203.0.113.14 port 51800 ssh2"
        self.assertEqual(sshd_grok_match(msg), "match")

    def test_modern_openssh_sshd_auth_tag(self):
        # OpenSSH 10.0+'s narrower pre-auth-only process tag.
        msg = "Jul  8 10:24:30 dragon-zord sshd-auth[12354]: Failed password for admin from 203.0.113.15 port 51801 ssh2"
        self.assertEqual(sshd_grok_match(msg), "match")

    def test_modern_openssh_tag_parse_failure_still_quarantines(self):
        # A malformed line under the modern tag must still reach grok and be
        # tagged _grokparsefailure (quarantined), not silently skipped —
        # the pre-filter broadens which TAGS reach grok, it doesn't weaken
        # what counts as a genuine parse failure once there.
        msg = "Jul  8 10:25:00 dragon-zord sshd-session[12355]: this is not a real auth line at all"
        self.assertEqual(sshd_grok_match(msg), "grokparsefailure")

    def test_malformed_ipv4_octets_is_grokparsefailure(self):
        # Regression guard for IP-validation fidelity: an out-of-range octet
        # must NOT match (the real grok %{IP} rejects it too) — a looser
        # source_ip character class here would silently accept it.
        msg = "Jul  8 10:26:00 dragon-zord sshd[12356]: Failed password for admin from 999.999.999.999 port 51900 ssh2"
        self.assertEqual(sshd_grok_match(msg), "grokparsefailure")

    def test_garbage_after_sshd_marker(self):
        msg = "Jul  8 10:21:00 dragon-zord sshd[12351]: this is not a real auth line at all"
        self.assertEqual(sshd_grok_match(msg), "grokparsefailure")

    def test_non_sshd_auth_log_line_is_skipped_not_failed(self):
        # sudo/cron/PAM lines never reach grok at all (no sshd process-tag
        # substring) — this must NOT be tagged _grokparsefailure, and must
        # NOT be routed to the quarantine index; it's simply out of scope
        # for this grok block.
        msg = "Jul  8 10:22:00 dragon-zord sudo: tjlam : TTY=pts/0 ; PWD=/home/tjlam ; USER=root ; COMMAND=/bin/ls"
        self.assertEqual(sshd_grok_match(msg), "skipped")

    def test_non_auth_log_path_is_skipped(self):
        msg = "Jul  8 10:15:23 dragon-zord sshd[12345]: Failed password for admin from 203.0.113.7 port 51422 ssh2"
        self.assertEqual(sshd_grok_match(msg, log_path="/var/log/syslog"), "skipped")

    def test_injection_style_username_does_not_hijack_source_ip(self):
        # Regression guard for the source.ip-spoof fix: an attacker-controlled
        # username containing a fake "from <ip> port <n>" must not let the
        # greedy capture bind to the INJECTED ip/port instead of the real,
        # sshd-appended trailing one.
        msg = ("Jul  8 10:23:00 dragon-zord sshd[12352]: Failed password for "
               "victim from 8.8.8.8 port 22 from 203.0.113.13 port 51700 ssh2")
        result = sshd_grok_match(msg)
        self.assertEqual(result, "match")
        m = SSHD_PATTERN.match(msg)
        self.assertEqual(m.group("source_ip"), "203.0.113.13")
        self.assertEqual(m.group("source_port"), "51700")


class ZeekJsonTests(unittest.TestCase):
    def test_valid_zeek_conn_json(self):
        line = '{"ts":1751234567.123,"id.orig_h":"10.0.0.5","id.resp_h":"93.184.216.34","proto":"tcp"}'
        self.assertEqual(zeek_json_parse(line), "match")

    def test_truncated_json_line(self):
        line = '{"ts":1751234567.123,"id.orig_h":"10.0.0.5","id.resp_h":'
        self.assertEqual(zeek_json_parse(line), "jsonparsefailure")

    def test_non_json_garbage_line(self):
        line = "this is not json at all {{{"
        self.assertEqual(zeek_json_parse(line), "jsonparsefailure")


if __name__ == "__main__":
    unittest.main(verbosity=2)
