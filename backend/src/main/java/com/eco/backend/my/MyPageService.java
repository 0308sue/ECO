package com.eco.backend.my;

import com.google.cloud.Timestamp;
import com.google.cloud.firestore.DocumentSnapshot;
import com.google.cloud.firestore.QueryDocumentSnapshot;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.YearMonth;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;

@Service
public class MyPageService {

    private static final ZoneId SERVICE_ZONE = ZoneId.of("Asia/Seoul");
    private static final int ECO_FRIENDLY_MAX_CARBON_SCORE = 2;

    private final MyPageRepository myPageRepository;

    public MyPageService(MyPageRepository myPageRepository) {
        this.myPageRepository = myPageRepository;
    }

    public MyPageResponse getMyPage(String userId) {
        DocumentSnapshot user = myPageRepository.findUser(userId)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다."));
        List<QueryDocumentSnapshot> receipts = myPageRepository.findReceipts(userId);
        YearMonth currentMonth = YearMonth.now(SERVICE_ZONE);
        YearMonth previousMonth = currentMonth.minusMonths(1);

        int ecoPoint = calculateEcoPoint(receipts);
        Integer previousMonthRank = calculateMonthlyRank(userId, previousMonth);
        Integer currentMonthRank = calculateMonthlyRank(userId, currentMonth);

        return new MyPageResponse(
                userId,
                readString(user, "nickname", "사용자"),
                readString(user, "email", ""),
                ecoPoint,
                readString(user, "grade", calculateGrade(ecoPoint)),
                receipts.size(),
                ecoPoint,
                findMostConsumedCategory(receipts),
                countMonthlyEcoConsumption(receipts, currentMonth),
                previousMonthRank,
                currentMonthRank,
                buildRankingMessage(previousMonthRank, currentMonthRank)
        );
    }

    private Integer calculateMonthlyRank(String userId, YearMonth targetMonth) {
        List<QueryDocumentSnapshot> users = myPageRepository.findUsers();
        List<UserMonthlyPoint> points = new ArrayList<>();

        for (QueryDocumentSnapshot user : users) {
            int monthlyPoint = calculateEcoPoint(
                    filterReceiptsByMonth(myPageRepository.findReceipts(user.getId()), targetMonth)
            );

            if (monthlyPoint <= 0) {
                continue;
            }

            points.add(new UserMonthlyPoint(user.getId(), monthlyPoint));
        }

        points.sort(Comparator
                .comparingInt(UserMonthlyPoint::point)
                .reversed()
                .thenComparing(UserMonthlyPoint::userId));

        for (int i = 0; i < points.size(); i++) {
            if (points.get(i).userId().equals(userId)) {
                return i + 1;
            }
        }

        return null;
    }

    private List<QueryDocumentSnapshot> filterReceiptsByMonth(
            List<QueryDocumentSnapshot> receipts,
            YearMonth targetMonth
    ) {
        List<QueryDocumentSnapshot> filteredReceipts = new ArrayList<>();

        for (QueryDocumentSnapshot receipt : receipts) {
            Optional<YearMonth> receiptMonth = readReceiptMonth(receipt);
            if (receiptMonth.isPresent() && receiptMonth.get().equals(targetMonth)) {
                filteredReceipts.add(receipt);
            }
        }

        return filteredReceipts;
    }

    private int calculateEcoPoint(List<QueryDocumentSnapshot> receipts) {
        int totalPoint = 0;

        for (QueryDocumentSnapshot receipt : receipts) {
            totalPoint += calculateReceiptPoint(receipt);
        }

        return totalPoint;
    }

    private int calculateReceiptPoint(QueryDocumentSnapshot receipt) {
        Object rawItems = receipt.get("items");
        if (!(rawItems instanceof List<?> items)) {
            return 0;
        }

        int receiptPoint = 0;
        for (Object rawItem : items) {
            if (!(rawItem instanceof Map<?, ?> item)) {
                continue;
            }

            receiptPoint += pointFromCarbonScore(readInt(item.get("carbonScore")));
        }

        return receiptPoint;
    }

    private int countMonthlyEcoConsumption(
            List<QueryDocumentSnapshot> receipts,
            YearMonth currentMonth
    ) {
        int count = 0;

        for (QueryDocumentSnapshot receipt : receipts) {
            Optional<YearMonth> receiptMonth = readReceiptMonth(receipt);
            if (receiptMonth.isEmpty() || !receiptMonth.get().equals(currentMonth)) {
                continue;
            }

            Object rawItems = receipt.get("items");
            if (!(rawItems instanceof List<?> items)) {
                continue;
            }

            for (Object rawItem : items) {
                if (!(rawItem instanceof Map<?, ?> item)) {
                    continue;
                }

                int carbonScore = readInt(item.get("carbonScore"));
                if (carbonScore > 0 && carbonScore <= ECO_FRIENDLY_MAX_CARBON_SCORE) {
                    count++;
                }
            }
        }

        return count;
    }

    private String findMostConsumedCategory(List<QueryDocumentSnapshot> receipts) {
        Map<String, Integer> categoryCounts = new HashMap<>();

        for (QueryDocumentSnapshot receipt : receipts) {
            Object rawItems = receipt.get("items");
            if (!(rawItems instanceof List<?> items)) {
                continue;
            }

            for (Object rawItem : items) {
                if (!(rawItem instanceof Map<?, ?> item)) {
                    continue;
                }

                String category = readString(item.get("category"));
                if (category.isBlank()) {
                    continue;
                }

                categoryCounts.merge(category, 1, Integer::sum);
            }
        }

        return categoryCounts.entrySet()
                .stream()
                .max(Map.Entry.<String, Integer>comparingByValue()
                        .thenComparing(Map.Entry.comparingByKey()))
                .map(Map.Entry::getKey)
                .orElse("아직 분석된 카테고리가 없습니다.");
    }

    private Optional<YearMonth> readReceiptMonth(QueryDocumentSnapshot receipt) {
        Object purchasedAt = receipt.get("purchasedAt");
        Optional<YearMonth> purchasedMonth = parseMonth(purchasedAt);
        if (purchasedMonth.isPresent()) {
            return purchasedMonth;
        }

        return parseMonth(receipt.get("createdAt"));
    }

    private Optional<YearMonth> parseMonth(Object value) {
        if (value instanceof Timestamp timestamp) {
            Instant instant = Instant.ofEpochSecond(
                    timestamp.getSeconds(),
                    timestamp.getNanos()
            );
            return Optional.of(YearMonth.from(instant.atZone(SERVICE_ZONE)));
        }

        if (!(value instanceof String text) || text.isBlank()) {
            return Optional.empty();
        }

        String trimmedText = text.trim();
        List<DateTimeFormatter> formatters = List.of(
                DateTimeFormatter.ISO_LOCAL_DATE,
                DateTimeFormatter.ofPattern("yyyy.MM.dd", Locale.KOREA),
                DateTimeFormatter.ofPattern("yyyy/MM/dd", Locale.KOREA)
        );
        List<DateTimeFormatter> dateTimeFormatters = List.of(
                DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss", Locale.KOREA),
                DateTimeFormatter.ofPattern("yyyy.MM.dd HH:mm:ss", Locale.KOREA),
                DateTimeFormatter.ofPattern("yyyy/MM/dd HH:mm:ss", Locale.KOREA)
        );

        for (DateTimeFormatter formatter : formatters) {
            try {
                return Optional.of(YearMonth.from(LocalDate.parse(trimmedText, formatter)));
            } catch (DateTimeParseException ignored) {
                // Try the next supported receipt date format.
            }
        }

        for (DateTimeFormatter formatter : dateTimeFormatters) {
            try {
                return Optional.of(YearMonth.from(LocalDateTime.parse(trimmedText, formatter)));
            } catch (DateTimeParseException ignored) {
                // Try the next supported receipt date-time format.
            }
        }

        return Optional.empty();
    }

    private String buildRankingMessage(
            Integer previousMonthRank,
            Integer currentMonthRank
    ) {
        if (currentMonthRank == null) {
            return "이번 달 친환경 소비 기록을 쌓으면 랭킹 비교가 표시됩니다.";
        }
        if (previousMonthRank == null) {
            return "이번 달 현재 " + currentMonthRank + "위예요. 첫 비교 기록을 쌓고 있어요.";
        }

        int diff = previousMonthRank - currentMonthRank;
        if (diff > 0) {
            return "전달보다 " + diff + "계단 올랐어요. 좋은 흐름이에요!";
        }
        if (diff < 0) {
            return "전달보다 " + Math.abs(diff) + "계단 내려갔어요. 이번 달 다시 올려봐요.";
        }

        return "전달과 같은 " + currentMonthRank + "위를 유지하고 있어요.";
    }

    private String calculateGrade(int ecoPoint) {
        if (ecoPoint >= 3000) {
            return "Forest";
        }
        if (ecoPoint >= 1500) {
            return "Tree";
        }
        if (ecoPoint >= 500) {
            return "Sprout";
        }
        return "Seed";
    }

    private int pointFromCarbonScore(int carbonScore) {
        if (carbonScore <= 0) {
            return 0;
        }
        return Math.max(20, (6 - carbonScore) * 20);
    }

    private int readInt(Object value) {
        if (value instanceof Number number) {
            return number.intValue();
        }
        if (value instanceof String text) {
            try {
                return Integer.parseInt(text);
            } catch (NumberFormatException ignored) {
                return 0;
            }
        }
        return 0;
    }

    private String readString(DocumentSnapshot document, String key, String fallback) {
        String value = document.getString(key);
        if (value == null || value.isBlank()) {
            return fallback;
        }
        return value;
    }

    private String readString(Object value) {
        if (value instanceof String text) {
            return text.trim();
        }
        return "";
    }

    private record UserMonthlyPoint(String userId, int point) {
    }
}
