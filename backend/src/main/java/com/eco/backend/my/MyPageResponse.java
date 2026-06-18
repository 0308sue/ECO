package com.eco.backend.my;

import java.util.List;

public class MyPageResponse {

    private final String userId;
    private final String nickname;
    private final String email;
    private final int ecoPoint;
    private final String grade;
    private final int receiptAnalysisCount;
    private final int totalSavedScore;
    private final String mostConsumedCategory;
    private final int monthlyEcoConsumptionCount;
    private final Integer previousMonthRank;
    private final Integer currentMonthRank;
    private final String rankingMessage;
    private final List<MyPageBadgeResponse> badges;

    public MyPageResponse(
            String userId,
            String nickname,
            String email,
            int ecoPoint,
            String grade,
            int receiptAnalysisCount,
            int totalSavedScore,
            String mostConsumedCategory,
            int monthlyEcoConsumptionCount,
            Integer previousMonthRank,
            Integer currentMonthRank,
            String rankingMessage,
            List<MyPageBadgeResponse> badges
    ) {
        this.userId = userId;
        this.nickname = nickname;
        this.email = email;
        this.ecoPoint = ecoPoint;
        this.grade = grade;
        this.receiptAnalysisCount = receiptAnalysisCount;
        this.totalSavedScore = totalSavedScore;
        this.mostConsumedCategory = mostConsumedCategory;
        this.monthlyEcoConsumptionCount = monthlyEcoConsumptionCount;
        this.previousMonthRank = previousMonthRank;
        this.currentMonthRank = currentMonthRank;
        this.rankingMessage = rankingMessage;
        this.badges = badges;
    }

    public String getUserId() {
        return userId;
    }

    public String getNickname() {
        return nickname;
    }

    public String getEmail() {
        return email;
    }

    public int getEcoPoint() {
        return ecoPoint;
    }

    public String getGrade() {
        return grade;
    }

    public int getReceiptAnalysisCount() {
        return receiptAnalysisCount;
    }

    public int getTotalSavedScore() {
        return totalSavedScore;
    }

    public String getMostConsumedCategory() {
        return mostConsumedCategory;
    }

    public int getMonthlyEcoConsumptionCount() {
        return monthlyEcoConsumptionCount;
    }

    public Integer getPreviousMonthRank() {
        return previousMonthRank;
    }

    public Integer getCurrentMonthRank() {
        return currentMonthRank;
    }

    public String getRankingMessage() {
        return rankingMessage;
    }

    public List<MyPageBadgeResponse> getBadges() {
        return badges;
    }
}
