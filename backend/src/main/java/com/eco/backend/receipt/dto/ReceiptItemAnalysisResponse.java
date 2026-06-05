package com.eco.backend.receipt.dto;

public class ReceiptItemAnalysisResponse {

    private String originalName;
    private String normalizedName;
    private int price;
    private String category;
    private String subCategory;
    private String matchedKeyword;
    private int estimatedCarbonGram;
    private double estimatedCarbonKg;
    private int carbonScore;

    public ReceiptItemAnalysisResponse() {
    }

    public ReceiptItemAnalysisResponse(
            String originalName,
            String normalizedName,
            int price,
            String category,
            String subCategory,
            String matchedKeyword,
            int estimatedCarbonGram,
            double estimatedCarbonKg,
            int carbonScore
    ) {
        this.originalName = originalName;
        this.normalizedName = normalizedName;
        this.price = price;
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

    public int getPrice() {
        return price;
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