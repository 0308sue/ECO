package com.backend.recommendation.dto;

public record ReceiptItem(
        String originalName,
        String normalizedName,
        String category,
        String subCategory,
        String matchedKeyword,
        Integer carbonScore
) {
}