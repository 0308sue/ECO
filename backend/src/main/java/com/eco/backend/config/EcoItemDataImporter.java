package com.eco.backend.config;

import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.WriteBatch;
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
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Component
public class EcoItemDataImporter implements CommandLineRunner {

    @Value("${eco.import.items.enabled:false}")
    private boolean importEnabled;

    @Override
    public void run(String... args) throws Exception {
        if (!importEnabled) {
            return;
        }

        InputStream inputStream = getClass().getResourceAsStream("/data/green_products.csv");

        if (inputStream == null) {
            System.out.println("green_products.csv 파일을 찾을 수 없습니다.");
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

        WriteBatch batch = db.batch();

        int count = 0;
        int skipped = 0;

        for (CSVRecord record : records) {
            String usage = getValue(record, "용도");
            String companyName = getValue(record, "업체명");
            String companyUrl = getValue(record, "홈페이지");
            String sourceItemId = getValue(record, "제품번호");
            String certificationNo = getValue(record, "인증번호");
            String productUseName = getValue(record, "제품용도명");
            String modelName = getValue(record, "모델명");
            String certificationStatus = getValue(record, "인증상태");
            String ecoLabelYn = getValue(record, "환경표지여부");
            String certificationStartDate = getValue(record, "환경표지인증시작일");
            String certificationEndDate = getValue(record, "환경표지인증종료일");
            String region = getValue(record, "지역");

            if (!isEcoItemCandidate(productUseName, modelName)) {
                skipped++;
                continue;
            }

            if (modelName.isBlank()) {
                skipped++;
                continue;
            }

            String category = inferCategory(productUseName);
            String subCategory = inferSubCategory(productUseName);
            List<String> keywords = inferKeywords(productUseName, modelName);

            Map<String, Object> item = new HashMap<>();
            item.put("name", modelName);
            item.put("category", category);
            item.put("subCategory", subCategory);
            item.put("keywords", keywords);

            item.put("companyName", companyName);
            item.put("companyUrl", companyUrl);

            item.put("certificationType", "환경표지");
            item.put("certificationNo", certificationNo);
            item.put("certificationStatus", certificationStatus);
            item.put("ecoLabelYn", ecoLabelYn);
            item.put("certificationStartDate", certificationStartDate);
            item.put("certificationEndDate", certificationEndDate);

            item.put("productUseName", productUseName);
            item.put("usage", usage);
            item.put("region", region);

            item.put("sourceItemId", sourceItemId);
            item.put("sourceName", "한국환경산업기술원 녹색제품정보시스템");
            item.put("sourceUrl", "공공데이터포털");
            item.put("isActive", true);

            item.put("reason", makeReason(subCategory));
            item.put("tip", makeTip(subCategory));
            item.put("imageUrl", "");

            String docId = makeDocId(certificationNo, modelName, companyName);

            batch.set(db.collection("eco_items").document(docId), item);
            count++;

            if (count % 450 == 0) {
                batch.commit().get();
                System.out.println("EcoItem " + count + "개 저장 완료");
                batch = db.batch();
            }
        }

        if (count % 450 != 0) {
            batch.commit().get();
        }

        System.out.println("EcoItem 데이터 import 완료: " + count + "개");
        System.out.println("필터링 제외: " + skipped + "개");
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

    private boolean isEcoItemCandidate(String productUseName, String modelName) {
        String text = (productUseName + " " + modelName).trim();

        if (text.isBlank()) {
            return false;
        }

        // 우리 서비스와 거리가 먼 산업/건축/원재료성 항목 제외
        List<String> excludeKeywords = List.of(
                "건축", "콘크리트", "블록", "벽지", "바닥재", "창호",
                "수도꼭지", "계량기", "등기구", "조명", "가구",
                "컴퓨터", "모니터", "프린터", "토너", "카트리지",
                "산업용", "원료", "펠릿", "펠렛", "시트",
                "농업용", "멀칭", "필름", "분골함"
        );

        for (String keyword : excludeKeywords) {
            if (text.contains(keyword)) {
                return false;
            }
        }

        // 실제 생활소비/제로웨이스트 추천에 연결 가능한 항목만 포함
        List<String> includeKeywords = List.of(
                "주방용 세제",
                "세탁용 세제",
                "섬유유연제",
                "다목적 세정제",
                "세정제",
                "세척제",
                "화장지",
                "수세용 타월",
                "수세용 타올",
                "비누",
                "샴푸",
                "린스",
                "바디클렌저",
                "탈취제",
                "방향제",
                "칫솔",
                "생분해성 식품 용기",
                "생분해성 식품 기구",
                "생분해성 용기",
                "생분해성 빨대",
                "생분해성수지 빨대",
                "생분해성 포장제품",
                "생분해성 봉투",
                "생분해성 쇼핑봉투",
                "다회용 식품 기구",
                "다회용 식품 용기"
        );

        for (String keyword : includeKeywords) {
            if (text.contains(keyword)) {
                return true;
            }
        }

        return false;
    }

    private String inferCategory(String productUseName) {
        if (productUseName.contains("생분해성")
                || productUseName.contains("다회용 식품")
                || productUseName.contains("빨대")
                || productUseName.contains("용기")
                || productUseName.contains("봉투")) {
            return "일회용품";
        }

        return "생활용품";
    }

    private String inferSubCategory(String productUseName) {
        if (productUseName.contains("주방용 세제")) {
            return "주방세제";
        }

        if (productUseName.contains("세탁용 세제")) {
            return "세탁세제";
        }

        if (productUseName.contains("섬유유연제")) {
            return "섬유유연제";
        }

        if (productUseName.contains("세정제") || productUseName.contains("세척제")) {
            return "세정제";
        }

        if (productUseName.contains("화장지")) {
            return "화장지류";
        }

        if (productUseName.contains("수세용 타월") || productUseName.contains("수세용 타올")) {
            return "수세미/타월";
        }

        if (productUseName.contains("비누")) {
            return "비누";
        }

        if (productUseName.contains("샴푸")) {
            return "샴푸";
        }

        if (productUseName.contains("린스")) {
            return "린스";
        }

        if (productUseName.contains("바디클렌저")) {
            return "바디클렌저";
        }

        if (productUseName.contains("탈취제")) {
            return "탈취제";
        }

        if (productUseName.contains("방향제")) {
            return "방향제";
        }

        if (productUseName.contains("칫솔")) {
            return "칫솔";
        }

        if (productUseName.contains("빨대")) {
            return "생분해 빨대";
        }

        if (productUseName.contains("봉투") || productUseName.contains("쇼핑봉투")) {
            return "생분해 봉투";
        }

        if (productUseName.contains("식품 용기") || productUseName.contains("식품 기구") || productUseName.contains("용기")) {
            return "생분해/다회용 용기";
        }

        return "친환경 생활용품";
    }

    private List<String> inferKeywords(String productUseName, String modelName) {
        String subCategory = inferSubCategory(productUseName);

        return switch (subCategory) {
            case "주방세제" -> List.of("주방세제", "세제", "설거지", "식기세제");
            case "세탁세제" -> List.of("세탁세제", "세제", "빨래", "세탁");
            case "섬유유연제" -> List.of("섬유유연제", "세탁", "빨래");
            case "세정제" -> List.of("세정제", "세척제", "청소", "클리너");
            case "화장지류" -> List.of("화장지", "휴지", "두루마리", "티슈");
            case "수세미/타월" -> List.of("수세미", "수세용타월", "주방타월");
            case "비누" -> List.of("비누", "고체비누", "세안");
            case "샴푸" -> List.of("샴푸", "샴푸바", "헤어");
            case "린스" -> List.of("린스", "컨디셔너", "헤어");
            case "바디클렌저" -> List.of("바디워시", "바디클렌저", "샤워");
            case "탈취제" -> List.of("탈취제", "냄새제거");
            case "방향제" -> List.of("방향제", "디퓨저", "향");
            case "칫솔" -> List.of("칫솔", "대나무칫솔", "구강용품");
            case "생분해 빨대" -> List.of("빨대", "일회용빨대", "생분해빨대");
            case "생분해 봉투" -> List.of("봉투", "비닐봉투", "쇼핑봉투", "생분해봉투");
            case "생분해/다회용 용기" -> List.of("종이컵", "일회용컵", "일회용용기", "배달용기", "식품용기");
            default -> Arrays.asList(productUseName, modelName);
        };
    }

    private String makeReason(String subCategory) {
        return switch (subCategory) {
            case "주방세제", "세탁세제", "섬유유연제", "세정제" ->
                    "환경표지 인증 제품을 선택하면 생활용품 사용 과정의 환경 부담을 줄이는 데 도움이 됩니다.";
            case "화장지류" ->
                    "환경표지 인증 화장지 제품을 선택하면 자원 사용과 환경 부담을 줄이는 데 도움이 됩니다.";
            case "샴푸", "린스", "바디클렌저", "비누" ->
                    "환경표지 인증 세정·위생 제품을 선택하면 일상 소비의 환경 영향을 줄이는 데 도움이 됩니다.";
            case "생분해 빨대", "생분해 봉투", "생분해/다회용 용기" ->
                    "일회용품 사용이 필요한 경우 생분해성 또는 다회용 인증 제품을 선택할 수 있습니다.";
            default ->
                    "환경표지 인증을 받은 제품으로 일반 제품보다 환경성을 고려한 선택입니다.";
        };
    }

    private String makeTip(String subCategory) {
        return switch (subCategory) {
            case "주방세제", "세탁세제", "섬유유연제", "세정제" ->
                    "같은 용도의 제품을 구매할 때 환경표지 인증 여부를 확인해보세요.";
            case "화장지류" ->
                    "휴지나 화장지를 구매할 때 인증 제품을 우선 선택해보세요.";
            case "샴푸", "린스", "바디클렌저", "비누" ->
                    "욕실용품은 리필 제품이나 고체형 제품과 함께 비교해보면 좋습니다.";
            case "생분해 빨대", "생분해 봉투", "생분해/다회용 용기" ->
                    "가능하면 다회용 제품을 먼저 사용하고, 불가피할 때 생분해성 제품을 선택해보세요.";
            default ->
                    "구매 전 인증 정보와 제품 용도를 확인해보세요.";
        };
    }

    private String makeDocId(String certificationNo, String modelName, String companyName) {
        String raw = certificationNo + "|" + modelName + "|" + companyName;
        String uuid = UUID.nameUUIDFromBytes(raw.getBytes(StandardCharsets.UTF_8)).toString();
        return "green_" + uuid;
    }
}