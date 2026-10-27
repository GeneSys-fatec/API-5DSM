package com.backend.tecsys.bdgd.model;

import com.backend.tecsys.bdgd.service.BdgdGroupValidator;

import java.util.List;

public record BdgdImportOptionsResponse(
        List<String> regioes,
        List<String> distribuidoras
) {
    public static BdgdImportOptionsResponse of(List<String> regioes, List<String> distribuidoras) {
        return new BdgdImportOptionsResponse(
                regioes,
                distribuidoras
        );
    }

    public static BdgdImportOptionsResponse defaults() {
        return new BdgdImportOptionsResponse(
                BdgdGroupValidator.ALLOWED_REGIONS,
                List.of()
        );
    }
}
