package com.eco.backend.my;

import com.google.cloud.firestore.DocumentSnapshot;
import com.google.cloud.firestore.FieldValue;
import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.QueryDocumentSnapshot;
import org.springframework.stereotype.Repository;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.ExecutionException;

@Repository
public class MyPageRepository {

    private final Firestore firestore;

    public MyPageRepository(Firestore firestore) {
        this.firestore = firestore;
    }

    public Optional<DocumentSnapshot> findUser(String userId) {
        try {
            DocumentSnapshot user = firestore
                    .collection("users")
                    .document(userId)
                    .get()
                    .get();

            if (!user.exists()) {
                return Optional.empty();
            }

            return Optional.of(user);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new IllegalStateException("사용자 조회 중 작업이 중단되었습니다.", e);
        } catch (ExecutionException e) {
            throw new IllegalStateException("Firestore에서 사용자를 조회하지 못했습니다.", e);
        }
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
            throw new IllegalStateException("사용자 목록 조회 중 작업이 중단되었습니다.", e);
        } catch (ExecutionException e) {
            throw new IllegalStateException("Firestore에서 사용자 목록을 조회하지 못했습니다.", e);
        }
    }

    public List<QueryDocumentSnapshot> findReceipts(String userId) {
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

    public List<QueryDocumentSnapshot> findBadges(String userId) {
        try {
            return firestore
                    .collection("users")
                    .document(userId)
                    .collection("badges")
                    .get()
                    .get()
                    .getDocuments();
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new IllegalStateException("배지 조회 중 작업이 중단되었습니다.", e);
        } catch (ExecutionException e) {
            throw new IllegalStateException("Firestore에서 배지를 조회하지 못했습니다.", e);
        }
    }

    public void saveBadge(String userId, MyPageBadgeResponse badge) {
        Map<String, Object> badgeData = new LinkedHashMap<>();
        badgeData.put("id", badge.getId());
        badgeData.put("name", badge.getName());
        badgeData.put("description", badge.getDescription());
        badgeData.put("tone", badge.getTone());
        badgeData.put("type", badge.getType());
        badgeData.put("sortOrder", badge.getSortOrder());
        badgeData.put("earnedAt", FieldValue.serverTimestamp());

        try {
            firestore
                    .collection("users")
                    .document(userId)
                    .collection("badges")
                    .document(badge.getId())
                    .set(badgeData)
                    .get();
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new IllegalStateException("배지 저장 중 작업이 중단되었습니다.", e);
        } catch (ExecutionException e) {
            throw new IllegalStateException("Firestore에 배지를 저장하지 못했습니다.", e);
        }
    }
}
