package com.eco.backend.recommendation.rule;

import java.util.List;

public record RecommendationRule(
        String category,
        String subCategory,
        List<String> keywords,
        String recommendedItem,
        String placeType,
        String reason
) {
    public boolean matches(String matchName, String itemCategory, String itemSubCategory) {
        if (matchName == null) {
            matchName = "";
        }

        boolean categoryMatched =
                category == null || category.equals(itemCategory);

        boolean subCategoryMatched =
                subCategory == null || subCategory.equals(itemSubCategory);

        boolean keywordMatched =
                keywords == null || keywords.isEmpty()
                        || keywords.stream().anyMatch(matchName::contains);

        // 현재 품목이 이 추천 규칙에 해당하는지 최종 판단
        return categoryMatched && subCategoryMatched && keywordMatched;
    }
}