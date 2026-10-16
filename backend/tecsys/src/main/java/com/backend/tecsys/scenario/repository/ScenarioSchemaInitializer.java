package com.backend.tecsys.scenario.repository;

import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Profile;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

@Component
@Profile("!mock")
@RequiredArgsConstructor
public class ScenarioSchemaInitializer {
    private final JdbcTemplate jdbc;

    @PostConstruct
    void alignCoverageAssetSchema() {
        Boolean tableExists = jdbc.queryForObject(
                "SELECT EXISTS (SELECT 1 FROM information_schema.tables "
                        + "WHERE table_schema = 'app' AND table_name = 'cenario_cobertura_ativo')",
                Boolean.class);
        if (Boolean.TRUE.equals(tableExists)) {
            jdbc.execute("ALTER TABLE app.cenario_cobertura_ativo "
                    + "DROP CONSTRAINT IF EXISTS cenario_cobertura_ativo_ativo_key_fkey");
        }
    }
}