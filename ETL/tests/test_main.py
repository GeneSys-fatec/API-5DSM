from __future__ import annotations

import importlib
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
        for name in ("extract", "transform"):
            if name not in sys.modules:
                stub = types.ModuleType(name)
                # Atributos usados por main.py em tempo de execução (não em
                # tempo de parse de argumentos, mas definidos por segurança).
                stub.read_layer = lambda *a, **k: None
                stub.list_available_layers = lambda *a, **k: []
                stub.prepare_layer = lambda gdf, *a, **k: gdf
                sys.modules[name] = stub

        if "main" in sys.modules:
            del sys.modules["main"]
        import main as main_module  # noqa: PLC0415

        return main_module


main = _import_main()


class TestParseArgsRegiao:
    """Testes unitários de `main.parse_args`.
    Validates: Requirements 3.3."""

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
        # `regiao` é posicional obrigatório: sem ele, argparse deve encerrar
        # com SystemExit (código de erro), não silenciar o argumento ausente.
        monkeypatch.setattr(
            sys,
            "argv",
            ["main.py", "/dados/ENEL_SP_2022.gdb", "ENEL_SP"],
        )

        with pytest.raises(SystemExit):
            main.parse_args()
