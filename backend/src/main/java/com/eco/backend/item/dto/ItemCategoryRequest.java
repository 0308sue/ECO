package com.eco.backend.item.dto;

public class ItemCategoryRequest {

    private String itemName;

    public ItemCategoryRequest() {
    }

    public ItemCategoryRequest(String itemName) {
        this.itemName = itemName;
    }

    public String getItemName() {
        return itemName;
    }

    public void setItemName(String itemName) {
        this.itemName = itemName;
    }
}