package com.eco.backend.recommendation.service;

import com.eco.backend.recommendation.domain.EcoItem;
import com.eco.backend.recommendation.domain.EcoPlace;
import com.eco.backend.recommendation.dto.RecommendationRequest;
import com.eco.backend.recommendation.dto.RecommendedItemResponse;
import com.eco.backend.recommendation.dto.RecommendedPlaceResponse;
import com.eco.backend.recommendation.dto.ReceiptItem;
import com.eco.backend.recommendation.repository.EcoRecommendationRepository;
import com.eco.backend.recommendation.rule.RecommendationRule;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

@Service
public class RecommendationService {

    private static final String DEFAULT_PLACE_TYPE = "제로웨이스트샵";

    private final EcoRecommendationRepository ecoRecommendationRepository;

    public RecommendationService(EcoRecommendationRepository ecoRecommendationRepository) {
        this.ecoRecommendationRepository = ecoRecommendationRepository;
    }

    private final List<RecommendationRule> rules = List.of(
            // 음료 전체
            new RecommendationRule(
                    "음료",
                    null,
                    List.of("펩시제로", "콜라", "사이다", "생수", "음료", "물", "탄산", "주스"),
                    "텀블러",
                    "제로웨이스트샵",
                    "음료 소비가 있어 일회용 컵과 플라스틱병 사용을 줄일 수 있는 텀블러를 추천합니다."
            ),

            // 커피 전용
            new RecommendationRule(
                    "음료",
                    "커피",
                    List.of("커피", "아메리카노", "라떼", "카페라떼", "카푸치노", "에스프레소", "카페", "ice", "hot"),
                    "텀블러",
                    "제로웨이스트샵",
                    "커피 소비가 있어 일회용 컵 대신 텀블러나 개인컵 사용을 추천합니다."
            ),

            // 식품/음식 전체
            new RecommendationRule(
                    "식품",
                    null,
                    List.of("햄버거", "버거", "치킨", "피자", "김밥", "라면", "도시락", "샌드위치", "빵", "과자", "음식", "식품"),
                    "다회용기",
                    "제로웨이스트샵",
                    "음식 구매 시 일회용 포장재를 줄일 수 있도록 다회용기 사용을 추천합니다."
            ),

            // 패스트푸드/포장 음식
            new RecommendationRule(
                    "식품",
                    "패스트푸드",
                    List.of("햄버거", "버거", "치킨", "피자", "감자튀김", "세트"),
                    "다회용기",
                    "제로웨이스트샵",
                    "패스트푸드나 포장 음식은 일회용 포장재가 많이 발생할 수 있어 다회용기 사용을 추천합니다."
            ),

            // 일회용품
            new RecommendationRule(
                    "일회용품",
                    "일회용컵",
                    List.of("종이컵", "일회용컵", "플라스틱컵", "컵", "빨대", "나무젓가락", "일회용수저", "일회용"),
                    "텀블러",
                    "제로웨이스트샵",
                    "일회용 컵이나 일회용품 대신 텀블러와 다회용품 사용을 추천합니다."
            ),

            // 물티슈
            new RecommendationRule(
                    "생활용품",
                    "화장지류",
                    List.of("물티슈", "티슈", "휴지", "키친타월"),
                    "손수건",
                    "제로웨이스트샵",
                    "물티슈 대신 손수건이나 다회용 행주 사용을 추천합니다."
            ),

            // 생활용품 - 샴푸/린스
            new RecommendationRule(
                    "생활용품",
                    null,
                    List.of("샴푸", "린스", "바디워시", "클렌징폼", "비누"),
                    "샴푸바",
                    "제로웨이스트샵",
                    "샴푸바는 플라스틱 용기 사용을 줄일 수 있는 대체 생활용품입니다."
            ),

            // 생활용품 - 세제
            new RecommendationRule(
                    "생활용품",
                    null,
                    List.of("세제", "세탁세제", "퍼실", "비트", "섬유유연제", "주방세제"),
                    "세제 리필",
                    "리필스테이션",
                    "세제 리필을 이용하면 새 플라스틱 용기 구매를 줄일 수 있습니다."
            ),

            // 장보기/봉투
            new RecommendationRule(
                    null,
                    null,
                    List.of("봉투", "비닐봉투", "쇼핑백", "마트", "장보기"),
                    "장바구니",
                    "제로웨이스트샵",
                    "비닐봉투 사용을 줄이기 위해 장바구니 사용을 추천합니다."
            ),

            // 전자/배터리
            new RecommendationRule(
                    null,
                    null,
                    List.of("건전지", "배터리", "충전기", "케이블", "이어폰"),
                    "충전지",
                    "폐건전지수거함",
                    "충전지나 재사용 가능한 전자제품을 사용하면 반복 구매와 폐기물 발생을 줄일 수 있습니다."
            ),

            // 기타 fallback용
            new RecommendationRule(
                    "기타",
                    null,
                    List.of("기타"),
                    "장바구니",
                    "제로웨이스트샵",
                    "분류가 어려운 소비라도 장바구니, 텀블러, 다회용기 사용으로 일회용품 사용을 줄일 수 있습니다."
            )
    );

    public List<RecommendedItemResponse> recommendItems(RecommendationRequest request) {
        List<RecommendedItemResponse> responses = new ArrayList<>();

        if (request.items() == null || request.items().isEmpty()) {
            addDefaultRecommendedItem(responses);
            return responses;
        }

        for (ReceiptItem receiptItem : request.items()) {
            String matchName = getMatchName(receiptItem);
            String category = receiptItem.category();
            String subCategory = receiptItem.subCategory();

            RecommendationRule matchedRule = findMatchedRule(matchName, category, subCategory);

            if (matchedRule != null) {
                addRecommendedItemFromDb(responses, receiptItem, matchName, matchedRule);
            }
        }

        // 어떤 품목도 rule에 걸리지 않아도 빈 배열 방지
        if (responses.isEmpty()) {
            addDefaultRecommendedItem(responses);
        }

        return responses;
    }

    public List<RecommendedPlaceResponse> recommendPlaces(RecommendationRequest request) {
        List<RecommendedPlaceResponse> responses = new ArrayList<>();

        List<String> requiredPlaceTypes = new ArrayList<>();

        if (request.items() != null && !request.items().isEmpty()) {
            for (ReceiptItem receiptItem : request.items()) {
                String matchName = getMatchName(receiptItem);
                String category = receiptItem.category();
                String subCategory = receiptItem.subCategory();

                RecommendationRule matchedRule = findMatchedRule(matchName, category, subCategory);

                if (matchedRule != null && !requiredPlaceTypes.contains(matchedRule.placeType())) {
                    requiredPlaceTypes.add(matchedRule.placeType());
                }
            }
        }

        // 장소도 빈 배열 방지
        if (requiredPlaceTypes.isEmpty()) {
            requiredPlaceTypes.add(DEFAULT_PLACE_TYPE);
        }

        for (String placeType : requiredPlaceTypes) {
            addRecommendedPlacesFromDb(responses, placeType);
        }

        return responses;
    }

    private RecommendationRule findMatchedRule(String matchName, String category, String subCategory) {
        for (RecommendationRule rule : rules) {
            if (rule.matches(matchName, category, subCategory)) {
                return rule;
            }
        }

        // category/subCategory가 없거나 기타인 경우 기본 rule
        for (RecommendationRule rule : rules) {
            if ("기타".equals(rule.category())) {
                return rule;
            }
        }

        return null;
    }

    private void addRecommendedItemFromDb(
            List<RecommendedItemResponse> responses,
            ReceiptItem receiptItem,
            String matchName,
            RecommendationRule rule
    ) {
        try {
            List<EcoItem> ecoItems =
                    ecoRecommendationRepository.findActiveEcoItemsByName(rule.recommendedItem());

            // DB에 실제 제품 후보가 없어도 rule 기반 추천은 반환
            if (ecoItems == null || ecoItems.isEmpty()) {
                responses.add(new RecommendedItemResponse(
                        receiptItem.originalName(),
                        matchName,
                        rule.recommendedItem(),
                        rule.reason(),
                        null,
                        null,
                        null
                ));
                return;
            }

            ecoItems.stream()
                    .limit(3)
                    .forEach(ecoItem -> responses.add(new RecommendedItemResponse(
                            receiptItem.originalName(),
                            matchName,
                            ecoItem.getName(),
                            ecoItem.getReason() != null && !ecoItem.getReason().isBlank()
                                    ? ecoItem.getReason()
                                    : rule.reason(),
                            ecoItem.getCompanyName(),
                            ecoItem.getCertificationNo(),
                            ecoItem.getSourceName()
                    )));
        } catch (Exception e) {
            throw new RuntimeException("추천 아이템 조회 중 오류가 발생했습니다.", e);
        }
    }

    private void addDefaultRecommendedItem(List<RecommendedItemResponse> responses) {
        try {
            String defaultItemName = "장바구니";

            List<EcoItem> ecoItems =
                    ecoRecommendationRepository.findActiveEcoItemsByName(defaultItemName);

            if (ecoItems == null || ecoItems.isEmpty()) {
                responses.add(new RecommendedItemResponse(
                        "기타 소비",
                        "기타",
                        defaultItemName,
                        "분류가 어려운 소비라도 장바구니, 텀블러, 다회용기 사용으로 일회용품 사용을 줄일 수 있습니다.",
                        null,
                        null,
                        null
                ));
                return;
            }

            ecoItems.stream()
                    .limit(3)
                    .forEach(ecoItem -> responses.add(new RecommendedItemResponse(
                            "기타 소비",
                            "기타",
                            ecoItem.getName(),
                            ecoItem.getReason() != null && !ecoItem.getReason().isBlank()
                                    ? ecoItem.getReason()
                                    : "분류가 어려운 소비라도 장바구니, 텀블러, 다회용기 사용으로 일회용품 사용을 줄일 수 있습니다.",
                            ecoItem.getCompanyName(),
                            ecoItem.getCertificationNo(),
                            ecoItem.getSourceName()
                    )));
        } catch (Exception e) {
            throw new RuntimeException("기본 추천 아이템 조회 중 오류가 발생했습니다.", e);
        }
    }

    private void addRecommendedPlacesFromDb(
            List<RecommendedPlaceResponse> responses,
            String placeType
    ) {
        try {
            List<EcoPlace> places = ecoRecommendationRepository.findActivePlacesByType(placeType);

            places.stream()
                    .limit(5)
                    .forEach(place -> responses.add(new RecommendedPlaceResponse(
                            place.getName(),
                            place.getType(),
                            place.getAddress(),
                            place.getLat(),
                            place.getLng(),
                            place.getDescription()
                    )));
        } catch (Exception e) {
            throw new RuntimeException("추천 장소 조회 중 오류가 발생했습니다.", e);
        }
    }

    private String getMatchName(ReceiptItem item) {
        if (item.normalizedName() != null && !item.normalizedName().isBlank()) {
            return item.normalizedName();
        }

        if (item.matchedKeyword() != null && !item.matchedKeyword().isBlank()) {
            return item.matchedKeyword();
        }

        if (item.originalName() != null && !item.originalName().isBlank()) {
            return item.originalName();
        }

        return "";
    }
}