package com.eco.backend.item.service;

import com.eco.backend.item.dto.ItemCategoryResponse;
import com.eco.backend.item.rule.ItemCategoryRule;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class ItemCategoryService {

    private final List<ItemCategoryRule> rules = List.of(
            // =========================
            // 음료
            // =========================
            new ItemCategoryRule("음료", "생수", 200, List.of(
                    "생수", "삼다수", "제주삼다수", "아이시스", "백산수", "평창수",
                    "석수", "스파클", "몽베스트", "에비앙", "evian"
            )),
            new ItemCategoryRule("음료", "탄산수", 250, List.of(
                    "탄산수", "트레비", "씨그램", "초정탄산수", "페리에", "산펠레그리노"
            )),
            new ItemCategoryRule("음료", "탄산음료", 350, List.of(
                    "콜라", "코카콜라", "펩시", "펩시제로", "코크제로",
                    "사이다", "칠성사이다", "스프라이트", "나랑드사이다",
                    "환타", "웰치스", "닥터페퍼", "밀키스", "데미소다"
            )),
            new ItemCategoryRule("음료", "이온음료", 300, List.of(
                    "게토레이", "파워에이드", "토레타", "포카리스웨트", "이온음료"
            )),
            new ItemCategoryRule("음료", "에너지음료", 400, List.of(
                    "몬스터", "레드불", "핫식스", "박카스", "비타500", "에너지드링크"
            )),
            new ItemCategoryRule("음료", "커피", 250, List.of(
                    "커피", "아메리카노", "카페라떼", "라떼", "카푸치노", "에스프레소",
                    "바닐라라떼", "카라멜마끼아또", "모카",
                    "레쓰비", "칸타타", "맥심", "티오피", "조지아",
                    "스타벅스", "컴포즈", "메가커피", "빽다방", "이디야"
            )),
            new ItemCategoryRule("음료", "차음료", 220, List.of(
                    "녹차", "홍차", "보리차", "옥수수수염차", "헛개차",
                    "아이스티", "티즐", "블랙보리", "하늘보리", "17차"
            )),
            new ItemCategoryRule("음료", "주스", 300, List.of(
                    "주스", "오렌지주스", "포도주스", "사과주스", "망고주스",
                    "델몬트", "미닛메이드", "썬업", "따옴", "쥬시쿨"
            )),
            new ItemCategoryRule("음료", "유음료", 450, List.of(
                    "초코우유", "딸기우유", "바나나우유", "빙그레바나나", "가공유",
                    "요구르트", "야쿠르트", "요거트음료"
            )),

            // =========================
            // 식품
            // =========================
            new ItemCategoryRule("식품", "라면", 600, List.of(
                    "라면", "신라면", "진라면", "안성탕면", "너구리", "짜파게티",
                    "불닭볶음면", "삼양라면", "열라면", "컵라면", "육개장사발면",
                    "왕뚜껑", "튀김우동", "새우탕", "스낵면", "비빔면"
            )),
            new ItemCategoryRule("식품", "과자", 300, List.of(
                    "과자", "새우깡", "감자깡", "양파링", "포카칩", "스윙칩",
                    "꼬깔콘", "오징어땅콩", "초코파이", "몽쉘", "오예스",
                    "빼빼로", "홈런볼", "칙촉", "칸쵸", "허니버터칩", "프링글스"
            )),
            new ItemCategoryRule("식품", "빵", 350, List.of(
                    "빵", "식빵", "크림빵", "단팥빵", "소보로", "샌드위치",
                    "베이글", "모닝빵", "카스테라", "파운드케이크", "머핀",
                    "도넛", "던킨", "파리바게뜨", "뚜레쥬르"
            )),
            new ItemCategoryRule("식품", "즉석식품", 700, List.of(
                    "김밥", "삼각김밥", "도시락", "햄버거", "핫도그",
                    "즉석밥", "햇반", "오뚜기밥", "컵밥", "죽", "레토르트",
                    "편의점도시락", "볶음밥", "냉동볶음밥", "3분카레", "3분짜장"
            )),
            new ItemCategoryRule("식품", "유제품", 500, List.of(
                    "우유", "서울우유", "매일우유", "남양우유", "연세우유",
                    "요거트", "요구르트", "치즈", "버터", "크림치즈", "플레인요거트"
            )),
            new ItemCategoryRule("식품", "계란육가공", 650, List.of(
                    "계란", "달걀", "구운계란", "훈제란",
                    "햄", "소시지", "비엔나", "베이컨", "스팸", "런천미트"
            )),
            new ItemCategoryRule("식품", "냉동가공식품", 750, List.of(
                    "만두", "냉동만두", "피자", "냉동피자", "치킨", "너겟",
                    "돈까스", "떡볶이", "핫바", "어묵", "냉동식품"
            )),
            new ItemCategoryRule("식품", "통조림", 600, List.of(
                    "참치", "참치캔", "스팸", "통조림", "옥수수콘", "골뱅이캔",
                    "고등어캔", "꽁치캔"
            )),
            new ItemCategoryRule("식품", "조미료소스", 300, List.of(
                    "간장", "고추장", "된장", "쌈장", "케찹", "케첩", "마요네즈",
                    "소스", "드레싱", "참기름", "식용유", "설탕", "소금"
            )),
            new ItemCategoryRule("식품", "아이스크림", 350, List.of(
                    "아이스크림", "월드콘", "메로나", "비비빅", "누가바",
                    "붕어싸만코", "스크류바", "돼지바", "투게더", "하겐다즈"
            )),

            // =========================
            // 생활용품
            // =========================
            new ItemCategoryRule("생활용품", "화장지류", 250, List.of(
                    "물티슈", "휴지", "화장지", "두루마리휴지", "각티슈",
                    "키친타월", "티슈", "냅킨"
            )),
            new ItemCategoryRule("생활용품", "세제류", 450, List.of(
                    "세제", "주방세제", "세탁세제", "액체세제", "분말세제",
                    "섬유유연제", "리필세제", "퍼실", "비트", "테크", "다우니",
                    "피죤", "퐁퐁", "트리오"
            )),
            new ItemCategoryRule("생활용품", "욕실용품", 350, List.of(
                    "샴푸", "린스", "트리트먼트", "바디워시", "바디클렌저",
                    "비누", "폼클렌징", "클렌징폼", "핸드워시", "엘라스틴",
                    "려샴푸", "도브", "해피바스"
            )),
            new ItemCategoryRule("생활용품", "구강용품", 300, List.of(
                    "칫솔", "치약", "가글", "구강청결제", "치실", "리스테린",
                    "페리오", "2080", "2080치약", "메디안"
            )),
            new ItemCategoryRule("생활용품", "위생용품", 300, List.of(
                    "마스크", "손소독제", "소독티슈", "생리대", "팬티라이너",
                    "면도기", "면도날", "밴드", "상처밴드"
            )),
            new ItemCategoryRule("생활용품", "청소용품", 300, List.of(
                    "수세미", "고무장갑", "청소포", "물걸레청소포", "행주",
                    "탈취제", "방향제", "락스", "곰팡이제거제", "배수구클리너"
            )),
            new ItemCategoryRule("생활용품", "보관용품", 400, List.of(
                    "보관용기", "밀폐용기", "락앤락", "반찬통", "도시락통",
                    "텀블러", "물병", "보틀"
            )),

            // =========================
            // 일회용품
            // =========================
            new ItemCategoryRule("일회용품", "일회용컵", 500, List.of(
                    "종이컵", "플라스틱컵", "일회용컵", "테이크아웃컵", "컵뚜껑",
                    "컵홀더"
            )),
            new ItemCategoryRule("일회용품", "비닐류", 400, List.of(
                    "비닐봉지", "봉투", "쇼핑봉투", "위생백", "지퍼백",
                    "크린백", "롤백"
            )),
            new ItemCategoryRule("일회용품", "일회용식기", 550, List.of(
                    "나무젓가락", "일회용젓가락", "일회용숟가락", "일회용포크",
                    "일회용나이프", "일회용접시", "종이접시", "플라스틱접시",
                    "일회용그릇"
            )),
            new ItemCategoryRule("일회용품", "포장재", 450, List.of(
                    "랩", "호일", "알루미늄호일", "배달용기", "일회용용기",
                    "포장용기", "빨대", "일회용빨대", "스트로우"
            )),

            // =========================
            // 전자제품
            // =========================
            new ItemCategoryRule("전자제품", "충전기케이블", 1500, List.of(
                    "충전기", "고속충전기", "케이블", "충전케이블", "usb케이블",
                    "c타입케이블", "라이트닝케이블", "어댑터", "충전어댑터"
            )),
            new ItemCategoryRule("전자제품", "음향기기", 2000, List.of(
                    "이어폰", "무선이어폰", "헤드셋", "헤드폰", "블루투스이어폰",
                    "스피커", "블루투스스피커"
            )),
            new ItemCategoryRule("전자제품", "컴퓨터주변기기", 2500, List.of(
                    "마우스", "키보드", "무선마우스", "무선키보드", "마우스패드",
                    "usb허브", "웹캠"
            )),
            new ItemCategoryRule("전자제품", "배터리", 1200, List.of(
                    "건전지", "배터리", "보조배터리", "알카라인", "에너자이저",
                    "듀라셀"
            )),
            new ItemCategoryRule("전자제품", "전기용품", 1000, List.of(
                    "멀티탭", "전구", "led전구", "형광등", "휴대폰거치대",
                    "스마트폰거치대", "차량용충전기"
            )),

            // =========================
            // 의류
            // =========================
            new ItemCategoryRule("의류", "상의", 2500, List.of(
                    "티셔츠", "반팔", "긴팔", "셔츠", "블라우스", "맨투맨",
                    "후드티", "니트", "스웨터", "나시", "민소매"
            )),
            new ItemCategoryRule("의류", "하의", 7000, List.of(
                    "바지", "청바지", "진", "데님", "슬랙스", "반바지",
                    "조거팬츠", "레깅스", "치마", "스커트"
            )),
            new ItemCategoryRule("의류", "속옷양말", 1000, List.of(
                    "양말", "덧신", "속옷", "팬티", "브라", "런닝", "내의",
                    "히트텍"
            )),
            new ItemCategoryRule("의류", "신발", 6000, List.of(
                    "신발", "운동화", "스니커즈", "슬리퍼", "샌들", "구두",
                    "부츠", "크록스"
            )),
            new ItemCategoryRule("의류", "외투", 8000, List.of(
                    "자켓", "재킷", "패딩", "코트", "점퍼", "야상", "가디건",
                    "후리스"
            )),
            new ItemCategoryRule("의류", "잡화", 1500, List.of(
                    "모자", "캡모자", "비니", "장갑", "목도리", "스카프",
                    "잠옷", "파자마", "우산"
            ))
    );

    public ItemCategoryResponse classify(String itemName) {
        validateItemName(itemName);

        String normalizedName = normalize(itemName);
        MatchResult bestMatch = null;

        for (ItemCategoryRule rule : rules) {
            for (String keyword : rule.getKeywords()) {
                String normalizedKeyword = normalize(keyword);

                if (normalizedKeyword.isBlank()) {
                    continue;
                }

                if (normalizedName.contains(normalizedKeyword)) {
                    MatchResult currentMatch = new MatchResult(
                            rule.getCategory(),
                            rule.getSubCategory(),
                            keyword,
                            rule.getEstimatedCarbonGram()
                    );

                    if (isBetterMatch(currentMatch, bestMatch)) {
                        bestMatch = currentMatch;
                    }
                }
            }
        }

        if (bestMatch != null) {
            int adjustedCarbonGram = adjustCarbonGram(
                    bestMatch.estimatedCarbonGram(),
                    normalizedName
            );
            int carbonScore = calculateCarbonScore(adjustedCarbonGram);

            return new ItemCategoryResponse(
                    itemName,
                    normalizedName,
                    bestMatch.category(),
                    bestMatch.subCategory(),
                    bestMatch.keyword(),
                    adjustedCarbonGram,
                    toKg(adjustedCarbonGram),
                    carbonScore
            );
        }

        int defaultCarbonGram = 100;

        return new ItemCategoryResponse(
                itemName,
                normalizedName,
                "기타",
                "기타",
                null,
                defaultCarbonGram,
                toKg(defaultCarbonGram),
                calculateCarbonScore(defaultCarbonGram)
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

    private boolean isBetterMatch(MatchResult currentMatch, MatchResult bestMatch) {
        if (bestMatch == null) {
            return true;
        }

        return currentMatch.keyword().length() > bestMatch.keyword().length();
    }

    private int adjustCarbonGram(int baseCarbonGram, String normalizedName) {
        int adjustment = 0;

        if (containsAny(normalizedName, List.of(
                "일회용", "플라스틱", "비닐", "배달용기", "테이크아웃컵",
                "종이컵", "빨대", "스트로우", "랩", "호일"
        ))) {
            adjustment += 100;
        }

        if (containsAny(normalizedName, List.of(
                "리필", "리필용", "대용량", "절약형"
        ))) {
            adjustment -= 100;
        }

        return Math.max(baseCarbonGram + adjustment, 50);
    }

    private int calculateCarbonScore(int carbonGram) {
        if (carbonGram <= 200) {
            return 1;
        }

        if (carbonGram <= 500) {
            return 2;
        }

        if (carbonGram <= 1000) {
            return 3;
        }

        if (carbonGram <= 3000) {
            return 4;
        }

        return 5;
    }

    private boolean containsAny(String text, List<String> keywords) {
        for (String keyword : keywords) {
            String normalizedKeyword = normalize(keyword);

            if (normalizedKeyword.isBlank()) {
                continue;
            }

            if (text.contains(normalizedKeyword)) {
                return true;
            }
        }

        return false;
    }

    private double toKg(int gram) {
        return gram / 1000.0;
    }

    private void validateItemName(String itemName) {
        if (itemName == null || itemName.trim().isEmpty()) {
            throw new IllegalArgumentException("품목명은 비어 있을 수 없습니다.");
        }
    }

    private String normalize(String itemName) {
        return itemName
                .trim()
                .toLowerCase()
                .replaceAll("\\s+", "")

                // 용량/중량 단위 제거: 500ml, 1.5l, 100g, 2kg 등
                .replaceAll("[0-9]+(\\.[0-9]+)?(ml|l|g|kg)", "")

                // 행사 표기 제거: 1+1, 2+1
                .replaceAll("[0-9]+\\+[0-9]+", "")

                // 수량 단위 제거: 5입, 10개, 3팩, 2병 등
                .replaceAll("[0-9]+(개|입|팩|병|봉|매)", "")

                // 단독 단위 제거
                .replaceAll("개|입|팩|병|봉|매", "")

                // 한글, 영어, 숫자는 유지
                .replaceAll("[^가-힣a-zA-Z0-9]", "");
    }

    private record MatchResult(
            String category,
            String subCategory,
            String keyword,
            int estimatedCarbonGram
    ) {
    }
}