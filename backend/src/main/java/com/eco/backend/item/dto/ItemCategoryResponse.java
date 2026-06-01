package com.eco.backend.item.dto;

public class ItemCategoryResponse {

    private String originalName;
    private String normalizedName;
    private String category;
    private String matchedKeyword;
    private int carbonScore;

    public ItemCategoryResponse() {
    }

    public ItemCategoryResponse(
            String originalName,
            String normalizedName,
            String category,
            String matchedKeyword,
            int carbonScore
    ) {
        this.originalName = originalName;
        this.normalizedName = normalizedName;
        this.category = category;
        this.matchedKeyword = matchedKeyword;
        this.carbonScore = carbonScore;
    }

    public String getOriginalName() {
        return originalName;
    }

    public String getNormalizedName() {
        return normalizedName;
    }

    public String getCategory() {
        return category;
    }

    public String getMatchedKeyword() {
        return matchedKeyword;
    }

    public int getCarbonScore() {
        return carbonScore;
    }
}