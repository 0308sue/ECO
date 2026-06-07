package com.eco.backend.config;

import com.google.cloud.firestore.Firestore;
import com.google.firebase.cloud.FirestoreClient;
import org.apache.commons.csv.CSVFormat;
import org.apache.commons.csv.CSVRecord;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.Reader;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Map;
import java.util.HashMap;

@Component
public class EcoPlaceDataImporter implements CommandLineRunner {

    @Value("${eco.import.places.enabled:false}")
    private boolean importEnabled;

    @Override
    public void run(String... args) throws Exception {
        if (!importEnabled) {
            return;
        }

        InputStream inputStream = getClass().getResourceAsStream("/data/zero_waste_places.csv");

        if (inputStream == null) {
            System.out.println("zero_waste_places.csv 파일을 찾을 수 없습니다.");
            return;
        }

        Firestore db = FirestoreClient.getFirestore();

        Reader reader = new InputStreamReader(inputStream, StandardCharsets.UTF_8);

        Iterable<CSVRecord> records = CSVFormat.DEFAULT
                .builder()
                .setHeader()
                .setSkipHeaderRecord(true)
                .build()
                .parse(reader);

        int count = 0;

        for (CSVRecord record : records) {
            String name = getValue(record, "display1");
            String address = getValue(record, "display2");
            String memo = getValue(record, "memo");

            Double lat = toDouble(getValue(record, "lat"));
            Double lng = toDouble(getValue(record, "lon"));

            if (name.isBlank() || lat == null || lng == null) {
                continue;
            }

            String sourcePlaceId = getValue(record, "seq");

            if (sourcePlaceId.isBlank()) {
                sourcePlaceId = getValue(record, "key");
            }

            String sourceGroupId = getValue(record, "folderId");

            String type = inferType(name, memo);

            Map<String, Object> place = new HashMap<>();
            place.put("name", name);
            place.put("type", type);
            place.put("address", address);
            place.put("lat", lat);
            place.put("lng", lng);
            place.put("phone", "");
            place.put("availableItems", inferAvailableItems(type));
            place.put("description", memo.isBlank() ? type + " 관련 장소입니다." : memo);
            place.put("sourceName", "제로웨이스트숍/리필/재활용 가게 지도");
            place.put("sourceUrl", "");
            place.put("sourcePlaceId", sourcePlaceId);
            place.put("sourceGroupId", sourceGroupId);
            place.put("isActive", true);

            String docId = sourcePlaceId.isBlank()
                    ? db.collection("eco_places").document().getId()
                    : "kakao_" + sourcePlaceId;

            db.collection("eco_places")
                    .document(docId)
                    .set(place)
                    .get();

            count++;
        }

        System.out.println("EcoPlace 데이터 import 완료: " + count + "개");
    }

    private String getValue(CSVRecord record, String columnName) {
        try {
            if (!record.isMapped(columnName)) {
                return "";
            }

            String value = record.get(columnName);
            return value == null ? "" : value.trim();
        } catch (Exception e) {
            return "";
        }
    }

    private Double toDouble(String value) {
        try {
            if (value == null || value.isBlank()) {
                return null;
            }

            return Double.parseDouble(value.trim());
        } catch (Exception e) {
            return null;
        }
    }

    private String inferType(String name, String memo) {
        String text = name + " " + memo;

        if (text.contains("리필") || text.contains("소분") || text.contains("알맹")) {
            return "리필샵";
        }

        if (text.contains("재활용") || text.contains("자원순환") || text.contains("새활용")) {
            return "재활용매장";
        }

        if (text.contains("중고") || text.contains("아름다운가게") || text.contains("굿윌")) {
            return "중고매장";
        }

        if (text.contains("식당") || text.contains("카페")) {
            return "친환경매장";
        }

        return "제로웨이스트샵";
    }

    private List<String> inferAvailableItems(String type) {
        return switch (type) {
            case "리필샵" -> List.of("세제", "샴푸", "화장품", "비누", "용기");
            case "재활용매장" -> List.of("재활용품", "새활용품");
            case "중고매장" -> List.of("의류", "생활용품", "중고제품");
            case "친환경매장" -> List.of("친환경 제품", "다회용품");
            default -> List.of("텀블러", "장바구니", "샴푸바", "고체비누", "다회용품");
        };
    }
}