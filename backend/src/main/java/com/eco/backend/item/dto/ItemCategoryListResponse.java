package com.eco.backend.item.dto;

import java.util.List;

public class ItemCategoryListResponse {

    private List<ItemCategoryResponse> results;

    public ItemCategoryListResponse() {
    }

    public ItemCategoryListResponse(List<ItemCategoryResponse> results) {
        this.results = results;
    }

    public List<ItemCategoryResponse> getResults() {
        return results;
    }
}