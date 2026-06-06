package com.eco.backend.receipt.dto;

import java.util.List;

public class ReceiptFinalSaveRequest {

    private String userId;
    private String storeName;
    private String purchasedAt;
    private String ocrText;
    private List<ReceiptOcrTextRequest.OcrLineRequest> ocrLines;
    private List<ReceiptItemRequest> items;

    public String getUserId() {
        return userId;
    }

    public String getStoreName() {
        return storeName;
    }

    public String getPurchasedAt() {
        return purchasedAt;
    }

    public String getOcrText() {
        return ocrText;
    }

    public List<ReceiptOcrTextRequest.OcrLineRequest> getOcrLines() {
        return ocrLines;
    }

    public List<ReceiptItemRequest> getItems() {
        return items;
    }

    public void setUserId(String userId) {
        this.userId = userId;
    }

    public void setStoreName(String storeName) {
        this.storeName = storeName;
    }

    public void setPurchasedAt(String purchasedAt) {
        this.purchasedAt = purchasedAt;
    }

    public void setOcrText(String ocrText) {
        this.ocrText = ocrText;
    }

    public void setOcrLines(List<ReceiptOcrTextRequest.OcrLineRequest> ocrLines) {
        this.ocrLines = ocrLines;
    }

    public void setItems(List<ReceiptItemRequest> items) {
        this.items = items;
    }

    public static class ReceiptItemRequest {
        private String name;
        private Integer price;

        public String getName() {
            return name;
        }

        public Integer getPrice() {
            return price;
        }

        public void setName(String name) {
            this.name = name;
        }

        public void setPrice(Integer price) {
            this.price = price;
        }
    }
}
