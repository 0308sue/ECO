package com.eco.backend.receipt.dto;

public class ReceiptOcrTextRequest {

    private String userId;
    private String ocrText;

    public ReceiptOcrTextRequest() {
    }

    public ReceiptOcrTextRequest(String userId, String ocrText) {
        this.userId = userId;
        this.ocrText = ocrText;
    }

    public String getUserId() {
        return userId;
    }

    public String getOcrText() {
        return ocrText;
    }

    public void setUserId(String userId) {
        this.userId = userId;
    }

    public void setOcrText(String ocrText) {
        this.ocrText = ocrText;
    }
}