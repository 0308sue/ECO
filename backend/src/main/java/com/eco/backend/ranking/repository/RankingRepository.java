package com.eco.backend.ranking.repository;

import com.google.cloud.firestore.Firestore;
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

    public List<QueryDocumentSnapshot> findUsers() {
        try {
            return firestore
                    .collection("users")
                    .get()
                    .get()
                    .getDocuments();
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new IllegalStateException("사용자 조회 중 작업이 중단되었습니다.", e);
        } catch (ExecutionException e) {
            throw new IllegalStateException("Firestore에서 사용자를 조회하지 못했습니다.", e);
        }
    }

    public List<QueryDocumentSnapshot> findReceiptsByUserId(String userId) {
        try {
            return firestore
                    .collection("users")
                    .document(userId)
                    .collection("receipts")
                    .get()
                    .get()
                    .getDocuments();
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new IllegalStateException("영수증 조회 중 작업이 중단되었습니다.", e);
        } catch (ExecutionException e) {
            throw new IllegalStateException("Firestore에서 영수증을 조회하지 못했습니다.", e);
        }
    }
}
