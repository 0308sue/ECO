package com.eco.backend.item.service;

import com.eco.backend.item.dto.ItemCategoryResponse;
import com.eco.backend.item.rule.ItemCategoryRule;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class ItemCategoryService {

    private final List<ItemCategoryRule> rules = List.of(
        new ItemCategoryRule("음료", List.of(
                "생수", "삼다수", "아이시스", "백산수", "평창수",
                "탄산수", "트레비", "씨그램",
                "콜라", "코카콜라", "펩시",
                "사이다", "칠성사이다", "스프라이트",
                "주스", "오렌지주스", "포도주스", "델몬트", "미닛메이드",
                "커피", "레쓰비", "칸타타", "맥심", "티오피",
                "환타", "웰치스", "게토레이", "파워에이드", "토레타",
                "몬스터", "레드불", "핫식스"
        )),

        new ItemCategoryRule("식품", List.of(
                "라면", "신라면", "진라면", "너구리", "짜파게티", "불닭볶음면",
                "과자", "새우깡", "포카칩", "꼬깔콘", "초코파이", "몽쉘", "빼빼로",
                "빵", "식빵", "크림빵", "단팥빵", "샌드위치",
                "김밥", "삼각김밥", "도시락", "햄버거", "핫도그",
                "우유", "서울우유", "매일우유", "요거트", "요구르트",
                "계란", "달걀", "햄", "치즈", "소시지",
                "참치", "스팸", "즉석밥", "햇반", "컵밥",
                "만두", "냉동만두", "피자", "치킨", "떡볶이"
        )),

        new ItemCategoryRule("생활용품", List.of(
                "물티슈", "휴지", "화장지", "키친타월",
                "세제", "주방세제", "세탁세제", "섬유유연제",
                "샴푸", "린스", "트리트먼트", "바디워시", "비누",
                "칫솔", "치약", "가글", "면도기",
                "수건", "행주", "수세미", "고무장갑",
                "청소포", "탈취제", "방향제",
                "건전지", "마스크", "손소독제"
        )),

        new ItemCategoryRule("일회용품", List.of(
                "종이컵", "플라스틱컵", "일회용컵",
                "빨대", "일회용빨대",
                "비닐봉지", "봉투", "쇼핑백",
                "나무젓가락", "일회용젓가락", "일회용숟가락", "일회용포크",
                "일회용접시", "종이접시", "플라스틱접시",
                "랩", "호일", "지퍼백", "위생백",
                "테이크아웃컵", "배달용기", "일회용용기"
        )),

        new ItemCategoryRule("전자제품", List.of(
                "충전기", "고속충전기", "케이블", "충전케이블", "usb케이블",
                "이어폰", "헤드셋", "마우스", "키보드",
                "보조배터리", "멀티탭", "어댑터",
                "건전지", "배터리", "전구", "led전구",
                "휴대폰거치대", "스마트폰거치대"
        )),

        new ItemCategoryRule("의류", List.of(
                "티셔츠", "반팔", "긴팔", "셔츠", "맨투맨", "후드티",
                "바지", "청바지", "슬랙스", "반바지",
                "양말", "속옷", "팬티", "브라",
                "모자", "신발", "운동화", "슬리퍼",
                "장갑", "목도리", "잠옷", "자켓", "패딩", "코트"
        ))
);

    public ItemCategoryResponse classify(String itemName) {
        validateItemName(itemName);

        String normalizedName = normalize(itemName);

        MatchResult bestMatch = null;

        for (ItemCategoryRule rule : rules) {
            for (String keyword : rule.getKeywords()) {
                if (normalizedName.contains(keyword)) {
                    if (bestMatch == null || keyword.length() > bestMatch.keyword().length()) {
                        bestMatch = new MatchResult(rule.getCategory(), keyword);
                    }
                }
            }
        }

        if (bestMatch != null) {
            int carbonScore = calculateCarbonScore(bestMatch.category());

            return new ItemCategoryResponse(
                    itemName,
                    normalizedName,
                    bestMatch.category(),
                    bestMatch.keyword(),
                    carbonScore
            );
        }

        int carbonScore = calculateCarbonScore("기타");

        return new ItemCategoryResponse(
                itemName,
                normalizedName,
                "기타",
                null,
                carbonScore
        );
    }

    public List<ItemCategoryResponse> classifyAll(List<String> itemNames) {
        if (itemNames == null || itemNames.isEmpty()) {
            throw new IllegalArgumentException("품목 목록은 비어 있을 수 없습니다.");
        }

        return itemNames.stream()
                .map(this::classify)
                .toList();
    }

    private void validateItemName(String itemName) {
        if (itemName == null || itemName.trim().isEmpty()) {
            throw new IllegalArgumentException("품목명은 비어 있을 수 없습니다.");
        }
    }

    private String normalize(String itemName) {
        return itemName
                .trim()
                .replaceAll("\\s+", "")
                .replaceAll("[0-9]+", "")
                .replaceAll("ml|ML|l|L|g|G|kg|KG|개|입|팩|병|봉|매", "")
                .replaceAll("[^가-힣a-zA-Z]", "")
                .toLowerCase();
    }

    private int calculateCarbonScore(String category) {
        return switch (category) {
            case "생활용품" -> 2;
            case "음료" -> 3;
            case "식품" -> 4;
            case "의류" -> 4;
            case "일회용품" -> 5;
            case "전자제품" -> 5;
            default -> 1;
        };
    }

    private record MatchResult(String category, String keyword) {
    }
}