"""Focused unit tests for the SOAR agent's security-critical pure helpers (issue #111).

Covers HMAC verification (fail-closed + constant-time) and MAC/IP validation — the
input-validation that gates device isolation. Heavy/native deps (weasyprint,
elasticsearch, jinja2) are stubbed so the agent imports without them; the test skips
cleanly if flask/requests are unavailable.
"""
import os
import sys
import types

import pytest

# --- Stub heavy optional deps pulled in transitively by agent_app -> weekly_ciso_report
for _name in ("weasyprint", "elasticsearch", "jinja2"):
    if _name not in sys.modules:
        mod = types.ModuleType(_name)
        sys.modules[_name] = mod
sys.modules["weasyprint"].HTML = object
sys.modules["elasticsearch"].Elasticsearch = object
sys.modules["jinja2"].Template = object

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


def _sign(body: bytes, secret: bytes) -> str:
    return "sha256=" + hmac.new(secret, body, hashlib.sha256).hexdigest()


class TestVerifySignature:
    def test_valid_signature_accepted(self):
        body = b'{"alert":"x"}'
        sig = _sign(body, agent.HMAC_SECRET)
        assert agent.verify_signature(body, sig) is True

    def test_wrong_signature_rejected(self):
        assert agent.verify_signature(b'{"a":1}', "sha256=deadbeef") is False

    def test_missing_header_rejected(self):
        assert agent.verify_signature(b"{}", None) is False

    def test_fails_closed_when_secret_unset(self, monkeypatch):
        # Unset secret MUST refuse every request (never fail open).
        monkeypatch.setattr(agent, "HMAC_SECRET", b"")
        body = b"{}"
        assert agent.verify_signature(body, _sign(body, b"")) is False


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
