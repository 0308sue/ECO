package com.eco.backend.receipt.service;

import com.eco.backend.item.dto.ItemCategoryResponse;
import com.eco.backend.item.service.ItemCategoryService;
import com.eco.backend.receipt.dto.ReceiptAnalysisResponse;
import com.eco.backend.receipt.dto.ReceiptItemAnalysisResponse;
import com.eco.backend.receipt.dto.ReceiptOcrTextRequest;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@Service
public class ReceiptService {

    private final ItemCategoryService itemCategoryService;
    private final ReceiptFirestoreService receiptFirestoreService;

    private enum ReceiptLayout {
        STANDARD, SPLIT_LINE, COLUMN
    }

    public ReceiptService(
            ItemCategoryService itemCategoryService,
            ReceiptFirestoreService receiptFirestoreService
    ) {
        this.itemCategoryService = itemCategoryService;
        this.receiptFirestoreService = receiptFirestoreService;
    }

    public ReceiptAnalysisResponse analyzeOcrText(
            String userId,
            String ocrText,
            List<ReceiptOcrTextRequest.OcrLineRequest> ocrLines
    ) {
        validateOcrText(ocrText);

        List<String> lines = preprocessLines(ocrText);

        String storeName = extractStoreName(lines);
        String purchasedAt = extractPurchasedAt(lines);

        List<ReceiptLineItem> lineItems;

        if (ocrLines != null && !ocrLines.isEmpty()) {
            lineItems = extractLineItemsFromOcrLines(ocrLines);
        } else {
            ReceiptLayout layout = detectLayout(lines);
            lineItems = switch (layout) {
                case SPLIT_LINE -> extractLineItemsSplitLine(lines);
                case COLUMN -> extractLineItemsColumnFallback(lines);
                default -> extractLineItems(lines);
            };
        }

        List<ReceiptItemAnalysisResponse> analyzedItems = lineItems.stream()
                .map(this::analyzeLineItem)
                .toList();

        ReceiptAnalysisResponse.Summary summary = createSummary(analyzedItems);

        String receiptId = receiptFirestoreService.saveReceiptAnalysis(
                userId,
                storeName,
                purchasedAt,
                analyzedItems,
                summary
        );

        return new ReceiptAnalysisResponse(
                receiptId,
                userId,
                storeName,
                purchasedAt,
                analyzedItems,
                summary
        );
    }

    private ReceiptLayout detectLayout(List<String> lines) {
        for (int i = 0; i < lines.size() - 1; i++) {
            String cur = lines.get(i).trim();
            String next = lines.get(i + 1).trim();

            boolean curIsItem = cur.matches("^(할|합|\\*)\\)\\s*.+")
                    || cur.matches("^\\d+\\)\\s*.+");

            boolean nextIsPriceLine =
                    isOnlyPriceLine(next)
                            || next.matches("\\d[\\d,]*\\s+\\d+개?\\s+\\d[\\d,]*");

            if (curIsItem && nextIsPriceLine) {
                return ReceiptLayout.SPLIT_LINE;
            }
        }

        boolean hasHeader = lines.stream().anyMatch(this::isItemSectionHeader);
        long pureNumberLines = lines.stream()
                .filter(line -> line.trim().matches("\\d[\\d,]*"))
                .count();

        if (!hasHeader && pureNumberLines >= 2) {
            return ReceiptLayout.COLUMN;
        }

        return ReceiptLayout.STANDARD;
    }

    private List<ReceiptLineItem> extractLineItems(List<String> lines) {
        List<ReceiptLineItem> lineItems = new ArrayList<>();
        boolean itemSectionStarted = false;

        for (int i = 0; i < lines.size(); i++) {
            String currentLine = lines.get(i).trim();

            if (currentLine.isBlank()) {
                continue;
            }

            if (isItemSectionHeader(currentLine)) {
                itemSectionStarted = true;
                continue;
            }

            if (!itemSectionStarted) {
                continue;
            }

            if (isItemSectionEnd(currentLine)) {
                break;
            }

            if (isIgnoredLine(currentLine)) {
                continue;
            }

            if (isOptionOrModifierLine(currentLine)) {
                continue;
            }

            if (isDateLine(currentLine)) {
                continue;
            }

            if (isOnlyPriceLine(currentLine)) {
                continue;
            }

            if (isInvalidItemName(currentLine)) {
                continue;
            }

            ReceiptLineItem sameLineItem = parseLineItemInSameLine(currentLine);
            if (sameLineItem != null && isValidCandidateItem(sameLineItem.itemName(), sameLineItem.price())) {
                lineItems.add(sameLineItem);
                continue;
            }

            Integer nearbyPrice = findNearbyPrice(lines, i, 15);
            if (nearbyPrice != null) {
                String itemName = cleanItemName(currentLine);

                if (isValidCandidateItem(itemName, nearbyPrice)) {
                    lineItems.add(new ReceiptLineItem(itemName, nearbyPrice));
                }
            }
        }

        if (lineItems.isEmpty()) {
            throw new IllegalArgumentException("OCR 텍스트에서 품목명을 추출할 수 없습니다.");
        }

        return removeDuplicateItems(lineItems);
    }

    private List<ReceiptLineItem> extractLineItemsSplitLine(List<String> lines) {
        List<ReceiptLineItem> items = new ArrayList<>();

        Pattern splitPattern = Pattern.compile(
                "^([\\d,]+)\\s+\\d+개?\\s+([\\d,]+)$"
        );

        for (int i = 0; i < lines.size() - 1; i++) {
            String cur = lines.get(i).trim();
            String next = lines.get(i + 1).trim();

            if (cur.isBlank()) {
                continue;
            }

            if (isIgnoredLine(cur) || isItemSectionEnd(cur)) {
                continue;
            }

            if (isOptionOrModifierLine(cur)) {
                continue;
            }

            boolean curIsItem = cur.matches("^(할|합|\\*)\\)\\s*.+")
                    || cur.matches("^\\d+\\)\\s*.+" );

            if (!curIsItem) {
                continue;
            }

            if (isOnlyPriceLine(next)) {
                String itemName = cleanItemName(cur);
                int price = parsePrice(next);

                if (isValidCandidateItem(itemName, price)) {
                    items.add(new ReceiptLineItem(itemName, price));
                    i++;
                }

                continue;
            }

            Matcher matcher = splitPattern.matcher(next);

            if (matcher.matches()) {
                String itemName = cleanItemName(cur);
                int price = parsePrice(matcher.group(2));

                if (isValidCandidateItem(itemName, price)) {
                    items.add(new ReceiptLineItem(itemName, price));
                    i++;
                }

                continue;
            }

            ReceiptLineItem same = parseLineItemInSameLine(cur);
            if (same != null && isValidCandidateItem(same.itemName(), same.price())) {
                items.add(same);
            }
        }

        if (items.isEmpty()) {
            throw new IllegalArgumentException("OCR 텍스트에서 품목명을 추출할 수 없습니다.");
        }

        return removeDuplicateItems(items);
    }

    private List<ReceiptLineItem> extractLineItemsColumnFallback(List<String> lines) {
        List<ReceiptLineItem> items = new ArrayList<>();
        boolean itemSectionStarted = false;

        for (int i = 0; i < lines.size(); i++) {
            String line = lines.get(i).trim();

            if (line.isBlank()) {
                continue;
            }

            if (isItemSectionHeader(line)) {
                itemSectionStarted = true;
                continue;
            }

            if (!itemSectionStarted) {
                if (!isIgnoredLine(line) && !isDateLine(line) && !isMostlyNumberLine(line)) {
                    if (i >= 5) {
                        itemSectionStarted = true;
                    }
                }
                continue;
            }

            if (isItemSectionEnd(line)) {
                break;
            }

            if (isIgnoredLine(line)) {
                continue;
            }

            if (isOptionOrModifierLine(line)) {
                continue;
            }

            if (isDateLine(line)) {
                continue;
            }

            if (isOnlyPriceLine(line)) {
                continue;
            }

            if (isInvalidItemName(line)) {
                continue;
            }

            ReceiptLineItem same = parseLineItemInSameLine(line);
            if (same != null && isValidCandidateItem(same.itemName(), same.price())) {
                items.add(same);
                continue;
            }

            Integer price = findNearbyPrice(lines, i, 10);
            if (price != null) {
                String name = cleanItemName(line);

                if (isValidCandidateItem(name, price)) {
                    items.add(new ReceiptLineItem(name, price));
                }
            }
        }

        if (items.isEmpty()) {
            throw new IllegalArgumentException("OCR 텍스트에서 품목명을 추출할 수 없습니다.");
        }

        return removeDuplicateItems(items);
    }

    private List<ReceiptLineItem> extractLineItemsFromOcrLines(
            List<ReceiptOcrTextRequest.OcrLineRequest> ocrLines
    ) {
        List<ReceiptOcrTextRequest.OcrLineRequest> sortedLines = ocrLines.stream()
                .filter(line -> line.getText() != null && !line.getText().isBlank())
                .sorted(
                        Comparator
                                .comparingDouble(ReceiptOcrTextRequest.OcrLineRequest::getY)
                                .thenComparingDouble(ReceiptOcrTextRequest.OcrLineRequest::getX)
                )
                .toList();

        List<String> textOnly = sortedLines.stream()
                .map(line -> normalizeOcrLine(line.getText()))
                .toList();

        if (detectLayout(textOnly) == ReceiptLayout.SPLIT_LINE) {
            return extractLineItemsSplitLine(textOnly);
        }

        List<ReceiptLineItem> lineItems = new ArrayList<>();
        boolean itemSectionStarted = false;

        for (int i = 0; i < sortedLines.size(); i++) {
            ReceiptOcrTextRequest.OcrLineRequest current = sortedLines.get(i);
            String currentText = normalizeOcrLine(current.getText());

            if (currentText.isBlank()) {
                continue;
            }

            if (isItemSectionHeader(currentText)) {
                itemSectionStarted = true;
                continue;
            }

            if (!itemSectionStarted) {
                continue;
            }

            if (isIgnoredLine(currentText)) {
                continue;
            }

            if (isOptionOrModifierLine(currentText)) {
                continue;
            }

            if (isDateLine(currentText)) {
                continue;
            }

            if (isOnlyPriceLine(currentText)) {
                continue;
            }

            if (isInvalidItemName(currentText)) {
                continue;
            }

            ReceiptLineItem sameLineItem = parseLineItemInSameLine(currentText);
            if (sameLineItem != null && isValidCandidateItem(sameLineItem.itemName(), sameLineItem.price())) {
                lineItems.add(sameLineItem);
                continue;
            }

            Integer price = findPriceByCoordinate(sortedLines, current, i);
            if (price != null) {
                String itemName = cleanItemName(currentText);

                if (isValidCandidateItem(itemName, price)) {
                    lineItems.add(new ReceiptLineItem(itemName, price));
                }
            }
        }

        if (lineItems.isEmpty()) {
            throw new IllegalArgumentException("OCR 텍스트에서 품목명을 추출할 수 없습니다.");
        }

        return removeDuplicateItems(lineItems);
    }

    private Integer findPriceByCoordinate(
            List<ReceiptOcrTextRequest.OcrLineRequest> lines,
            ReceiptOcrTextRequest.OcrLineRequest itemLine,
            int itemIndex
    ) {
        String itemText = normalizeOcrLine(itemLine.getText());

        if (isOptionItemLine(itemText)) {
            return findOptionItemPrice(lines, itemIndex);
        }

        double itemCenterY = itemLine.getY() + itemLine.getHeight() / 2.0;
        double yTolerance = Math.max(itemLine.getHeight() * 1.3, 18.0);

        for (ReceiptOcrTextRequest.OcrLineRequest candidate : lines) {
            String text = normalizeOcrLine(candidate.getText());

            if (!isOnlyPriceLine(text)) {
                continue;
            }

            double priceCenterY = candidate.getY() + candidate.getHeight() / 2.0;
            boolean sameRow = Math.abs(itemCenterY - priceCenterY) <= yTolerance;
            boolean rightSide = candidate.getX() > itemLine.getX();

            if (sameRow && rightSide) {
                int price = parsePrice(text);

                if (price >= 100 && price <= 300_000) {
                    return price;
                }
            }
        }

        List<Integer> priceCandidates = new ArrayList<>();
        int end = Math.min(lines.size(), itemIndex + 12);

        for (int i = itemIndex + 1; i < end; i++) {
            String text = normalizeOcrLine(lines.get(i).getText());

            if (text.isBlank()) {
                continue;
            }

            if (isIgnoredLine(text) || isDateLine(text)) {
                continue;
            }

            if (text.contains("승인금액")
                    || text.contains("공급가")
                    || text.contains("부가세")
                    || text.contains("합계")) {
                continue;
            }

            if (isOnlyPriceLine(text)) {
                int price = parsePrice(text);

                if (price >= 100 && price <= 300_000) {
                    priceCandidates.add(price);
                }
            }
        }

        if (priceCandidates.isEmpty()) {
            return null;
        }

        return priceCandidates.get(0);
    }

    private Integer findOptionItemPrice(
            List<ReceiptOcrTextRequest.OcrLineRequest> lines,
            int itemIndex
    ) {
        List<Integer> priceCandidates = new ArrayList<>();
        int end = Math.min(lines.size(), itemIndex + 15);

        for (int i = itemIndex + 1; i < end; i++) {
            String text = normalizeOcrLine(lines.get(i).getText());

            if (text.isBlank()) {
                continue;
            }

            if (isDateLine(text)) {
                continue;
            }

            if (text.contains("승인금액")
                    || text.contains("공급가")
                    || text.contains("부가세")
                    || text.contains("합계")
                    || text.contains("카드")
                    || text.contains("승인")
                    || text.contains("사업자")) {
                continue;
            }

            Integer price = parseLoosePrice(text);

            if (price != null && price >= 1000 && price <= 300_000) {
                priceCandidates.add(price);
            }
        }

        if (priceCandidates.isEmpty()) {
            return null;
        }

        return priceCandidates.stream()
                .min(Integer::compareTo)
                .orElse(null);
    }

    private Integer parseLoosePrice(String text) {
        String cleaned = text.trim()
                .replace("원", "")
                .replace(")", "")
                .replace("(", "")
                .replace(",", "");

        if (!cleaned.matches("[0-9]+")) {
            return null;
        }

        return Integer.parseInt(cleaned);
    }

    private List<String> preprocessLines(String ocrText) {
        List<String> lines = new ArrayList<>();

        for (String rawLine : ocrText.split("\\r?\\n")) {
            String line = normalizeOcrLine(rawLine);

            if (line.isBlank()) {
                continue;
            }

            if (isDividerLine(line)) {
                continue;
            }

            if (isPreprocessNoiseLine(line)) {
                continue;
            }

            lines.add(line);
        }

        return lines;
    }

    private String normalizeOcrLine(String line) {
        if (line == null) {
            return "";
        }

        return line
                .replace("₩", "")
                .replace("￦", "")
                .replace("￥", "")
                .replace("ㆍ", ".")
                .replace("：", ":")
                .replace("（", "(")
                .replace("）", ")")
                .replace("[", "")
                .replace("]", "")
                .replaceAll("\\s+", " ")
                .trim();
    }

    private boolean isDividerLine(String line) {
        String normalized = line.replaceAll("\\s+", "");
        return normalized.matches("[-_=*\\.]{3,}")
                || normalized.matches("[|]{3,}");
    }

    private boolean isPreprocessNoiseLine(String line) {
        String normalized = line.replaceAll("\\s+", "");

        if (normalized.isBlank()) {
            return true;
        }

        if (normalized.matches(".*\\d{2,3}-\\d{3,4}-\\d{4}.*")) {
            return true;
        }

        if (normalized.matches(".*\\d{4}-\\d{4}-\\d{4}-\\d{4}.*")) {
            return true;
        }

        if (normalized.matches(".*\\*{2,}.*")) {
            return true;
        }

        return normalized.contains("주소")
                || normalized.contains("전화")
                || normalized.contains("TEL")
                || normalized.contains("사업자")
                || normalized.contains("대표")
                || normalized.contains("카드번호")
                || normalized.contains("승인번호")
                || normalized.contains("승인")
                || normalized.contains("카드명")
                || normalized.contains("매입사")
                || normalized.contains("신용카드")
                || normalized.contains("현금영수증")
                || normalized.contains("영수증번호")
                || normalized.contains("포스ID")
                || normalized.contains("POS")
                || normalized.contains("KIOSK")
                || normalized.contains("테이블")
                || normalized.contains("주문번호")
                || normalized.contains("CASHIER")
                || normalized.contains("캐셔");
    }

    private String extractStoreName(List<String> lines) {
        int limit = Math.min(lines.size(), 8);

        for (int i = 0; i < limit; i++) {
            String line = lines.get(i).trim();

            if (line.isBlank()) {
                continue;
            }

            if (isIgnoredLine(line)) {
                continue;
            }

            if (isItemSectionHeader(line)) {
                continue;
            }

            if (isDateLine(line)) {
                continue;
            }

            if (isMostlyNumberLine(line)) {
                continue;
            }

            if (line.length() < 2) {
                continue;
            }

            return line;
        }

        return "상호명 미확인";
    }

    private String extractPurchasedAt(List<String> lines) {
        for (String line : lines) {
            String cleanedLine = line.trim();

            if (cleanedLine.matches(".*20\\d{2}[-./년\\s]+\\d{1,2}[-./월\\s]+\\d{1,2}.*")) {
                return cleanedLine;
            }

            if (cleanedLine.matches(".*\\d{2}[-./]\\d{1,2}[-./]\\d{1,2}.*")) {
                return cleanedLine;
            }

            if (cleanedLine.matches(".*\\d{1,2}:\\d{2}.*")) {
                return cleanedLine;
            }
        }

        return null;
    }

    private Integer findNearbyPrice(List<String> lines, int itemLineIndex, int maxLookAhead) {
        List<Integer> priceCandidates = new ArrayList<>();
        int end = Math.min(lines.size(), itemLineIndex + maxLookAhead + 1);

        for (int i = itemLineIndex + 1; i < end; i++) {
            String line = lines.get(i).trim();

            if (line.isBlank() || isIgnoredLine(line) || isDateLine(line)) {
                continue;
            }

            if (line.contains("승인금액")
                    || line.contains("공급가")
                    || line.contains("부가세")
                    || line.contains("합계")) {
                continue;
            }

            if (isOnlyPriceLine(line)) {
                int price = parsePrice(line);

                if (price >= 100 && price <= 300_000) {
                    priceCandidates.add(price);
                }
            }
        }

        if (priceCandidates.isEmpty()) {
            return null;
        }

        String itemText = lines.get(itemLineIndex).trim();

        if (isOptionItemLine(itemText)) {
            return priceCandidates.stream()
                    .min(Integer::compareTo)
                    .orElse(null);
        }

        return priceCandidates.get(0);
    }

    private ReceiptLineItem parseLineItemInSameLine(String line) {
        if (isOnlyPriceLine(line)) {
            return null;
        }

        Integer price = extractPrice(line);

        if (price == null || price < 100 || price > 300_000) {
            return null;
        }

        String itemName = cleanItemName(removeLastPrice(line).trim());

        if (itemName.isBlank() || !isValidCandidateItem(itemName, price)) {
            return null;
        }

        return new ReceiptLineItem(itemName, price);
    }

    private Integer extractPrice(String line) {
        String[] tokens = line.trim().split("\\s+");

        for (int i = tokens.length - 1; i >= 0; i--) {
            String token = tokens[i];

            if (isPriceToken(token)) {
                int price = parsePrice(token);

                if (price >= 100 && price <= 300_000) {
                    return price;
                }
            }
        }

        return null;
    }

    private boolean isPriceToken(String token) {
        String cleaned = token.trim();

        if (cleaned.contains("(") || cleaned.contains(")") || cleaned.contains(".")) {
            return false;
        }

        return cleaned.matches("[0-9]{1,3}(,[0-9]{3})*원?")
                || cleaned.matches("[0-9]+원?");
    }

    private int parsePrice(String token) {
        return Integer.parseInt(
                token.replace(",", "").replace("원", "").trim()
        );
    }

    private String removeLastPrice(String line) {
        return line
                .replaceFirst("\\s*[0-9]{1,3}(,[0-9]{3})*원?\\s*$", "")
                .replaceFirst("\\s*[0-9]+원?\\s*$", "");
    }

    private boolean isOnlyPriceLine(String line) {
        String cleaned = line.trim();

        if (cleaned.contains("(") || cleaned.contains(")") || cleaned.contains(".")) {
            return false;
        }

        return cleaned.matches("[0-9]{1,3}(,[0-9]{3})+원?")
                || cleaned.matches("[0-9]{3,6}원?");
    }

    private boolean isIgnoredLine(String line) {
        String normalized = line.replaceAll("\\s+", "");

        return normalized.contains("합계")
                || normalized.contains("총액")
                || normalized.contains("총금액")
                || normalized.contains("총구매액")
                || normalized.contains("공급가액")
                || normalized.contains("결제")
                || normalized.contains("카드")
                || normalized.contains("승인")
                || normalized.contains("부가세")
                || normalized.contains("과세")
                || normalized.contains("면세")
                || normalized.contains("공급가")
                || normalized.contains("거스름")
                || normalized.contains("받은금액")
                || normalized.contains("영수증")
                || normalized.contains("사업자")
                || normalized.contains("대표")
                || normalized.contains("전화")
                || normalized.contains("TEL")
                || normalized.contains("주소")
                || normalized.contains("일시")
                || normalized.contains("날짜")
                || normalized.contains("POS")
                || normalized.contains("포스")
                || normalized.contains("포스ID")
                || normalized.contains("KIOSK")
                || normalized.contains("테이블")
                || normalized.contains("가맹점")
                || normalized.contains("가맹점번호")
                || normalized.contains("매출전표")
                || normalized.contains("전표")
                || normalized.contains("주문번호")
                || normalized.contains("주문")
                || normalized.contains("CASHIER")
                || normalized.contains("캐셔")
                || normalized.contains("캠퍼스")
                || normalized.contains("대학교")
                || normalized.contains("호관")
                || normalized.contains("고객용")
                || normalized.contains("표시상품")
                || normalized.contains("감사합니다")
                || normalized.contains("부가세면세")
                || normalized.contains("발행시")
                || normalized.contains("제품합계")
                || normalized.contains("과세금액")
                || normalized.contains("면세금액")
                || normalized.contains("청구액")
                || normalized.contains("받은돈")
                || normalized.contains("비씨카드")
                || normalized.matches(".*\\d{2,3}-\\d{3,4}-\\d{4}.*")
                || normalized.matches(".*\\d{4}-\\d{4}-\\d{4}-\\d{4}.*")
                || normalized.matches(".*\\*{2,}.*");
    }

    private boolean isDateLine(String line) {
        return line.matches(".*20\\d{2}[-./년\\s]+\\d{1,2}[-./월\\s]+\\d{1,2}.*")
                || line.matches(".*\\d{2}[-./]\\d{1,2}[-./]\\d{1,2}.*")
                || line.matches(".*\\d{1,2}:\\d{2}.*");
    }

    private boolean isItemSectionHeader(String line) {
        String normalized = line.replaceAll("\\s+", "");

        return normalized.contains("품명")
                || normalized.contains("상품명")
                || normalized.contains("메뉴명")
                || normalized.contains("품목")
                || normalized.contains("수량품명")
                || normalized.contains("품명금액")
                || (normalized.contains("수량") && normalized.contains("금액"));
    }

    private boolean isItemSectionEnd(String line) {
        String normalized = line.replaceAll("\\s+", "");

        return normalized.contains("주문금액")
                || normalized.contains("합계")
                || normalized.contains("공급가")
                || normalized.contains("부가세")
                || normalized.contains("결제")
                || normalized.contains("신용카드")
                || normalized.contains("카드")
                || normalized.contains("승인")
                || normalized.contains("받은금액")
                || normalized.contains("거스름")
                || normalized.contains("제품합계");
    }

    private boolean isInvalidItemName(String line) {
        String normalized = line.replaceAll("\\s+", "")
                .replace(",", "")
                .replace("원", "");

        if (normalized.isBlank()) {
            return true;
        }

        if (isOnlyPriceLine(line)) {
            return true;
        }

        if (normalized.matches("[0-9]+")) {
            return true;
        }

        if (normalized.matches("[0-9().]+")) {
            return true;
        }

        if (normalized.matches("[0-9]+개")) {
            return true;
        }

        if (normalized.matches("[0-9]+할")) {
            return true;
        }

        if (normalized.matches("[0-9]+할인?")) {
            return true;
        }

        if (normalized.matches("[0-9]+원?할")) {
            return true;
        }

        if (normalized.length() < 2) {
            return true;
        }

        if (!normalized.matches(".*[가-힣a-zA-Z].*")) {
            return true;
        }

        return normalized.contains("품명")
                || normalized.contains("상품명")
                || normalized.contains("메뉴명")
                || normalized.contains("품목")
                || normalized.contains("단가")
                || normalized.contains("수량")
                || normalized.contains("금액")
                || normalized.contains("제품합계")
                || normalized.contains("합계")
                || normalized.contains("주문")
                || normalized.contains("주문번호")
                || normalized.contains("포스ID")
                || normalized.contains("KIOSK")
                || normalized.contains("영수증")
                || normalized.contains("테이블")
                || normalized.contains("부가세")
                || normalized.contains("공급가액")
                || normalized.contains("신용카드")
                || normalized.contains("매출전표")
                || normalized.contains("과세금액")
                || normalized.contains("면세금액")
                || normalized.contains("청구액")
                || normalized.contains("청구")
                || normalized.contains("받은돈")
                || normalized.contains("비씨카드")
                || normalized.contains("가맹점번호")
                || normalized.contains("카드번호")
                || normalized.contains("카드명")
                || normalized.contains("매입사")
                || normalized.contains("승인번호")
                || normalized.contains("CASHIER")
                || normalized.contains("캐셔")
                || normalized.contains("감사합니다")
                || normalized.contains("고객용")
                || normalized.contains("프린트")
                || normalized.contains("캠퍼스")
                || normalized.contains("대학교")
                || normalized.contains("호관")
                || normalized.contains("표시상품")
                || normalized.contains("부가세면세")
                || normalized.contains("발행시")
                || normalized.contains("할부")
                || normalized.contains("할인");
    }

    private boolean isValidCandidateItem(String itemName, int price) {
        String normalized = itemName
                .replaceAll("\\s+", "")
                .replace(",", "")
                .replace("원", "")
                .toUpperCase();

        if (normalized.isBlank()) {
            return false;
        }

        if (price < 100 || price > 300_000) {
            return false;
        }

        if (!normalized.matches(".*[가-힣A-Z].*")) {
            return false;
        }

        String numericLike = normalized
                .replace("I", "1")
                .replace("L", "1")
                .replace("|", "1")
                .replace("O", "0");

        if (numericLike.matches("[0-9]+")) {
            return false;
        }

        if (normalized.matches("[0-9]+할")) {
            return false;
        }

        if (normalized.matches("[0-9]+할인?")) {
            return false;
        }

        if (normalized.matches("[0-9]+원?할")) {
            return false;
        }

        return !(normalized.contains("고객용")
                || normalized.contains("승인")
                || normalized.contains("승인금액")
                || normalized.contains("승인번호")
                || normalized.contains("결제")
                || normalized.contains("결제금액")
                || normalized.contains("카드")
                || normalized.contains("카드번호")
                || normalized.contains("카드명")
                || normalized.contains("매입사")
                || normalized.contains("가맹")
                || normalized.contains("가맹번호")
                || normalized.contains("가맹점번호")
                || normalized.contains("합계")
                || normalized.contains("총액")
                || normalized.contains("총금액")
                || normalized.contains("공급가")
                || normalized.contains("공급가액")
                || normalized.contains("부가세")
                || normalized.contains("과세")
                || normalized.contains("면세")
                || normalized.contains("면세금액")
                || normalized.contains("청구액")
                || normalized.contains("청구")
                || normalized.contains("받은돈")
                || normalized.contains("비씨카드")
                || normalized.contains("거스름")
                || normalized.contains("받은금액")
                || normalized.contains("영수증")
                || normalized.contains("사업자")
                || normalized.contains("대표")
                || normalized.contains("전화")
                || normalized.contains("주소")
                || normalized.contains("POS")
                || normalized.contains("포스")
                || normalized.contains("KIOSK")
                || normalized.contains("테이블")
                || normalized.contains("주문번호")
                || normalized.contains("CASHIER")
                || normalized.contains("캐셔")
                || normalized.contains("감사합니다")
                || normalized.contains("표시상품")
                || normalized.contains("발행시")
                || normalized.contains("할부")
                || normalized.contains("할인"));
    }

    private boolean isOptionItemLine(String itemName) {
        String normalized = itemName.replaceAll("\\s+", "");

        return normalized.contains("->>")
                || normalized.contains("공기밥")
                || normalized.contains("추가")
                || normalized.contains("옵션")
                || normalized.startsWith("(");
    }

    private boolean isOptionOrModifierLine(String line) {
        String normalized = line.replaceAll("\\s+", "");

        return normalized.startsWith("-")
                || normalized.startsWith("[")
                || normalized.endsWith("]")
                || normalized.contains("포테이토")
                || normalized.contains("제로콜라")
                || normalized.contains("아이스")
                || normalized.contains("콜라R")
                || normalized.contains("콜라(R)");
    }

    private boolean isMostlyNumberLine(String line) {
        String numberOnly = line.replaceAll("[^0-9]", "");
        return !numberOnly.isBlank() && numberOnly.length() >= line.length() / 2;
    }

    private String cleanItemName(String itemName) {
        String cleaned = itemName
                .replaceFirst("^(할|합|\\d+|\\*)\\)\\s*", "")
                .replace("(합)", "")
                .replace("(할)", "")
                .replace("[합]", "")
                .replace("[할]", "")
                .replace("합)", "")
                .replace("할)", "")
                .replace("*", "")
                .replaceAll("->>\\s*\\[?\\d*\\]?", "")
                .replaceAll("->>\\s*\\d*", "")
                .replaceFirst("^\\d+\\s+", "")
                .replaceFirst("^\\d+개\\s*", "")
                .trim();

        while (cleaned.startsWith("(")
                && cleaned.chars().filter(c -> c == '(').count()
                > cleaned.chars().filter(c -> c == ')').count()) {
            cleaned = cleaned.substring(1).trim();
        }

        while (cleaned.endsWith(")")
                && cleaned.chars().filter(c -> c == ')').count()
                > cleaned.chars().filter(c -> c == '(').count()) {
            cleaned = cleaned.substring(0, cleaned.length() - 1).trim();
        }

        return cleaned;
    }

    private List<ReceiptLineItem> removeDuplicateItems(List<ReceiptLineItem> items) {
        Map<String, ReceiptLineItem> unique = new LinkedHashMap<>();

        for (ReceiptLineItem item : items) {
            unique.putIfAbsent(item.itemName() + "|" + item.price(), item);
        }

        return new ArrayList<>(unique.values());
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

    private ReceiptAnalysisResponse.Summary createSummary(
            List<ReceiptItemAnalysisResponse> items
    ) {
        int totalPrice = items.stream()
                .mapToInt(ReceiptItemAnalysisResponse::getPrice)
                .sum();

        int totalCarbonGram = items.stream()
                .mapToInt(ReceiptItemAnalysisResponse::getEstimatedCarbonGram)
                .sum();

        double totalCarbonKg =
                Math.round((totalCarbonGram / 1000.0) * 1000.0) / 1000.0;

        double averageScore = items.stream()
                .mapToInt(ReceiptItemAnalysisResponse::getCarbonScore)
                .average()
                .orElse(0.0);

        averageScore = Math.round(averageScore * 10.0) / 10.0;

        String topCategory = findMostFrequentCategory(items);
        String topSubCategory = findMostFrequentSubCategory(items);

        return new ReceiptAnalysisResponse.Summary(
                totalPrice,
                totalCarbonGram,
                totalCarbonKg,
                averageScore,
                items.size(),
                topCategory,
                topSubCategory
        );
    }

    private String findMostFrequentCategory(List<ReceiptItemAnalysisResponse> items) {
        Map<String, Integer> count = new LinkedHashMap<>();

        for (ReceiptItemAnalysisResponse item : items) {
            count.merge(item.getCategory(), 1, Integer::sum);
        }

        return count.entrySet().stream()
                .max(Comparator.comparingInt(Map.Entry::getValue))
                .map(Map.Entry::getKey)
                .orElse("기타");
    }

    private String findMostFrequentSubCategory(List<ReceiptItemAnalysisResponse> items) {
        Map<String, Integer> count = new LinkedHashMap<>();

        for (ReceiptItemAnalysisResponse item : items) {
            count.merge(item.getSubCategory(), 1, Integer::sum);
        }

        return count.entrySet().stream()
                .max(Comparator.comparingInt(Map.Entry::getValue))
                .map(Map.Entry::getKey)
                .orElse("기타");
    }

    private void validateOcrText(String ocrText) {
        if (ocrText == null || ocrText.trim().isEmpty()) {
            throw new IllegalArgumentException("OCR 텍스트는 비어 있을 수 없습니다.");
        }
    }

    private record ReceiptLineItem(String itemName, int price) {
    }
}