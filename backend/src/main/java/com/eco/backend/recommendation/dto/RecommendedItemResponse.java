package com.eco.backend.recommendation.dto;

public record RecommendedItemResponse(
        String originalItem,
        String normalizedItem,
        String recommendedItem,
        String reason,
        String companyName,
        String certificationNo,
        String sourceName
) {
}