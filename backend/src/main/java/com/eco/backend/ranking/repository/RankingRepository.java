package com.eco.backend.ranking.repository;

import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.Query;
import com.google.cloud.firestore.QueryDocumentSnapshot;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.concurrent.ExecutionException;

@Repository
public class RankingRepository {

    private final Firestore firestore;

    public RankingRepository(Firestore firestore) {
        this.firestore = firestore;
    }

    public List<QueryDocumentSnapshot> findTopUsersByEcoPoint(int limit) {
        try {
            return firestore
                    .collection("users")
                    .orderBy("ecoPoint", Query.Direction.DESCENDING)
                    .limit(limit)
                    .get()
                    .get()
                    .getDocuments();
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new IllegalStateException("랭킹 조회 중 작업이 중단되었습니다.", e);
        } catch (ExecutionException e) {
            throw new IllegalStateException("Firestore에서 랭킹을 조회하지 못했습니다.", e);
        }
    }
}
