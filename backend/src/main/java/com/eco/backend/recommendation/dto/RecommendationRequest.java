package com.eco.backend.recommendation.dto;

import java.util.List;

public record RecommendationRequest(
        String userID,
        List<ReceiptItem> items,
        ReceiptSummary summary,
        Double lat,
        Double lng
) {
}