"""Focused unit tests for the SOAR agent's security-critical pure helpers.

Covers HMAC verification (fail-closed + constant-time + replay protection) and
MAC/IP validation — the input-validation that gates device isolation. Heavy/native
deps (weasyprint, elasticsearch) are stubbed so the agent imports without them; the
test skips cleanly if flask/requests are unavailable. jinja2 is NOT stubbed — it is
a genuine Flask dependency, so it is always really installed wherever flask is
importable, and a fake stub here previously broke Flask's own internal
`from jinja2 import BaseLoader` import once flask/jinja2 were installed for real.
"""
import os
import sys
import types

import pytest

# --- Stub heavy optional deps pulled in transitively by agent_app -> weekly_ciso_report
for _name in ("weasyprint", "elasticsearch"):
    if _name not in sys.modules:
        mod = types.ModuleType(_name)
        sys.modules[_name] = mod
sys.modules["weasyprint"].HTML = object
sys.modules["elasticsearch"].Elasticsearch = object

# Provide a known HMAC secret BEFORE importing (the module reads env at import).
os.environ["SOC_AGENT_HMAC_SECRET"] = "unit-test-secret"

_AGENT_DIR = os.path.join(
    os.path.dirname(__file__), "..", "..", "scripts", "setup", "ai_agent"
)
sys.path.insert(0, os.path.abspath(_AGENT_DIR))

# Skip the whole module if flask/requests aren't installed (report-only CI env).
agent = pytest.importorskip("agent_app")


import hashlib
import hmac
import time


def _sign(body: bytes, secret: bytes, ts: str | None = None) -> tuple[str, str]:
    """Mirror agent_app.sign_request(): HMAC over '<timestamp>.' + body."""
    ts = ts or str(int(time.time()))
    sig = "sha256=" + hmac.new(secret, f"{ts}.".encode() + body, hashlib.sha256).hexdigest()
    return ts, sig


class TestVerifySignature:
    def setup_method(self):
        agent._seen_sigs.clear()  # isolate the replay/nonce cache per test

    def test_valid_signature_accepted(self):
        body = b'{"alert":"x"}'
        ts, sig = _sign(body, agent.HMAC_SECRET)
        assert agent.verify_signature(body, sig, ts) is True

    def test_wrong_signature_rejected(self):
        ts = str(int(time.time()))
        assert agent.verify_signature(b'{"a":1}', "sha256=deadbeef", ts) is False

    def test_missing_signature_header_rejected(self):
        assert agent.verify_signature(b"{}", None, str(int(time.time()))) is False

    def test_missing_timestamp_header_rejected(self):
        body = b'{"alert":"x"}'
        _, sig = _sign(body, agent.HMAC_SECRET)
        assert agent.verify_signature(body, sig, None) is False

    def test_fails_closed_when_secret_unset(self, monkeypatch):
        # Unset secret MUST refuse every request (never fail open).
        monkeypatch.setattr(agent, "HMAC_SECRET", b"")
        body = b"{}"
        ts, sig = _sign(body, b"")
        assert agent.verify_signature(body, sig, ts) is False

    def test_replayed_signature_rejected(self):
        body = b'{"alert":"replay-me"}'
        ts, sig = _sign(body, agent.HMAC_SECRET)
        assert agent.verify_signature(body, sig, ts) is True   # first use: accepted
        assert agent.verify_signature(body, sig, ts) is False  # replay: rejected

    def test_stale_timestamp_rejected(self):
        body = b'{"alert":"x"}'
        old_ts = str(int(time.time()) - agent.HMAC_REPLAY_WINDOW - 60)
        _, sig = _sign(body, agent.HMAC_SECRET, ts=old_ts)
        assert agent.verify_signature(body, sig, old_ts) is False

    def test_tampered_body_rejected(self):
        ts, sig = _sign(b'{"alert":"original"}', agent.HMAC_SECRET)
        assert agent.verify_signature(b'{"alert":"tampered"}', sig, ts) is False


class TestValidators:
    @pytest.mark.parametrize("mac", ["AA:BB:CC:DD:EE:FF", "00-11-22-33-44-55"])
    def test_valid_macs(self, mac):
        assert agent.is_valid_mac(mac) is True

    @pytest.mark.parametrize("mac", ["", "AA:BB:CC:DD:EE", "ZZ:BB:CC:DD:EE:FF", "1.2.3.4"])
    def test_invalid_macs(self, mac):
        assert agent.is_valid_mac(mac) is False

    @pytest.mark.parametrize("ip", ["10.0.0.1", "192.168.1.1", "::1"])
    def test_valid_ips(self, ip):
        assert agent.is_valid_ip(ip) is True

    @pytest.mark.parametrize("ip", ["", "999.1.1.1", "not-an-ip"])
    def test_invalid_ips(self, ip):
        assert agent.is_valid_ip(ip) is False

    @pytest.mark.parametrize("ip", ["::1%eth0", "fe80::1%25en0", "1.2.3.4%0"])
    def test_scoped_ipv6_rejected(self, ip):
        # A scoped IPv6 literal must never reach the broker's SSH-executed
        # firewall command unsanitised.
        assert agent.is_valid_ip(ip) is False
