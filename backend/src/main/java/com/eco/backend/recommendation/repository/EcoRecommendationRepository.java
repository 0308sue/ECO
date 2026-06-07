package com.eco.backend.recommendation.repository;

import com.eco.backend.recommendation.domain.EcoItem;
import com.eco.backend.recommendation.domain.EcoPlace;
import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.QueryDocumentSnapshot;
import com.google.firebase.cloud.FirestoreClient;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public class EcoRecommendationRepository {

    public List<EcoItem> findAllActiveEcoItems() throws Exception {
        Firestore db = FirestoreClient.getFirestore();

        List<QueryDocumentSnapshot> documents = db.collection("eco_items")
                .whereEqualTo("isActive", true)
                .get()
                .get()
                .getDocuments();

        return documents.stream()
                .map(document -> document.toObject(EcoItem.class))
                .toList();
    }

    public List<EcoItem> findActiveEcoItemsByName(String itemName) throws Exception {
        Firestore db = FirestoreClient.getFirestore();

        List<QueryDocumentSnapshot> documents = db.collection("eco_items")
                .whereEqualTo("name", itemName)
                .whereEqualTo("isActive", true)
                .get()
                .get()
                .getDocuments();

        return documents.stream()
                .map(document -> document.toObject(EcoItem.class))
                .toList();
    }

    public List<EcoPlace> findAllActiveEcoPlaces() throws Exception {
        Firestore db = FirestoreClient.getFirestore();

        List<QueryDocumentSnapshot> documents = db.collection("eco_places")
                .whereEqualTo("isActive", true)
                .get()
                .get()
                .getDocuments();

        return documents.stream()
                .map(document -> document.toObject(EcoPlace.class))
                .toList();
    }

    public List<EcoPlace> findActivePlacesByType(String placeType) throws Exception {
        Firestore db = FirestoreClient.getFirestore();

        List<QueryDocumentSnapshot> documents = db.collection("eco_places")
                .whereEqualTo("type", placeType)
                .whereEqualTo("isActive", true)
                .get()
                .get()
                .getDocuments();

        return documents.stream()
                .map(document -> document.toObject(EcoPlace.class))
                .toList();
    }
}