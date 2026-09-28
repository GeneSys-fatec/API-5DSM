package com.backend.tecsys.scenario.controller;

import com.backend.tecsys.scenario.service.SearchAreaService;
import com.backend.tecsys.scenario.dto.SearchAreaRequest;
import com.backend.tecsys.scenario.dto.SearchAreaResponse;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/scenario/search-area")
public class SearchAreaController {

    private final SearchAreaService searchAreaService;

    public SearchAreaController(SearchAreaService searchAreaService) {
        this.searchAreaService = searchAreaService;
    }

    @PostMapping
    public ResponseEntity<SearchAreaResponse> delimitSearchArea(@Valid @RequestBody SearchAreaRequest request) {
        try {
            SearchAreaResponse response = searchAreaService.processSearchArea(request);
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(SearchAreaResponse.builder()
                    .validationStatus("ERROR")
                    .message(e.getMessage())
                    .build());
        }
    }
}
