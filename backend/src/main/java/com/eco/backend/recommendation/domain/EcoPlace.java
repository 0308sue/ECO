package com.eco.backend.recommendation.domain;

import java.util.List;

public class EcoPlace {

    private String name;
    private String type;
    private String address;
    private Double lat;
    private Double lng;
    private String phone;
    private List<String> availableItems;
    private List<String> targetCategories;
    private String description;
    private String sourceName;
    private String sourceUrl;
    private Boolean isActive;

    public EcoPlace() {
    }

    public String getName() {
        return name;
    }

    public String getType() {
        return type;
    }

    public String getAddress() {
        return address;
    }

    public Double getLat() {
        return lat;
    }

    public Double getLng() {
        return lng;
    }

    public String getPhone() {
        return phone;
    }

    public List<String> getAvailableItems() {
        return availableItems;
    }

    public List<String> getTargetCategories() {
        return targetCategories;
    }

    public String getDescription() {
        return description;
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