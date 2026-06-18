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
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;
import java.util.Set;

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
        int monthlyEcoConsumptionCount = countMonthlyEcoConsumption(receipts, currentMonth);
        int totalEcoConsumptionCount = countTotalEcoConsumption(receipts);
        int categoryCount = countCategories(receipts);
        int monthlyReceiptAnalysisCount = countMonthlyReceipts(receipts, currentMonth);
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
                monthlyEcoConsumptionCount,
                previousMonthRank,
                currentMonthRank,
                buildRankingMessage(previousMonthRank, currentMonthRank),
                awardAndLoadBadges(
                        userId,
                        receipts,
                        receipts.size(),
                        totalEcoConsumptionCount,
                        monthlyEcoConsumptionCount,
                        monthlyReceiptAnalysisCount,
                        categoryCount,
                        previousMonthRank,
                        currentMonthRank,
                        currentMonth
                )
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

    private int countMonthlyReceipts(
            List<QueryDocumentSnapshot> receipts,
            YearMonth targetMonth
    ) {
        int count = 0;

        for (QueryDocumentSnapshot receipt : receipts) {
            Optional<YearMonth> receiptMonth = readReceiptMonth(receipt);
            if (receiptMonth.isPresent() && receiptMonth.get().equals(targetMonth)) {
                count++;
            }
        }

        return count;
    }

    private int countTotalEcoConsumption(List<QueryDocumentSnapshot> receipts) {
        int count = 0;

        for (QueryDocumentSnapshot receipt : receipts) {
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

    private int countCategories(List<QueryDocumentSnapshot> receipts) {
        Map<String, Boolean> categories = new HashMap<>();

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
                if (!category.isBlank()) {
                    categories.put(category, true);
                }
            }
        }

        return categories.size();
    }

    private boolean hasBalancedEcoConsumption(List<QueryDocumentSnapshot> receipts) {
        Map<String, Integer> ecoCategoryCounts = new HashMap<>();
        int totalEcoItemCount = 0;

        for (QueryDocumentSnapshot receipt : receipts) {
            Object rawItems = receipt.get("items");
            if (!(rawItems instanceof List<?> items)) {
                continue;
            }

            for (Object rawItem : items) {
                if (!(rawItem instanceof Map<?, ?> item)) {
                    continue;
                }

                int carbonScore = readInt(item.get("carbonScore"));
                String category = readString(item.get("category"));
                if (
                        carbonScore > 0
                                && carbonScore <= ECO_FRIENDLY_MAX_CARBON_SCORE
                                && !category.isBlank()
                ) {
                    totalEcoItemCount++;
                    ecoCategoryCounts.merge(category, 1, Integer::sum);
                }
            }
        }

        if (ecoCategoryCounts.size() < 3 || totalEcoItemCount == 0) {
            return false;
        }

        int topCategoryCount = ecoCategoryCounts
                .values()
                .stream()
                .max(Integer::compareTo)
                .orElse(0);

        return topCategoryCount <= totalEcoItemCount * 0.6;
    }

    private boolean hasThreeMonthReceiptStreak(
            List<QueryDocumentSnapshot> receipts,
            YearMonth currentMonth
    ) {
        return countMonthlyReceipts(receipts, currentMonth) > 0
                && countMonthlyReceipts(receipts, currentMonth.minusMonths(1)) > 0
                && countMonthlyReceipts(receipts, currentMonth.minusMonths(2)) > 0;
    }

    private boolean hasHighScoreReceipt(List<QueryDocumentSnapshot> receipts) {
        for (QueryDocumentSnapshot receipt : receipts) {
            if (calculateReceiptPoint(receipt) >= 300) {
                return true;
            }
        }

        return false;
    }

    private boolean hasPerfectGreenReceipt(List<QueryDocumentSnapshot> receipts) {
        for (QueryDocumentSnapshot receipt : receipts) {
            Object rawItems = receipt.get("items");
            if (!(rawItems instanceof List<?> items) || items.isEmpty()) {
                continue;
            }

            boolean allItemsAreGreen = true;
            for (Object rawItem : items) {
                if (!(rawItem instanceof Map<?, ?> item)) {
                    allItemsAreGreen = false;
                    break;
                }

                int carbonScore = readInt(item.get("carbonScore"));
                if (carbonScore <= 0 || carbonScore > ECO_FRIENDLY_MAX_CARBON_SCORE) {
                    allItemsAreGreen = false;
                    break;
                }
            }

            if (allItemsAreGreen) {
                return true;
            }
        }

        return false;
    }

    private boolean hasComebackConsumption(
            List<QueryDocumentSnapshot> receipts,
            YearMonth currentMonth
    ) {
        return countMonthlyReceipts(receipts, currentMonth.minusMonths(1)) == 0
                && countMonthlyReceipts(receipts, currentMonth) > 0;
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

    private List<MyPageBadgeResponse> awardAndLoadBadges(
            String userId,
            List<QueryDocumentSnapshot> receipts,
            int receiptAnalysisCount,
            int totalEcoConsumptionCount,
            int monthlyEcoConsumptionCount,
            int monthlyReceiptAnalysisCount,
            int categoryCount,
            Integer previousMonthRank,
            Integer currentMonthRank,
            YearMonth currentMonth
    ) {
        List<QueryDocumentSnapshot> savedBadgeDocuments = myPageRepository.findBadges(userId);
        Set<String> savedBadgeIds = new HashSet<>();

        for (QueryDocumentSnapshot badgeDocument : savedBadgeDocuments) {
            savedBadgeIds.add(badgeDocument.getId());
        }

        for (MyPageBadgeResponse badge : buildBadgeCandidates(
                receipts,
                receiptAnalysisCount,
                totalEcoConsumptionCount,
                monthlyEcoConsumptionCount,
                monthlyReceiptAnalysisCount,
                categoryCount,
                previousMonthRank,
                currentMonthRank,
                currentMonth
        )) {
            if (!savedBadgeIds.contains(badge.getId())) {
                myPageRepository.saveBadge(userId, badge);
            }
        }

        return myPageRepository.findBadges(userId)
                .stream()
                .map(this::toBadgeResponse)
                .sorted(Comparator
                        .comparingInt(MyPageBadgeResponse::getSortOrder)
                        .thenComparing(MyPageBadgeResponse::getId))
                .toList();
    }

    private List<MyPageBadgeResponse> buildBadgeCandidates(
            List<QueryDocumentSnapshot> receipts,
            int receiptAnalysisCount,
            int totalEcoConsumptionCount,
            int monthlyEcoConsumptionCount,
            int monthlyReceiptAnalysisCount,
            int categoryCount,
            Integer previousMonthRank,
            Integer currentMonthRank,
            YearMonth currentMonth
    ) {
        List<MyPageBadgeResponse> badges = new ArrayList<>();
        String monthKey = currentMonth.format(DateTimeFormatter.ofPattern("yyyy_MM"));
        String monthLabel = currentMonth.format(DateTimeFormatter.ofPattern("yyyy년 M월", Locale.KOREA));
        boolean isMonthEnd = LocalDate.now(SERVICE_ZONE).equals(currentMonth.atEndOfMonth());

        if (isMonthEnd && currentMonthRank != null && currentMonthRank == 1) {
            badges.add(new MyPageBadgeResponse(
                    "monthly_gold_leaf_" + monthKey,
                    "금잎 배지",
                    monthLabel + " 월말 친환경 랭킹 1위",
                    "gold",
                    "monthly",
                    10
            ));
        } else if (isMonthEnd && currentMonthRank != null && currentMonthRank == 2) {
            badges.add(new MyPageBadgeResponse(
                    "monthly_silver_leaf_" + monthKey,
                    "은잎 배지",
                    monthLabel + " 월말 친환경 랭킹 2위",
                    "silver",
                    "monthly",
                    20
            ));
        } else if (isMonthEnd && currentMonthRank != null && currentMonthRank == 3) {
            badges.add(new MyPageBadgeResponse(
                    "monthly_bronze_leaf_" + monthKey,
                    "동잎 배지",
                    monthLabel + " 월말 친환경 랭킹 3위",
                    "bronze",
                    "monthly",
                    30
            ));
        }

        if (receiptAnalysisCount >= 1) {
            badges.add(new MyPageBadgeResponse(
                    "first_step",
                    "첫 발자국",
                    "영수증 분석 1회 완료",
                    "green",
                    "permanent",
                    100
            ));
        }
        if (receiptAnalysisCount >= 10) {
            badges.add(new MyPageBadgeResponse(
                    "analysis_routine",
                    "분석 루틴러",
                    "영수증 분석 10회 완료",
                    "green",
                    "permanent",
                    110
            ));
        }
        if (receiptAnalysisCount >= 30) {
            badges.add(new MyPageBadgeResponse(
                    "record_keeper",
                    "기록왕",
                    "영수증 분석 30회 완료",
                    "green",
                    "permanent",
                    120
            ));
        }
        if (totalEcoConsumptionCount >= 5) {
            badges.add(new MyPageBadgeResponse(
                    "eco_beginner",
                    "친환경 입문자",
                    "친환경 소비 5회 달성",
                    "mint",
                    "permanent",
                    130
            ));
        }
        if (totalEcoConsumptionCount >= 20) {
            badges.add(new MyPageBadgeResponse(
                    "green_basket",
                    "초록 장바구니",
                    "친환경 소비 20회 달성",
                    "mint",
                    "permanent",
                    140
            ));
        }
        if (monthlyEcoConsumptionCount >= 10) {
            badges.add(new MyPageBadgeResponse(
                    "low_carbon_routine_" + monthKey,
                    "저탄소 루틴",
                    monthLabel + " 친환경 소비 10회 달성",
                    "mint",
                    "monthly",
                    150
            ));
        }
        if (categoryCount >= 5) {
            badges.add(new MyPageBadgeResponse(
                    "category_explorer",
                    "카테고리 탐험가",
                    "서로 다른 소비 카테고리 5개 이상 분석",
                    "blue",
                    "permanent",
                    160
            ));
        }
        if (hasBalancedEcoConsumption(receipts)) {
            badges.add(new MyPageBadgeResponse(
                    "balanced_consumer",
                    "균형 소비러",
                    "3개 이상 카테고리에서 고르게 친환경 소비",
                    "blue",
                    "permanent",
                    170
            ));
        }
        if (currentMonthRank != null && currentMonthRank <= 10) {
            badges.add(new MyPageBadgeResponse(
                    "top_ten_" + monthKey,
                    "TOP 10",
                    monthLabel + " 친환경 랭킹 10위 안 진입",
                    "blue",
                    "monthly",
                    40
            ));
        }
        if (
                previousMonthRank != null
                        && currentMonthRank != null
                        && currentMonthRank < previousMonthRank
        ) {
            badges.add(new MyPageBadgeResponse(
                    "rising_rank_" + monthKey,
                    "상승세",
                    monthLabel + " 전달 대비 랭킹 상승",
                    "blue",
                    "monthly",
                    50
            ));
        }
        if (hasThreeMonthReceiptStreak(receipts, currentMonth)) {
            badges.add(new MyPageBadgeResponse(
                    "three_month_streak",
                    "꾸준왕",
                    "3개월 연속 영수증 분석",
                    "green",
                    "permanent",
                    180
            ));
        }
        if (monthlyReceiptAnalysisCount >= 5) {
            badges.add(new MyPageBadgeResponse(
                    "monthly_focus_" + monthKey,
                    "이번 달 집중러",
                    monthLabel + " 영수증 분석 5회 이상",
                    "mint",
                    "monthly",
                    190
            ));
        }
        if (hasHighScoreReceipt(receipts)) {
            badges.add(new MyPageBadgeResponse(
                    "high_score_receipt",
                    "고득점 영수증",
                    "한 영수증에서 Eco Point 300점 이상 획득",
                    "gold",
                    "permanent",
                    200
            ));
        }
        if (hasPerfectGreenReceipt(receipts)) {
            badges.add(new MyPageBadgeResponse(
                    "perfect_green_receipt",
                    "완벽한 초록 소비",
                    "한 영수증의 모든 품목이 친환경 기준 충족",
                    "mint",
                    "permanent",
                    210
            ));
        }
        if (hasComebackConsumption(receipts, currentMonth)) {
            badges.add(new MyPageBadgeResponse(
                    "comeback_practitioner_" + monthKey,
                    "다시 돌아온 실천가",
                    monthLabel + " 지난달 기록 없이 다시 분석",
                    "blue",
                    "monthly",
                    220
            ));
        }

        return badges;
    }

    private MyPageBadgeResponse toBadgeResponse(QueryDocumentSnapshot badgeDocument) {
        return new MyPageBadgeResponse(
                readString(badgeDocument, "id", badgeDocument.getId()),
                readString(badgeDocument, "name", "배지"),
                readString(badgeDocument, "description", ""),
                readString(badgeDocument, "tone", "green"),
                readString(badgeDocument, "type", "permanent"),
                readInt(badgeDocument.get("sortOrder"))
        );
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
