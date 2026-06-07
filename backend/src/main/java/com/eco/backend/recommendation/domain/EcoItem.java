package com.eco.backend.recommendation.domain;

import java.util.List;

public class EcoItem {

    private String name;
    private String category;
    private List<String> targetCategories;
    private List<String> targetSubCategories;
    private List<String> targetKeywords;
    private String reason;
    private String tip;
    private List<String> relatedPlaceTypes;
    private String imageUrl;
    private String sourceName;
    private String sourceUrl;
    private Boolean isActive;

    public EcoItem() {
    }

    public String getName() {
        return name;
    }

    public String getCategory() {
        return category;
    }

    public List<String> getTargetCategories() {
        return targetCategories;
    }

    public List<String> getTargetSubCategories() {
        return targetSubCategories;
    }

    public List<String> getTargetKeywords() {
        return targetKeywords;
    }

    public String getReason() {
        return reason;
    }

    public String getTip() {
        return tip;
    }

    public List<String> getRelatedPlaceTypes() {
        return relatedPlaceTypes;
    }

    public String getImageUrl() {
        return imageUrl;
    }

    public String getSourceName() {
        return sourceName;
    }

    public String getSourceUrl() {
        return sourceUrl;
    }

    public Boolean getIsActive() {
        return isActive;
    }
}