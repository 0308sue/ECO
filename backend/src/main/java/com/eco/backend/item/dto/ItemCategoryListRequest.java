package com.eco.backend.item.dto;

import java.util.List;

public class ItemCategoryListRequest {

    private List<String> items;

    public ItemCategoryListRequest() {
    }

    public ItemCategoryListRequest(List<String> items) {
        this.items = items;
    }

    public List<String> getItems() {
        return items;
    }

    public void setItems(List<String> items) {
        this.items = items;
    }
}