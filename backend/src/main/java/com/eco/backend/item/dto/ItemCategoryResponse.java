package com.eco.backend.item.dto;

public class ItemCategoryResponse {

    private String originalName;
    private String normalizedName;
    private String category;
    private String subCategory;
    private String matchedKeyword;
    private int estimatedCarbonGram;
    private double estimatedCarbonKg;
    private int carbonScore;

    public ItemCategoryResponse() {
    }

    public ItemCategoryResponse(
            String originalName,
            String normalizedName,
            String category,
            String subCategory,
            String matchedKeyword,
            int estimatedCarbonGram,
            double estimatedCarbonKg,
            int carbonScore
    ) {
        this.originalName = originalName;
        this.normalizedName = normalizedName;
        this.category = category;
        this.subCategory = subCategory;
        this.matchedKeyword = matchedKeyword;
        this.estimatedCarbonGram = estimatedCarbonGram;
        this.estimatedCarbonKg = estimatedCarbonKg;
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

    public String getSubCategory() {
        return subCategory;
    }

    public String getMatchedKeyword() {
        return matchedKeyword;
    }

    public int getEstimatedCarbonGram() {
        return estimatedCarbonGram;
    }

    public double getEstimatedCarbonKg() {
        return estimatedCarbonKg;
    }

    public int getCarbonScore() {
        return carbonScore;
    }
}