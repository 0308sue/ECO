package com.eco.backend.receipt.service;

import com.eco.backend.receipt.dto.ReceiptAnalysisResponse;
import com.eco.backend.receipt.dto.ReceiptItemAnalysisResponse;
import com.google.cloud.firestore.DocumentReference;
import com.google.cloud.firestore.FieldValue;
import com.google.cloud.firestore.Firestore;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutionException;

@Service
public class ReceiptFirestoreService {

    private final Firestore firestore;

    public ReceiptFirestoreService(Firestore firestore) {
        this.firestore = firestore;
    }

    public String saveReceiptAnalysis(
            String userId,
            List<ReceiptItemAnalysisResponse> items,
            ReceiptAnalysisResponse.Summary summary
    ) {
        DocumentReference receiptRef = firestore
                .collection("users")
                .document(userId)
                .collection("receipts")
                .document();

        String receiptId = receiptRef.getId();

        Map<String, Object> receiptData = new LinkedHashMap<>();
        receiptData.put("receiptId", receiptId);
        receiptData.put("userId", userId);
        receiptData.put("items", convertItemsToMap(items));
        receiptData.put("summary", convertSummaryToMap(summary));
        receiptData.put("createdAt", FieldValue.serverTimestamp());

        try {
            receiptRef.set(receiptData).get();
            return receiptId;
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new IllegalStateException("영수증 분석 결과 저장 중 작업이 중단되었습니다.", e);
        } catch (ExecutionException e) {
            throw new IllegalStateException("Firestore에 영수증 분석 결과를 저장하지 못했습니다.", e);
        }
    }

    private List<Map<String, Object>> convertItemsToMap(
            List<ReceiptItemAnalysisResponse> items
    ) {
        List<Map<String, Object>> itemMaps = new ArrayList<>();

        for (ReceiptItemAnalysisResponse item : items) {
            Map<String, Object> itemMap = new LinkedHashMap<>();
            itemMap.put("originalName", item.getOriginalName());
            itemMap.put("normalizedName", item.getNormalizedName());
            itemMap.put("price", item.getPrice());
            itemMap.put("category", item.getCategory());
            itemMap.put("subCategory", item.getSubCategory());
            itemMap.put("matchedKeyword", item.getMatchedKeyword());
            itemMap.put("estimatedCarbonGram", item.getEstimatedCarbonGram());
            itemMap.put("estimatedCarbonKg", item.getEstimatedCarbonKg());
            itemMap.put("carbonScore", item.getCarbonScore());

            itemMaps.add(itemMap);
        }

        return itemMaps;
    }

    private Map<String, Object> convertSummaryToMap(
            ReceiptAnalysisResponse.Summary summary
    ) {
        Map<String, Object> summaryMap = new LinkedHashMap<>();
        summaryMap.put("totalPrice", summary.getTotalPrice());
        summaryMap.put("totalEstimatedCarbonGram", summary.getTotalEstimatedCarbonGram());
        summaryMap.put("totalEstimatedCarbonKg", summary.getTotalEstimatedCarbonKg());
        summaryMap.put("averageCarbonScore", summary.getAverageCarbonScore());
        summaryMap.put("itemCount", summary.getItemCount());
        summaryMap.put("topCategory", summary.getTopCategory());
        summaryMap.put("topSubCategory", summary.getTopSubCategory());

        return summaryMap;
    }
}