package com.eco.backend.ranking.service;

import com.eco.backend.ranking.dto.RankingUserResponse;
import com.eco.backend.ranking.repository.RankingRepository;
import com.google.cloud.firestore.QueryDocumentSnapshot;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Map;

@Service
public class RankingService {

    private static final int DEFAULT_LIMIT = 30;
    private static final int MAX_LIMIT = 100;

    private final RankingRepository rankingRepository;

    public RankingService(RankingRepository rankingRepository) {
        this.rankingRepository = rankingRepository;
    }

    public List<RankingUserResponse> getRankings(Integer requestedLimit) {
        int limit = normalizeLimit(requestedLimit);
        List<QueryDocumentSnapshot> users = rankingRepository.findUsers();
        List<RankingUserResponse> rankings = new ArrayList<>();

        for (int i = 0; i < users.size(); i++) {
            QueryDocumentSnapshot user = users.get(i);
            int ecoPoint = calculateEcoPoints(user.getId());

            if (ecoPoint <= 0) {
                continue;
            }

            rankings.add(new RankingUserResponse(
                    0,
                    user.getId(),
                    readNickname(user, i),
                    ecoPoint,
                    readGrade(user)
            ));
        }

        rankings.sort(Comparator
                .comparingInt(RankingUserResponse::getEcoPoint)
                .reversed()
                .thenComparing(RankingUserResponse::getNickname));

        List<RankingUserResponse> rankedUsers = new ArrayList<>();
        int resultSize = Math.min(limit, rankings.size());

        for (int i = 0; i < resultSize; i++) {
            RankingUserResponse ranking = rankings.get(i);
            rankedUsers.add(new RankingUserResponse(
                    i + 1,
                    ranking.getUserId(),
                    ranking.getNickname(),
                    ranking.getEcoPoint(),
                    ranking.getGrade()
            ));
        }

        return rankedUsers;
    }

    private int normalizeLimit(Integer requestedLimit) {
        if (requestedLimit == null) {
            return DEFAULT_LIMIT;
        }
        return Math.max(1, Math.min(requestedLimit, MAX_LIMIT));
    }

    private String readNickname(QueryDocumentSnapshot user, int index) {
        String nickname = user.getString("nickname");
        if (nickname != null && !nickname.isBlank()) {
            return nickname;
        }
        return "ECO 유저 " + (index + 1);
    }

    private int calculateEcoPoints(String userId) {
        List<QueryDocumentSnapshot> receipts =
                rankingRepository.findReceiptsByUserId(userId);
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
        return 0;
    }

    private String readGrade(QueryDocumentSnapshot user) {
        String grade = user.getString("grade");
        if (grade != null && !grade.isBlank()) {
            return grade;
        }
        return "Seed";
    }
}
