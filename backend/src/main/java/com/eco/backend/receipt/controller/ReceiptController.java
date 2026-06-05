package com.eco.backend.receipt.controller;

import com.eco.backend.receipt.dto.ReceiptAnalysisResponse;
import com.eco.backend.receipt.dto.ReceiptOcrTextRequest;
import com.eco.backend.receipt.service.ReceiptService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/receipts")
public class ReceiptController {

    private final ReceiptService receiptService;

    public ReceiptController(ReceiptService receiptService) {
        this.receiptService = receiptService;
    }

    @PostMapping("/ocr-text")
    public ResponseEntity<ReceiptAnalysisResponse> analyzeOcrText(
            @RequestBody ReceiptOcrTextRequest request
    ) {
        ReceiptAnalysisResponse response =
                receiptService.analyzeOcrText(
                        request.getUserId(),
                        request.getOcrText()
                );

        return ResponseEntity.ok(response);
    }
}