from __future__ import annotations

import sys
import types
from pathlib import Path

import pytest

_ETL_DIR = Path(__file__).resolve().parent.parent
if str(_ETL_DIR) not in sys.path:
    sys.path.insert(0, str(_ETL_DIR))


def _import_main():
    try:
        import main as main_module  # noqa: PLC0415

        return main_module
    except ModuleNotFoundError:
        if "extract" not in sys.modules:
            stub = types.ModuleType("extract")
            stub.read_layer = lambda *a, **k: None
            stub.list_available_layers = lambda *a, **k: []
            sys.modules["extract"] = stub

        if "main" in sys.modules:
            del sys.modules["main"]
        import main as main_module  # noqa: PLC0415

        return main_module


main = _import_main()


class TestParseArgsRegiao:

    def test_parse_args_accepts_positional_regiao(self, monkeypatch):
        monkeypatch.setattr(
            sys,
            "argv",
            ["main.py", "/dados/ENEL_SP_2022.gdb", "ENEL_SP", "SUDESTE"],
        )

        args = main.parse_args()

        assert args.gdb_path == "/dados/ENEL_SP_2022.gdb"
        assert args.distribuidora == "ENEL_SP"
        assert args.regiao == "SUDESTE"

    def test_parse_args_missing_regiao_raises_system_exit(self, monkeypatch):
        monkeypatch.setattr(
            sys,
            "argv",
            ["main.py", "/dados/ENEL_SP_2022.gdb", "ENEL_SP"],
        )

        with pytest.raises(SystemExit):
            main.parse_args()
