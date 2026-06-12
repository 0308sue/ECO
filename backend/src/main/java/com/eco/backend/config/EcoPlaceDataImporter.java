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
        String text = ((name == null ? "" : name) + " " + (memo == null ? "" : memo))
                .toLowerCase();

        if (containsAny(text, "리필", "소분", "알맹", "refill", "정기리필", "방문리필")) {
            return "리필스테이션";
        }

        if (containsAny(text, "카페", "커피", "coffee", "요거트", "디저트", "찻집", "티하우스")) {
            return "친환경카페";
        }

        if (containsAny(text, "식당", "반찬", "음식", "푸드", "도시락", "비건식당", "밥집", "분식", "레스토랑", "키친", "버거", "샌드위치")) {
            return "친환경식당";
        }

        if (containsAny(text, "빵", "베이커리", "비건베이커리", "제과", "우리밀")) {
            return "친환경식당";
        }

        if (containsAny(text, "농산물", "로컬푸드", "무포장", "마켓", "생협", "한살림", "두레생협", "자연드림", "초록마을")) {
            return "로컬푸드/무포장마켓";
        }

        if (containsAny(text, "재활용", "자원순환", "리사이클", "분리", "종이팩", "건전지", "수거", "되살림", "리워드", "새활용", "아름다운가게", "굿윌")) {
            return "재활용센터/자원순환가게";
        }

        if (containsAny(text, "공방", "체험", "클래스", "제작", "워크숍", "워크샵")) {
            return "공방/체험";
        }

        return "제로웨이스트샵";
    }

    private List<String> inferAvailableItems(String type) {
        return switch (type) {
            case "친환경카페" -> List.of("텀블러", "다회용컵", "개인컵", "음료");
            case "친환경식당" -> List.of("다회용기", "도시락통", "포장재 절감", "비건식품");
            case "리필스테이션" -> List.of("세제", "샴푸", "린스", "바디워시", "화장품", "용기");
            case "로컬푸드/무포장마켓" -> List.of("장바구니", "무포장 식품", "로컬푸드", "농산물");
            case "재활용센터/자원순환가게" -> List.of("재활용품", "새활용품", "종이팩", "폐건전지", "중고제품");
            case "공방/체험" -> List.of("업사이클 체험", "친환경 클래스", "재사용 제품");
            default -> List.of("텀블러", "장바구니", "샴푸바", "고체비누", "다회용품");
        };
    }

    private boolean containsAny(String text, String... keywords) {
        for (String keyword : keywords) {
            if (text.contains(keyword)) {
                return true;
            }
        }
        return false;
    }
}