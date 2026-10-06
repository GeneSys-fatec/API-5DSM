package com.backend.tecsys.bdgd.model;

import java.util.List;

public record BdgdGroupResponse(
        String regiao,
        String distribuidora,
        List<BdgdBaseSummaryResponse> bases) {
}
