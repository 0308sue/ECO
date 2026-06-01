package com.eco.backend.item.rule;

import java.util.List;

public class ItemCategoryRule {

    private final String category;
    private final List<String> keywords;

    public ItemCategoryRule(String category, List<String> keywords) {
        this.category = category;
        this.keywords = keywords;
    }

    public String getCategory() {
        return category;
    }

    public List<String> getKeywords() {
        return keywords;
    }
}