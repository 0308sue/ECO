package com.eco.backend.ranking.service;

import com.eco.backend.ranking.dto.RankingUserResponse;
import com.eco.backend.ranking.repository.RankingRepository;
import com.google.cloud.firestore.QueryDocumentSnapshot;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

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
        List<QueryDocumentSnapshot> users =
                rankingRepository.findTopUsersByEcoPoint(limit);
        List<RankingUserResponse> rankings = new ArrayList<>();

        for (int i = 0; i < users.size(); i++) {
            QueryDocumentSnapshot user = users.get(i);
            rankings.add(new RankingUserResponse(
                    i + 1,
                    user.getId(),
                    readNickname(user, i),
                    readEcoPoint(user),
                    readGrade(user)
            ));
        }

        return rankings;
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

    private int readEcoPoint(QueryDocumentSnapshot user) {
        Long ecoPoint = user.getLong("ecoPoint");
        if (ecoPoint == null) {
            return 0;
        }
        return ecoPoint.intValue();
    }

    private String readGrade(QueryDocumentSnapshot user) {
        String grade = user.getString("grade");
        if (grade != null && !grade.isBlank()) {
            return grade;
        }
        return "Seed";
    }
}
