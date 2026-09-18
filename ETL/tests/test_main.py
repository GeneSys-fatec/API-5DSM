"""
test_main.py — Testes unitários de ETL/main.py.

Testes puros de CLI (sem GDB/DB): cobrem apenas `parse_args`. `main.py`
importa `extract` no nível do módulo, e esse módulo exige `fiona` (GDAL),
que pode não estar instalado neste ambiente. Para permitir testar
`parse_args` (que depende só de `argparse`) sem essa dependência pesada,
`extract` é stubado em `sys.modules` antes de importar `main`, caso a
importação real falhe.

Nota: `transform` NÃO é stubado — ele não depende de `fiona` (só de
geopandas/shapely), então é sempre importado de verdade. Isso evita
contaminar outros módulos de teste (ex. test_transform.py) que também
fazem `import transform` na mesma sessão do pytest e esperam receber o
módulo real, não um stub.
"""
from __future__ import annotations

import sys
import types
from pathlib import Path

import pytest

_ETL_DIR = Path(__file__).resolve().parent.parent
if str(_ETL_DIR) not in sys.path:
    sys.path.insert(0, str(_ETL_DIR))


def _import_main():
    """Importa `main`, stubando `extract` em `sys.modules` se a importação
    real falhar por dependência ausente (ex: `fiona`/GDAL).
    """
    try:
        import main as main_module  # noqa: PLC0415

        return main_module
    except ModuleNotFoundError:
        if "extract" not in sys.modules:
            stub = types.ModuleType("extract")
            # Atributos usados por main.py em tempo de execução (não em
            # tempo de parse de argumentos, mas definidos por segurança).
            stub.read_layer = lambda *a, **k: None
            stub.list_available_layers = lambda *a, **k: []
            sys.modules["extract"] = stub

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