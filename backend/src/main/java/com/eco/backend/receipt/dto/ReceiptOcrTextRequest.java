package com.eco.backend.receipt.dto;

import java.util.List;

public class ReceiptOcrTextRequest {

    private String userId;
    private String ocrText;
    private List<OcrLineRequest> ocrLines;

    public ReceiptOcrTextRequest() {
    }

    public ReceiptOcrTextRequest(
            String userId,
            String ocrText,
            List<OcrLineRequest> ocrLines
    ) {
        this.userId = userId;
        this.ocrText = ocrText;
        this.ocrLines = ocrLines;
    }

    public String getUserId() {
        return userId;
    }

    public String getOcrText() {
        return ocrText;
    }

    public List<OcrLineRequest> getOcrLines() {
        return ocrLines;
    }

    public void setUserId(String userId) {
        this.userId = userId;
    }

    public void setOcrText(String ocrText) {
        this.ocrText = ocrText;
    }

    public void setOcrLines(List<OcrLineRequest> ocrLines) {
        this.ocrLines = ocrLines;
    }

    public static class OcrLineRequest {

        private String text;
        private double x;
        private double y;
        private double width;
        private double height;

        public OcrLineRequest() {
        }

        public OcrLineRequest(
                String text,
                double x,
                double y,
                double width,
                double height
        ) {
            this.text = text;
            this.x = x;
            this.y = y;
            this.width = width;
            this.height = height;
        }

        public String getText() {
            return text;
        }

        public double getX() {
            return x;
        }

        public double getY() {
            return y;
        }

        public double getWidth() {
            return width;
        }

        public double getHeight() {
            return height;
        }

        public void setText(String text) {
            this.text = text;
        }

        public void setX(double x) {
            this.x = x;
        }

        public void setY(double y) {
            this.y = y;
        }

        public void setWidth(double width) {
            this.width = width;
        }

        public void setHeight(double height) {
            this.height = height;
        }
    }
}