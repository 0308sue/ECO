package com.eco.backend.recommendation.dto;

public record ReceiptItem(
        String originalName,
        String normalizedName,
        String matchedKeyword,
        String category,
        String subCategory,
        Integer carbonScore
) {
}