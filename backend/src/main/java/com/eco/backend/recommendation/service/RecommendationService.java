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

    private final EcoRecommendationRepository ecoRecommendationRepository;

    public RecommendationService(EcoRecommendationRepository ecoRecommendationRepository) {
        this.ecoRecommendationRepository = ecoRecommendationRepository;
    }

    private final List<RecommendationRule> rules = List.of(
            new RecommendationRule(
                    "음료",
                    null,
                    List.of("펩시제로", "콜라", "사이다", "생수", "음료"),
                    "텀블러",
                    "제로웨이스트샵",
                    "음료 소비가 있어 일회용 컵과 플라스틱병 사용을 줄일 수 있는 텀블러를 추천합니다."
            ),
            new RecommendationRule(
                    "생활용품",
                    "화장지류",
                    List.of("물티슈"),
                    "손수건",
                    "제로웨이스트샵",
                    "물티슈 대신 손수건이나 다회용 행주 사용을 추천합니다."
            ),
            new RecommendationRule(
                    "일회용품",
                    "일회용컵",
                    List.of("종이컵", "일회용컵", "플라스틱컵"),
                    "텀블러",
                    "제로웨이스트샵",
                    "일회용 컵 대신 텀블러 사용을 추천합니다."
            ),
            new RecommendationRule(
                    "생활용품",
                    null,
                    List.of("샴푸", "린스"),
                    "샴푸바",
                    "제로웨이스트샵",
                    "샴푸바는 플라스틱 용기 사용을 줄일 수 있는 대체 생활용품입니다."
            ),
            new RecommendationRule(
                    "생활용품",
                    null,
                    List.of("세제", "세탁세제", "퍼실", "비트", "섬유유연제"),
                    "세제 리필",
                    "리필스테이션",
                    "세제 리필을 이용하면 새 플라스틱 용기 구매를 줄일 수 있습니다."
            ),
            new RecommendationRule(
                    null,
                    null,
                    List.of("건전지", "배터리"),
                    "충전지",
                    "폐건전지수거함",
                    "충전지를 사용하면 반복 구매와 폐기물 발생을 줄일 수 있습니다."
            )
    );

    public List<RecommendedItemResponse> recommendItems(RecommendationRequest request) {
        List<RecommendedItemResponse> responses = new ArrayList<>();

        if (request.items() == null || request.items().isEmpty()) {
            return responses;
        }

        for (ReceiptItem receiptItem : request.items()) {
            String matchName = getMatchName(receiptItem);
            String category = receiptItem.category();
            String subCategory = receiptItem.subCategory();

            for (RecommendationRule rule : rules) {
                if (rule.matches(matchName, category, subCategory)) {
                    addRecommendedItemFromDb(responses, receiptItem, matchName, rule);
                    break;
                }
            }
        }

        return responses;
    }

    public List<RecommendedPlaceResponse> recommendPlaces(RecommendationRequest request) {
        List<RecommendedPlaceResponse> responses = new ArrayList<>();

        if (request.items() == null || request.items().isEmpty()) {
            return responses;
        }

        List<String> requiredPlaceTypes = new ArrayList<>();

        for (ReceiptItem receiptItem : request.items()) {
            String matchName = getMatchName(receiptItem);
            String category = receiptItem.category();
            String subCategory = receiptItem.subCategory();

            for (RecommendationRule rule : rules) {
                if (rule.matches(matchName, category, subCategory)) {
                    if (!requiredPlaceTypes.contains(rule.placeType())) {
                        requiredPlaceTypes.add(rule.placeType());
                    }
                    break;
                }
            }
        }

        for (String placeType : requiredPlaceTypes) {
            try {
                List<EcoPlace> places = ecoRecommendationRepository.findActivePlacesByType(placeType);

                for (EcoPlace place : places) {
                    responses.add(new RecommendedPlaceResponse(
                            place.getName(),
                            place.getType(),
                            place.getAddress(),
                            place.getLat(),
                            place.getLng(),
                            place.getDescription()
                    ));
                }
            } catch (Exception e) {
                throw new RuntimeException("추천 장소 조회 중 오류가 발생했습니다.", e);
            }
        }

        return responses;
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


            for (EcoItem ecoItem : ecoItems) {
                responses.add(new RecommendedItemResponse(
                        receiptItem.originalName(),
                        matchName,
                        ecoItem.getName(),
                        ecoItem.getReason()
                ));
            }
        } catch (Exception e) {
        throw new RuntimeException("추천 아이템 조회 중 오류가 발생했습니다.", e);
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