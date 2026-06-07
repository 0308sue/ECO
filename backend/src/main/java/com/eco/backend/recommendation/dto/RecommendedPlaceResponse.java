package com.eco.backend.recommendation.dto;

public record RecommendedPlaceResponse(
        String placeName,
        String placeType,
        String address,
        Double lat,
        Double lng,
        String reason
) {
}