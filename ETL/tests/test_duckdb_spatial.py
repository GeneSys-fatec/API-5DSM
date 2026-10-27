"""Tests for bdgd_etl.duckdb_spatial."""
import duckdb
import pytest

from bdgd_etl import duckdb_spatial
from bdgd_etl.duckdb_spatial import install_spatial_extension, load_spatial


class _FakeCon:
    def __init__(self, failing: dict[str, int]):
        self.failing = dict(failing)
        self.calls: list[str] = []

    def execute(self, sql: str):
        self.calls.append(sql)
        if self.failing.get(sql, 0) > 0:
            self.failing[sql] -= 1
            raise duckdb.Error("boom")


@pytest.fixture(autouse=True)
def _no_sleep(monkeypatch):
    monkeypatch.setattr(duckdb_spatial.time, "sleep", lambda _s: None)


def test_load_spatial_does_not_install_when_extension_present():
    con = _FakeCon({})
    load_spatial(con)
    assert con.calls == ["LOAD spatial"]


def test_load_spatial_installs_when_load_fails_once():
    con = _FakeCon({"LOAD spatial": 1})
    load_spatial(con)
    assert con.calls == ["LOAD spatial", "INSTALL spatial", "LOAD spatial"]


def test_install_retries_until_success():
    con = _FakeCon({"INSTALL spatial": 2})
    duckdb_spatial._install_with_retries(con)
    assert con.calls.count("INSTALL spatial") == 3


def test_install_gives_up_after_max_attempts():
    con = _FakeCon({"INSTALL spatial": 99})
    with pytest.raises(duckdb.Error):
        duckdb_spatial._install_with_retries(con)
    assert con.calls.count("INSTALL spatial") == duckdb_spatial._INSTALL_ATTEMPTS


def test_real_extension_can_be_installed_and_loaded():
    install_spatial_extension()
    con = duckdb.connect()
    try:
        load_spatial(con)
        assert con.execute("SELECT ST_AsText(ST_Point(1, 2))").fetchone()[0] == "POINT (1 2)"
    finally:
        con.close()
