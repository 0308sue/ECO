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
    private String companyName;
    private String certificationNo;
    private String certificationType;

    private String subCategory;
    private List<String> keywords;
    private String productUseName;
    private String usage;

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

    public String getCompanyName() {
        return companyName;
    }

    public String getCertificationNo() {
        return certificationNo;
    }

    public String getCertificationType() {
        return certificationType;
    }

    public void setName(String name) {
        this.name = name;
    }

    public void setCategory(String category) {
        this.category = category;
    }

    public void setTargetCategories(List<String> targetCategories) {
        this.targetCategories = targetCategories;
    }

    public void setTargetSubCategories(List<String> targetSubCategories) {
        this.targetSubCategories = targetSubCategories;
    }

    public void setTargetKeywords(List<String> targetKeywords) {
        this.targetKeywords = targetKeywords;
    }

    public void setReason(String reason) {
        this.reason = reason;
    }

    public void setTip(String tip) {
        this.tip = tip;
    }

    public void setRelatedPlaceTypes(List<String> relatedPlaceTypes) {
        this.relatedPlaceTypes = relatedPlaceTypes;
    }

    public void setImageUrl(String imageUrl) {
        this.imageUrl = imageUrl;
    }

    public void setSourceName(String sourceName) {
        this.sourceName = sourceName;
    }

    public void setSourceUrl(String sourceUrl) {
        this.sourceUrl = sourceUrl;
    }

    public void setIsActive(Boolean isActive) {
        this.isActive = isActive;
    }

    public void setCompanyName(String companyName) {
        this.companyName = companyName;
    }

    public void setCertificationNo(String certificationNo) {
        this.certificationNo = certificationNo;
    }

    public void setCertificationType(String certificationType) {
        this.certificationType = certificationType;
    }

    public String getSubCategory() {
        return subCategory;
    }

    public List<String> getKeywords() {
        return keywords;
    }

    public String getProductUseName() {
        return productUseName;
    }

    public String getUsage() {
        return usage;
    }

    public void setSubCategory(String subCategory) {
        this.subCategory = subCategory;
    }

    public void setKeywords(List<String> keywords) {
        this.keywords = keywords;
    }

    public void setProductUseName(String productUseName) {
        this.productUseName = productUseName;
    }

    public void setUsage(String usage) {
        this.usage = usage;
    }

}