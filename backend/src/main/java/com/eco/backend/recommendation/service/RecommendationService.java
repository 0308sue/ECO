package com.eco.backend.recommendation.service;

import com.eco.backend.recommendation.dto.RecommendationRequest;
import com.eco.backend.recommendation.dto.RecommendedItemResponse;
import com.eco.backend.recommendation.dto.RecommendedPlaceResponse;
import com.eco.backend.recommendation.dto.ReceiptItem;
import com.eco.backend.recommendation.rule.RecommendationRule;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

@Service
public class RecommendationService {

    // 현재는 DB 없이 코드 안에서 추천 규칙을 관리함
    // 나중에 Firebase/DB를 붙이면 eco_items, eco_places만 DB에서 조회하는 방향으로 확장
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

        for (ReceiptItem item : request.items()) {
            String matchName = getMatchName(item);
            String category = item.category();
            String subCategory = item.subCategory();

            for (RecommendationRule rule : rules) {
                if (rule.matches(matchName, category, subCategory)) {
                    responses.add(new RecommendedItemResponse(
                            item.originalName(),
                            matchName,
                            rule.recommendedItem(),
                            rule.reason()
                    ));

                    // 한 품목에 대해 첫 번째로 매칭된 추천만 반환
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

        boolean needZeroWasteShop = false;
        boolean needRefillStation = false;
        boolean needBatteryBox = false;

        for (ReceiptItem item : request.items()) {
            String matchName = getMatchName(item);
            String category = item.category();
            String subCategory = item.subCategory();

            for (RecommendationRule rule : rules) {
                if (rule.matches(matchName, category, subCategory)) {
                    switch (rule.placeType()) {
                        case "제로웨이스트샵" -> needZeroWasteShop = true;
                        case "리필스테이션" -> needRefillStation = true;
                        case "폐건전지수거함" -> needBatteryBox = true;
                        default -> {
                            // 아직 장소 추천 규칙이 없는 경우 제외
                        }
                    }
                }
            }
        }

        if (needZeroWasteShop) {
            responses.add(new RecommendedPlaceResponse(
                    "예시 제로웨이스트샵",
                    "제로웨이스트샵",
                    "부산광역시 부산진구",
                    35.157,
                    129.059,
                    "친환경 생활용품과 대체 아이템을 구매할 수 있습니다."
            ));
        }

        if (needRefillStation) {
            responses.add(new RecommendedPlaceResponse(
                    "예시 리필스테이션",
                    "리필스테이션",
                    "부산광역시 부산진구",
                    35.158,
                    129.061,
                    "세탁세제 리필이 가능한 장소입니다."
            ));
        }

        if (needBatteryBox) {
            responses.add(new RecommendedPlaceResponse(
                    "예시 폐건전지 수거함",
                    "폐건전지수거함",
                    "부산광역시 부산진구",
                    35.156,
                    129.058,
                    "건전지는 일반쓰레기가 아닌 전용 수거함에 배출하는 것이 좋습니다."
            ));
        }

        return responses;
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