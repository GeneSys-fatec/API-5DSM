package com.backend.tecsys.scenario.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SearchAreaResponse {
    private List<AssetDto> candidates;
    private String validationStatus;
    private String message;
}
