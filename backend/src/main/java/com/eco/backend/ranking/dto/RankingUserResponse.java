package com.eco.backend.ranking.dto;

public class RankingUserResponse {

    private final int rank;
    private final String userId;
    private final String nickname;
    private final int ecoPoint;
    private final String grade;

    public RankingUserResponse(
            int rank,
            String userId,
            String nickname,
            int ecoPoint,
            String grade
    ) {
        this.rank = rank;
        this.userId = userId;
        this.nickname = nickname;
        this.ecoPoint = ecoPoint;
        this.grade = grade;
    }

    public int getRank() {
        return rank;
    }

    public String getUserId() {
        return userId;
    }

    public String getNickname() {
        return nickname;
    }

    public int getEcoPoint() {
        return ecoPoint;
    }

    public String getGrade() {
        return grade;
    }
}
