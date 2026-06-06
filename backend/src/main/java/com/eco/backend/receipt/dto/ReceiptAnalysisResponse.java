package com.eco.backend.receipt.dto;

import java.util.List;

public class ReceiptAnalysisResponse {

    private String receiptId;
    private String userId;
    private String storeName;
    private String purchasedAt;
    private List<ReceiptItemAnalysisResponse> items;
    private Summary summary;

    public ReceiptAnalysisResponse() {
    }

    public ReceiptAnalysisResponse(
            String receiptId,
            String userId,
            String storeName,
            String purchasedAt,
            List<ReceiptItemAnalysisResponse> items,
            Summary summary
    ) {
        this.receiptId = receiptId;
        this.userId = userId;
        this.storeName = storeName;
        this.purchasedAt = purchasedAt;
        this.items = items;
        this.summary = summary;
    }

    public String getReceiptId() {
        return receiptId;
    }

    public String getUserId() {
        return userId;
    }

    public String getStoreName() {
        return storeName;
    }

    public String getPurchasedAt() {
        return purchasedAt;
    }

    public List<ReceiptItemAnalysisResponse> getItems() {
        return items;
    }

    public Summary getSummary() {
        return summary;
    }

    public static class Summary {

        private int totalPrice;
        private int totalEstimatedCarbonGram;
        private double totalEstimatedCarbonKg;
        private double averageCarbonScore;
        private int itemCount;
        private String topCategory;
        private String topSubCategory;

        public Summary() {
        }

        public Summary(
                int totalPrice,
                int totalEstimatedCarbonGram,
                double totalEstimatedCarbonKg,
                double averageCarbonScore,
                int itemCount,
                String topCategory,
                String topSubCategory
        ) {
            this.totalPrice = totalPrice;
            this.totalEstimatedCarbonGram = totalEstimatedCarbonGram;
            this.totalEstimatedCarbonKg = totalEstimatedCarbonKg;
            this.averageCarbonScore = averageCarbonScore;
            this.itemCount = itemCount;
            this.topCategory = topCategory;
            this.topSubCategory = topSubCategory;
        }

        public int getTotalPrice() {
            return totalPrice;
        }

        public int getTotalEstimatedCarbonGram() {
            return totalEstimatedCarbonGram;
        }

        public double getTotalEstimatedCarbonKg() {
            return totalEstimatedCarbonKg;
        }

        public double getAverageCarbonScore() {
            return averageCarbonScore;
        }

        public int getItemCount() {
            return itemCount;
        }

        public String getTopCategory() {
            return topCategory;
        }

        public String getTopSubCategory() {
            return topSubCategory;
        }
    }
}