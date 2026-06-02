package com.eco.backend.item.rule;

import java.util.List;

public class ItemCategoryRule {

    private final String category;
    private final String subCategory;
    private final int estimatedCarbonGram;
    private final List<String> keywords;

    public ItemCategoryRule(
            String category,
            String subCategory,
            int estimatedCarbonGram,
            List<String> keywords
    ) {
        this.category = category;
        this.subCategory = subCategory;
        this.estimatedCarbonGram = estimatedCarbonGram;
        this.keywords = keywords;
    }

    public String getCategory() {
        return category;
    }

    public String getSubCategory() {
        return subCategory;
    }

    public int getEstimatedCarbonGram() {
        return estimatedCarbonGram;
    }

    public List<String> getKeywords() {
        return keywords;
    }
}