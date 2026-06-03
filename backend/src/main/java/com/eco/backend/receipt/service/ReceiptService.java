package com.eco.backend.receipt.service;

import com.eco.backend.item.dto.ItemCategoryResponse;
import com.eco.backend.item.service.ItemCategoryService;
import com.eco.backend.receipt.dto.ReceiptAnalysisResponse;
import com.eco.backend.receipt.dto.ReceiptItemAnalysisResponse;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Service
public class ReceiptService {

    private final ItemCategoryService itemCategoryService;
    private final ReceiptFirestoreService receiptFirestoreService;

    public ReceiptService(
        ItemCategoryService itemCategoryService,
        ReceiptFirestoreService receiptFirestoreService
    ) {
        this.itemCategoryService = itemCategoryService;
        this.receiptFirestoreService = receiptFirestoreService;
    }

    public ReceiptAnalysisResponse analyzeOcrText(String userId, String ocrText) {
        validateOcrText(ocrText);

        List<ReceiptLineItem> lineItems = extractLineItems(ocrText);

        List<ReceiptItemAnalysisResponse> analyzedItems = lineItems.stream()
                .map(this::analyzeLineItem)
                .toList();

        ReceiptAnalysisResponse.Summary summary = createSummary(analyzedItems);

        String receiptId = receiptFirestoreService.saveReceiptAnalysis(
                userId,
                analyzedItems,
                summary
        );

        return new ReceiptAnalysisResponse(
                receiptId,
                userId,
                analyzedItems,
                summary
        );
    }

    private ReceiptItemAnalysisResponse analyzeLineItem(ReceiptLineItem lineItem) {
        ItemCategoryResponse itemAnalysis =
                itemCategoryService.classify(lineItem.itemName());

        return new ReceiptItemAnalysisResponse(
                itemAnalysis.getOriginalName(),
                itemAnalysis.getNormalizedName(),
                lineItem.price(),
                itemAnalysis.getCategory(),
                itemAnalysis.getSubCategory(),
                itemAnalysis.getMatchedKeyword(),
                itemAnalysis.getEstimatedCarbonGram(),
                itemAnalysis.getEstimatedCarbonKg(),
                itemAnalysis.getCarbonScore()
        );
    }

    private List<ReceiptLineItem> extractLineItems(String ocrText) {
        String[] lines = ocrText.split("\\r?\\n");
        List<ReceiptLineItem> lineItems = new ArrayList<>();

        for (String line : lines) {
            String cleanedLine = line.trim();

            if (cleanedLine.isBlank()) {
                continue;
            }

            if (isIgnoredLine(cleanedLine)) {
                continue;
            }

            ReceiptLineItem lineItem = parseLineItem(cleanedLine);

            if (lineItem != null && !lineItem.itemName().isBlank()) {
                lineItems.add(lineItem);
            }
        }

        if (lineItems.isEmpty()) {
            throw new IllegalArgumentException("OCR 텍스트에서 품목명을 추출할 수 없습니다.");
        }

        return lineItems;
    }

    private ReceiptLineItem parseLineItem(String line) {
        Integer price = extractPrice(line);

        if (price == null) {
            return new ReceiptLineItem(line.trim(), 0);
        }

        String itemName = removeLastPrice(line).trim();

        if (itemName.isBlank()) {
            return null;
        }

        return new ReceiptLineItem(itemName, price);
    }

    private Integer extractPrice(String line) {
        String[] tokens = line.trim().split("\\s+");

        for (int i = tokens.length - 1; i >= 0; i--) {
            String token = tokens[i];

            if (isPriceToken(token)) {
                return parsePrice(token);
            }
        }

        return null;
    }

    private boolean isPriceToken(String token) {
        return token.matches("[0-9]{1,3}(,[0-9]{3})*원?")
                || token.matches("[0-9]+원?");
    }

    private int parsePrice(String token) {
        String numericText = token
                .replace(",", "")
                .replace("원", "");

        return Integer.parseInt(numericText);
    }

    private String removeLastPrice(String line) {
        return line
                .replaceFirst("\\s+[0-9]{1,3}(,[0-9]{3})*원?\\s*$", "")
                .replaceFirst("\\s+[0-9]+원?\\s*$", "");
    }

    private boolean isIgnoredLine(String line) {
        String normalizedLine = line.replaceAll("\\s+", "");

        return normalizedLine.contains("합계")
                || normalizedLine.contains("총액")
                || normalizedLine.contains("결제")
                || normalizedLine.contains("카드")
                || normalizedLine.contains("승인")
                || normalizedLine.contains("부가세")
                || normalizedLine.contains("과세")
                || normalizedLine.contains("면세")
                || normalizedLine.contains("거스름")
                || normalizedLine.contains("영수증")
                || normalizedLine.contains("사업자")
                || normalizedLine.contains("전화")
                || normalizedLine.contains("주소")
                || normalizedLine.contains("일시")
                || normalizedLine.contains("날짜");
    }

    private ReceiptAnalysisResponse.Summary createSummary(
            List<ReceiptItemAnalysisResponse> items
    ) {
        int totalPrice = items.stream()
                .mapToInt(ReceiptItemAnalysisResponse::getPrice)
                .sum();

        int totalEstimatedCarbonGram = items.stream()
                .mapToInt(ReceiptItemAnalysisResponse::getEstimatedCarbonGram)
                .sum();

        double totalEstimatedCarbonKg =
                Math.round((totalEstimatedCarbonGram / 1000.0) * 1000.0) / 1000.0;

        double averageCarbonScore = items.stream()
                .mapToInt(ReceiptItemAnalysisResponse::getCarbonScore)
                .average()
                .orElse(0.0);

        averageCarbonScore = Math.round(averageCarbonScore * 10.0) / 10.0;

        String topCategory = findMostFrequentCategory(items);
        String topSubCategory = findMostFrequentSubCategory(items);

        return new ReceiptAnalysisResponse.Summary(
                totalPrice,
                totalEstimatedCarbonGram,
                totalEstimatedCarbonKg,
                averageCarbonScore,
                items.size(),
                topCategory,
                topSubCategory
        );
    }

    private String findMostFrequentCategory(List<ReceiptItemAnalysisResponse> items) {
        Map<String, Integer> categoryCount = new LinkedHashMap<>();

        for (ReceiptItemAnalysisResponse item : items) {
            categoryCount.put(
                    item.getCategory(),
                    categoryCount.getOrDefault(item.getCategory(), 0) + 1
            );
        }

        return categoryCount.entrySet()
                .stream()
                .max(Comparator.comparingInt(Map.Entry::getValue))
                .map(Map.Entry::getKey)
                .orElse("기타");
    }

    private String findMostFrequentSubCategory(List<ReceiptItemAnalysisResponse> items) {
        Map<String, Integer> subCategoryCount = new LinkedHashMap<>();

        for (ReceiptItemAnalysisResponse item : items) {
            subCategoryCount.put(
                    item.getSubCategory(),
                    subCategoryCount.getOrDefault(item.getSubCategory(), 0) + 1
            );
        }

        return subCategoryCount.entrySet()
                .stream()
                .max(Comparator.comparingInt(Map.Entry::getValue))
                .map(Map.Entry::getKey)
                .orElse("기타");
    }

    private void validateOcrText(String ocrText) {
        if (ocrText == null || ocrText.trim().isEmpty()) {
            throw new IllegalArgumentException("OCR 텍스트는 비어 있을 수 없습니다.");
        }
    }

    private record ReceiptLineItem(
            String itemName,
            int price
    ) {
    }
}