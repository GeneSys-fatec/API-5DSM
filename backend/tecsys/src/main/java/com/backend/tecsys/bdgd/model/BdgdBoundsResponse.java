package com.backend.tecsys.bdgd.model;

import java.util.UUID;

public record BdgdBoundsResponse(
        UUID importId,
        Object geometry,
        int assetCount) {
}
