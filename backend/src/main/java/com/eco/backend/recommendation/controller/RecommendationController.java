package com.eco.backend.recommendation.controller;

import com.eco.backend.recommendation.dto.RecommendationRequest;
import com.eco.backend.recommendation.dto.RecommendedItemResponse;
import com.eco.backend.recommendation.dto.RecommendedPlaceResponse;
import com.eco.backend.recommendation.service.RecommendationService;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/recommendations")
public class RecommendationController {

    private final RecommendationService recommendationService;

    public RecommendationController(RecommendationService recommendationService) {
        this.recommendationService = recommendationService;
    }

    @PostMapping("/items")
    public List<RecommendedItemResponse> recommendItems(
            @RequestBody RecommendationRequest request
    ) {
        return recommendationService.recommendItems(request);
    }

    @PostMapping("/places")
    public List<RecommendedPlaceResponse> recommendPlaces(
            @RequestBody RecommendationRequest request
    ) {
        return recommendationService.recommendPlaces(request);
    }
}