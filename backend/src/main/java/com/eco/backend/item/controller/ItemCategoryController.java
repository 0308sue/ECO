package com.eco.backend.item.controller;

import com.eco.backend.item.dto.ItemCategoryListRequest;
import com.eco.backend.item.dto.ItemCategoryListResponse;
import com.eco.backend.item.dto.ItemCategoryRequest;
import com.eco.backend.item.dto.ItemCategoryResponse;
import com.eco.backend.item.service.ItemCategoryService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/items")
public class ItemCategoryController {

    private final ItemCategoryService itemCategoryService;

    public ItemCategoryController(ItemCategoryService itemCategoryService) {
        this.itemCategoryService = itemCategoryService;
    }

    @PostMapping("/category")
    public ResponseEntity<ItemCategoryResponse> classifyCategory(
            @RequestBody ItemCategoryRequest request
    ) {
        ItemCategoryResponse response =
                itemCategoryService.classify(request.getItemName());

        return ResponseEntity.ok(response);
    }

    @PostMapping("/categories")
    public ResponseEntity<ItemCategoryListResponse> classifyCategories(
            @RequestBody ItemCategoryListRequest request
    ) {
        List<ItemCategoryResponse> results =
                itemCategoryService.classifyAll(request.getItems());

        return ResponseEntity.ok(new ItemCategoryListResponse(results));
    }
}