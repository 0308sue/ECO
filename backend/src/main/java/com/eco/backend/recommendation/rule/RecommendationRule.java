package com.eco.backend.recommendation.rule;

import java.util.List;

public record RecommendationRule (
    String category,
    String subcategory,
    List<String> keywords,
    String recommendedItem,
    String placeType,
    String reason
){
    public boolean matches(String matchName, String itemCategory, String itemSubCategory) {
    // category가 null이면 전체 카테고리 허용, 아니면 품목 카테고리와 일치해야 함
    boolean categoryMatched =
            category == null || category.equals(itemCategory);

    // subCategory가 null이면 전체 세부 카테고리 허용, 아니면 품목 세부 카테고리와 일치해야 함
    boolean subCategoryMatched =
            subCategory == null || subCategory.equals(itemSubCategory);

    // keywords가 비어 있으면 전체 허용, 아니면 품목명에 키워드 중 하나가 포함되어야 함
    boolean keywordMatched =
            keywords == null || keywords.isEmpty()
                    || keywords.stream().anyMatch(matchName::contains);

    // 세 조건을 모두 만족하면 해당 추천 규칙 적용
    return categoryMatched && subCategoryMatched && keywordMatched;
}
}