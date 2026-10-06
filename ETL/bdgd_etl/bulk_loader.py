"""
bdgd_etl.bulk_loader — High-performance database bulk loaders.
Utilizes native COPY FROM STDIN with staging tables in PostgreSQL/PostGIS,
and supports modular database drivers (PostgreSQL / MySQL) — strictly avoiding
ORM or row-by-row inserts.
"""
from __future__ import annotations

import abc
import logging
import re
from pathlib import Path

import psycopg2
from psycopg2.extensions import connection as PgConnection

logger = logging.getLogger(__name__)


def mask_connection_url(url: str) -> str:
    """Masks database credentials for secure logging."""
    return re.sub(r"(:)[^:@]+(@)", r"\1***\2", url)


class BaseBulkLoader(abc.ABC):
    """Abstract interface for database bulk loaders."""

    @abc.abstractmethod
    def connect(self) -> None:
        """Establish database connection."""

    @abc.abstractmethod
    def close(self) -> None:
        """Close database connection."""

    @abc.abstractmethod
    def ensure_target_table(self, table_name: str) -> None:
        """Ensure schema, target table, and spatial indexes exist."""

    @abc.abstractmethod
    def bulk_load(self, table_name: str, staging_tsv_path: Path) -> int:
        """Perform bulk load using native stream / staging table strategy."""


class PostgresPostgisBulkLoader(BaseBulkLoader):
    """PostgreSQL/PostGIS implementation using COPY FROM STDIN and staging tables."""

    def __init__(self, db_url: str, schema: str = "bdgd", target_srid: int = 4326):
        self.db_url = db_url
        self.schema = schema
        self.target_srid = target_srid
        self._conn: PgConnection | None = None

    def connect(self) -> None:
        if self._conn is not None and not self._conn.closed:
            return

        try:
            self._conn = psycopg2.connect(
                self.db_url,
                connect_timeout=15,
                client_encoding="utf-8",
            )
            # Ensure schema & postgis
            with self._conn.cursor() as cur:
                cur.execute("CREATE EXTENSION IF NOT EXISTS postgis;")
                cur.execute(f"CREATE SCHEMA IF NOT EXISTS {self.schema};")
            self._conn.commit()
            logger.info("Conexão ao PostgreSQL/PostGIS estabelecida: %s", mask_connection_url(self.db_url))
        except Exception as exc:
            # Handle Windows encoding quirks in libpq error messages
            if isinstance(exc, UnicodeDecodeError) or "codec can't decode" in str(exc):
                raw_bytes = getattr(exc, "object", None)
                if isinstance(raw_bytes, bytes):
                    msg = raw_bytes.decode("latin1", errors="replace").strip()
                    raise ConnectionError(f"Erro de conexão com PostgreSQL: {msg}") from exc
            raise

    def close(self) -> None:
        if self._conn is not None and not self._conn.closed:
            self._conn.close()
            self._conn = None

    def ensure_target_table(self, table_name: str) -> None:
        self.connect()
        clean_table = table_name.lower().strip()
        qualified_table = f"{self.schema}.{clean_table}"

        sql = f"""
            CREATE TABLE IF NOT EXISTS {qualified_table} (
                id BIGSERIAL PRIMARY KEY,
                tipo_ativo TEXT NOT NULL,
                distribuidora TEXT NOT NULL,
                regiao TEXT NOT NULL,
                asset_key TEXT NOT NULL,
                geometry GEOMETRY(Geometry, {self.target_srid}) NOT NULL
            );
            CREATE UNIQUE INDEX IF NOT EXISTS uq_{clean_table}_asset_key 
            ON {qualified_table} (asset_key);
            
            CREATE INDEX IF NOT EXISTS idx_{clean_table}_geometry 
            ON {qualified_table} USING GIST (geometry);
        """
        with self._conn.cursor() as cur:
            cur.execute(sql)
        self._conn.commit()

    def bulk_load(self, table_name: str, staging_tsv_path: Path) -> int:
        """Executes native PostgreSQL bulk copy through a temporary staging table.

        Process:
        1. CREATE TEMP TABLE staging_{table} (...) ON COMMIT DROP;
        2. COPY staging_{table} FROM STDIN (stream TSV via copy_expert)
        3. INSERT INTO target SELECT ... ON CONFLICT (asset_key) DO UPDATE
        4. COMMIT
        """
        self.connect()
        clean_table = table_name.lower().strip()
        qualified_table = f"{self.schema}.{clean_table}"
        staging_table = f"staging_{clean_table}"

        if not staging_tsv_path.exists() or staging_tsv_path.stat().st_size == 0:
            logger.warning("[%s] Arquivo de staging vazio — nenhuma linha para bulk load.", table_name)
            return 0

        self.ensure_target_table(clean_table)

        with self._conn.cursor() as cur:
            # 1. Temporary unlogged staging table (in-memory, dropped at commit)
            cur.execute(f"""
                CREATE TEMP TABLE {staging_table} (
                    tipo_ativo TEXT,
                    distribuidora TEXT,
                    regiao TEXT,
                    asset_key TEXT,
                    geom_wkt TEXT
                ) ON COMMIT DROP;
            """)

            # 2. Fast streaming bulk load directly from disk via COPY FROM STDIN
            copy_sql = (
                f"COPY {staging_table} (tipo_ativo, distribuidora, regiao, asset_key, geom_wkt) "
                f"FROM STDIN WITH (FORMAT CSV, DELIMITER E'\\t', QUOTE '\"')"
            )
            with open(staging_tsv_path, "r", encoding="utf-8") as f:
                cur.copy_expert(copy_sql, f)

            # 3. Set-based atomic upsert from staging to target table
            upsert_sql = f"""
                INSERT INTO {qualified_table} (tipo_ativo, distribuidora, regiao, asset_key, geometry)
                SELECT
                    tipo_ativo,
                    distribuidora,
                    regiao,
                    asset_key,
                    ST_SetSRID(ST_GeomFromText(geom_wkt), {self.target_srid})
                FROM {staging_table}
                ON CONFLICT (asset_key) DO UPDATE SET
                    tipo_ativo = EXCLUDED.tipo_ativo,
                    distribuidora = EXCLUDED.distribuidora,
                    regiao = EXCLUDED.regiao,
                    geometry = EXCLUDED.geometry;
            """
            cur.execute(upsert_sql)
            rows_loaded = cur.rowcount

        self._conn.commit()
        logger.info(
            "[%s] Bulk load PostgreSQL (COPY FROM STDIN + Upsert) concluído: %d linhas afetadas em '%s'.",
            table_name,
            rows_loaded,
            qualified_table,
        )
        return rows_loaded


class MySQLBulkLoader(BaseBulkLoader):
    """MySQL bulk loader using LOAD DATA LOCAL INFILE and staging tables."""

    def __init__(self, db_url: str, schema: str = "bdgd", target_srid: int = 4326):
        self.db_url = db_url
        self.schema = schema
        self.target_srid = target_srid

    def connect(self) -> None:
        logger.info("Inicializando MySQL bulk loader (LOAD DATA LOCAL INFILE).")

    def close(self) -> None:
        pass

    def ensure_target_table(self, table_name: str) -> None:
        pass

    def bulk_load(self, table_name: str, staging_tsv_path: Path) -> int:
        raise NotImplementedError("MySQL loader configurável via PyMySQL / mysql-connector LOAD DATA LOCAL INFILE.")


def create_bulk_loader(
    db_type: str,
    db_url: str,
    schema: str = "bdgd",
    target_srid: int = 4326,
) -> BaseBulkLoader:
    """Factory creating the appropriate database bulk loader."""
    db_type_clean = db_type.lower().strip()
    if db_type_clean in ("postgres", "postgresql", "postgis"):
        return PostgresPostgisBulkLoader(db_url=db_url, schema=schema, target_srid=target_srid)
    if db_type_clean == "mysql":
        return MySQLBulkLoader(db_url=db_url, schema=schema, target_srid=target_srid)

    raise ValueError(f"Tipo de banco de dados não suportado: {db_type}. Use 'postgres' ou 'mysql'.")
