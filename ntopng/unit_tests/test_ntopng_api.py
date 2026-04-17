#!/usr/bin/env python3
"""Lightweight unit tests for the ntopng Python API (no live server).

Uses unittest.mock to satisfy __init__ (connect/test.lua) and REST helpers.
Output is parsed by parse_results.py --framework unittest.
"""

from __future__ import annotations

import unittest
from unittest.mock import MagicMock, patch

import requests

from ntopng.ntopng import Ntopng
from ntopng.interface import Interface
from ntopng.host import Host
from ntopng.historical import Historical


def _connect_ok_response() -> MagicMock:
    r = MagicMock()
    r.headers = {"Content-Type": "application/json; charset=utf-8"}
    return r


def _json_rsp(body: dict) -> MagicMock:
    r = MagicMock()
    r.status_code = 200
    r.json.return_value = body
    r.headers = {"Content-Type": "application/json"}
    return r


class TestNtopngClient(unittest.TestCase):
    """Construction and URL helpers."""

    @patch("ntopng.ntopng.requests.get", side_effect=requests.exceptions.ConnectionError("refused"))
    def test_unreachable_server_raises_valueerror(self, _mock_get):
        with self.assertRaises(ValueError):
            Ntopng("admin", "admin", None, "http://127.0.0.1:59999")

    @patch.object(Ntopng, "issue_request")
    def test_init_raises_when_content_type_not_json(self, mock_issue):
        bad = MagicMock()
        bad.headers = {"Content-Type": "text/html"}
        mock_issue.return_value = bad
        with self.assertRaises(ValueError):
            Ntopng("a", "b", None, "http://127.0.0.1:1")

    @patch.object(Ntopng, "issue_request", return_value=_connect_ok_response())
    def test_init_succeeds_with_json_connect_response(self, mock_issue):
        n = Ntopng("u", "p", None, "http://nt.example:3000")
        self.assertEqual(n.get_url(), "http://nt.example:3000")
        mock_issue.assert_called_once()
        call_url = mock_issue.call_args[0][0]
        self.assertTrue(call_url.endswith("/lua/rest/v2/connect/test.lua"))

    @patch.object(Ntopng, "issue_request", return_value=_connect_ok_response())
    def test_auth_token_sets_fields(self, _mock_issue):
        n = Ntopng(None, None, "tok123", "http://localhost:3000")
        self.assertIsNone(n.username)
        self.assertIsNone(n.password)
        self.assertEqual(n.auth_token, "tok123")

    @patch.object(Ntopng, "issue_request", return_value=_connect_ok_response())
    def test_enable_debug(self, _mock_issue):
        n = Ntopng("a", "b", None, "http://x:1")
        self.assertFalse(n.debug)
        n.enable_debug()
        self.assertTrue(n.debug)

    @patch("ntopng.ntopng.requests.get")
    def test_issue_request_uses_token_header(self, mock_get):
        mock_get.return_value = _connect_ok_response()
        n = Ntopng(None, None, "mytoken", "http://h:9")
        mock_get.reset_mock()
        mock_get.return_value = _connect_ok_response()
        n.issue_request("http://h:9/lua/x", {"q": 1})
        self.assertEqual(mock_get.call_count, 1)
        kwargs = mock_get.call_args[1]
        self.assertIn("Authorization", kwargs["headers"])
        self.assertEqual(kwargs["headers"]["Authorization"], "Token mytoken")
        self.assertIsNone(kwargs["auth"])

    @patch("ntopng.ntopng.requests.get")
    def test_issue_request_uses_basic_auth(self, mock_get):
        mock_get.return_value = _connect_ok_response()
        n = Ntopng("alice", "secret", None, "http://h:9")
        mock_get.reset_mock()
        mock_get.return_value = _connect_ok_response()
        n.issue_request("http://h:9/api", None)
        self.assertEqual(mock_get.call_count, 1)
        self.assertIsNotNone(mock_get.call_args[1]["auth"])

    @patch.object(Ntopng, "issue_request")
    def test_request_returns_rsp_field(self, mock_issue):
        mock_issue.side_effect = [
            _connect_ok_response(),
            _json_rsp({"rsp": {"interfaces": [1, 2]}}),
        ]
        n = Ntopng("a", "b", None, "http://srv:3000")
        out = n.request("/lua/rest/v2/get/x.lua", {"ifid": 0})
        self.assertEqual(out, {"interfaces": [1, 2]})
        self.assertIn("srv:3000", mock_issue.call_args[0][0])

    @patch("builtins.print")
    @patch.object(Ntopng, "issue_request")
    def test_request_bad_status_raises(self, mock_issue, _mock_print):
        mock_issue.side_effect = [
            _connect_ok_response(),
            MagicMock(status_code=404),
        ]
        n = Ntopng("a", "b", None, "http://srv:1")
        with self.assertRaises(Exception) as ctx:
            n.request("/lua/rest/v2/get/x.lua", None)
        self.assertIn("Bad response code", str(ctx.exception))

    @patch.object(Ntopng, "issue_post_request")
    @patch.object(Ntopng, "issue_request")
    def test_post_request_returns_rsp(self, mock_issue, mock_post):
        mock_issue.return_value = _connect_ok_response()
        n = Ntopng("a", "b", None, "http://srv:2")
        mock_post.return_value = _json_rsp({"rsp": [10, 20]})
        out = n.post_request("/lua/rest/v2/post/x.lua", {"k": "v"})
        self.assertEqual(out, [10, 20])

    @patch.object(Ntopng, "issue_request", return_value=_connect_ok_response())
    def test_get_interface_factory(self, _mock_issue):
        n = Ntopng("a", "b", None, "http://x:1")
        iface = n.get_interface(7)
        self.assertIsInstance(iface, Interface)
        self.assertEqual(iface.ifid, 7)
        self.assertIs(iface.ntopng_obj, n)

    @patch.object(Ntopng, "issue_request", return_value=_connect_ok_response())
    def test_get_historical_interface_factory(self, _mock_issue):
        n = Ntopng("a", "b", None, "http://x:1")
        hist = n.get_historical_interface(99)
        self.assertIsInstance(hist, Historical)
        self.assertEqual(hist.ifid, 99)
        self.assertIs(hist.ntopng_obj, n)


class TestHostInterface(unittest.TestCase):
    """Host / Interface parameter wiring (no HTTP in these paths)."""

    def setUp(self):
        patcher = patch.object(Ntopng, "issue_request", return_value=_connect_ok_response())
        patcher.start()
        self.addCleanup(patcher.stop)
        self.nt = Ntopng("a", "b", None, "http://mock:1")

    @patch.object(Ntopng, "request")
    def test_host_get_host_data_params_no_vlan(self, mock_req):
        h = Host(self.nt, 3, "192.168.1.1")
        h.get_host_data()
        mock_req.assert_called_once()
        path, params = mock_req.call_args[0]
        self.assertIn("/get/host/data.lua", path)
        self.assertEqual(params, {"ifid": 3, "host": "192.168.1.1"})

    @patch.object(Ntopng, "request")
    def test_host_get_host_data_params_with_vlan(self, mock_req):
        h = Host(self.nt, 3, "192.168.1.2", vlan=100)
        h.get_host_data()
        params = mock_req.call_args[0][1]
        self.assertEqual(params["vlan"], 100)

    @patch.object(Ntopng, "request")
    def test_host_dscp_direction_recvd(self, mock_req):
        h = Host(self.nt, 1, "10.0.0.1")
        h.get_dscp_stats(True)
        self.assertEqual(mock_req.call_args[0][1]["direction"], "recvd")

    @patch.object(Ntopng, "request")
    def test_host_dscp_direction_sent(self, mock_req):
        h = Host(self.nt, 1, "10.0.0.1")
        h.get_dscp_stats(False)
        self.assertEqual(mock_req.call_args[0][1]["direction"], "sent")

    def test_interface_get_host_wraps_host(self):
        iface = Interface(self.nt, 42)
        h = iface.get_host("1.2.3.4", vlan=5)
        self.assertIsInstance(h, Host)
        self.assertEqual(h.ifid, 42)
        self.assertEqual(h.ip, "1.2.3.4")
        self.assertEqual(h.vlan, 5)


if __name__ == "__main__":
    unittest.main()
