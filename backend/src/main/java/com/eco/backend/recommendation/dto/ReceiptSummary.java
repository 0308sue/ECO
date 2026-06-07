package com.eco.backend.recommendation.dto;

public record ReceiptSummary(
        String topCategory,
        String topSubCategory,
        Double averageCarbonScore
) {
}