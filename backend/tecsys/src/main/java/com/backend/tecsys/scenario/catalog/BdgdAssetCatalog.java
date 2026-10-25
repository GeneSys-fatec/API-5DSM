package com.backend.tecsys.scenario.catalog;

import org.springframework.stereotype.Component;

import java.util.*;
import java.util.stream.Collectors;

/**
 * Catálogo Semântico Central da BDGD (Base de Dados Geográfica da Distribuidora).
 * Unifica e classifica os ativos da BDGD em Famílias Semânticas Funcionais,
 * de acordo com as normas da ANEEL (PRODIST Módulo 10 / DDA) e a visão negocial.
 *
 * Mapeia aliases regulatórios e legados de diferentes concessionárias
 * (ex: PONNOT e POSTE, UNTRMT e UNTRD) para a mesma família semântica,
 * garantindo resiliência total contra variações de formatos de importação.
 */
@Component
public class BdgdAssetCatalog {

    public enum AssetFamily {
        POSTE("POSTE", "Postes e Estruturas MT", true, Set.of("POSTE", "PONNOT", "POST", "ESTRUTURA", "TORRE", "SUPORTE")),
        TRAFO("TRAFO", "Transformadores MT/BT", true, Set.of("TRAFO", "UNTRMT", "UNTRD", "TRANSFORMADOR", "EQTR")),
        RELIGADOR("RELIGADOR", "Religadores, Chaves e Proteção", true, Set.of("RELIGADOR", "UNREMT", "UNCRMT", "UNCRAT", "RECLOSER", "CHAVE", "SECCIONADORA", "PARARRAIOS")),
        SUB("SUB", "Subestações Elétricas", true, Set.of("SUB", "SUBESTACAO", "SE", "SUBSTATION")),
        SSDMT("SSDMT", "Segmentos de Rede MT", false, Set.of("SSDMT", "RAMALMT", "TRECHOMT")),
        SSDBT("SSDBT", "Segmentos de Rede BT", false, Set.of("SSDBT", "RAMALBT", "TRECHOBT")),
        SSDAT("SSDAT", "Segmentos de Rede AT", false, Set.of("SSDAT", "LINHA_AT", "TRECHOAT")),
        UCBT("UCBT", "Consumidores BT", false, Set.of("UCBT")),
        UCMT("UCMT", "Consumidores MT", false, Set.of("UCMT")),
        OUTROS("OUTROS", "Outros Ativos BDGD", false, Set.of("OUTROS"));

        private final String code;
        private final String displayName;
        private final boolean eligibleGateway;
        private final Set<String> aliases;

        AssetFamily(String code, String displayName, boolean eligibleGateway, Set<String> aliases) {
            this.code = code;
            this.displayName = displayName;
            this.eligibleGateway = eligibleGateway;
            this.aliases = aliases.stream().map(String::toUpperCase).collect(Collectors.toUnmodifiableSet());
        }

        public String getCode() {
            return code;
        }

        public String getDisplayName() {
            return displayName;
        }

        public boolean isEligibleGateway() {
            return eligibleGateway;
        }

        public Set<String> getAliases() {
            return aliases;
        }

        public boolean matches(String raw) {
            if (raw == null) return false;
            String upper = raw.trim().toUpperCase();
            return aliases.contains(upper) || code.equals(upper) || name().equals(upper);
        }
    }

    private static final Map<String, AssetFamily> ALIAS_MAP = new HashMap<>();

    static {
        for (AssetFamily family : AssetFamily.values()) {
            ALIAS_MAP.put(family.getCode(), family);
            ALIAS_MAP.put(family.name(), family);
            for (String alias : family.getAliases()) {
                ALIAS_MAP.put(alias, family);
            }
        }
    }

    /**
     * Resolve uma string bruta da BDGD (ex: "PONNOT", "poste", "UNTRMT") para sua Família Semântica.
     */
    public AssetFamily resolveFamily(String rawType) {
        if (rawType == null || rawType.isBlank()) {
            return AssetFamily.OUTROS;
        }
        String upper = rawType.trim().toUpperCase();
        AssetFamily found = ALIAS_MAP.get(upper);
        return found != null ? found : AssetFamily.OUTROS;
    }

    /**
     * Retorna o código canônico da família para o tipo de ativo informado.
     * Ex: "PONNOT" -> "POSTE", "UNTRMT" -> "TRAFO", "SUBESTACAO" -> "SUB".
     */
    public String canonicalCode(String rawType) {
        if (rawType == null || rawType.isBlank()) {
            return "OUTROS";
        }
        AssetFamily family = resolveFamily(rawType);
        if (family == AssetFamily.OUTROS) {
            return rawType.trim().toUpperCase();
        }
        return family.getCode();
    }

    /**
     * Informa se a família de ativos é elegível para instalação física de gateway na simulação.
     */
    public boolean isGatewayEligible(String rawType) {
        return resolveFamily(rawType).isEligibleGateway();
    }

    /**
     * Expande uma lista de tipos selecionados pelo usuário para todos os aliases equivalentes.
     * Exemplo: ["POSTE"] -> ["POSTE", "PONNOT", "POST", "ESTRUTURA", "TORRE", "SUPORTE"].
     * Garante que queries SQL ou filtros em memória nunca descartem ativos válidos por divergência de nomes.
     */
    public Set<String> expandFilter(Collection<String> requestedTypes) {
        if (requestedTypes == null || requestedTypes.isEmpty()) {
            return Collections.emptySet();
        }
        Set<String> expanded = new HashSet<>();
        for (String req : requestedTypes) {
            if (req == null || req.isBlank()) continue;
            String upper = req.trim().toUpperCase();
            AssetFamily family = resolveFamily(upper);
            if (family != AssetFamily.OUTROS) {
                expanded.addAll(family.getAliases());
                expanded.add(family.getCode());
                expanded.add(family.name());
            } else {
                expanded.add(upper);
            }
        }
        return Collections.unmodifiableSet(expanded);
    }
}
