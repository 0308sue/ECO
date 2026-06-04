package com.eco.backend.auth.service;

import com.eco.backend.auth.dto.KakaoLoginResponse;
import com.eco.backend.auth.dto.KakaoUserInfo;
import com.google.firebase.auth.AuthErrorCode;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseAuthException;
import com.google.firebase.auth.UserRecord;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.util.Map;

@Service
public class KakaoAuthService {

    private static final URI KAKAO_USER_INFO_URI =
            URI.create("https://kapi.kakao.com/v2/user/me");

    private final HttpClient httpClient = HttpClient.newHttpClient();
    private final ObjectMapper objectMapper = new ObjectMapper();

    public KakaoLoginResponse login(String accessToken)
            throws IOException, InterruptedException, FirebaseAuthException {
        KakaoUserInfo kakaoUser = requestKakaoUserInfo(accessToken);
        String uid = "kakao_" + kakaoUser.id();

        ensureFirebaseUser(uid, kakaoUser);

        Map<String, Object> claims = Map.of(
                "provider", "kakao",
                "kakaoId", kakaoUser.id()
        );
        String customToken = FirebaseAuth.getInstance()
                .createCustomToken(uid, claims);

        return new KakaoLoginResponse(
                customToken,
                uid,
                kakaoUser.email(),
                kakaoUser.nickname()
        );
    }

    private KakaoUserInfo requestKakaoUserInfo(String accessToken)
            throws IOException, InterruptedException {
        HttpRequest request = HttpRequest.newBuilder(KAKAO_USER_INFO_URI)
                .header("Authorization", "Bearer " + accessToken)
                .GET()
                .build();

        HttpResponse<String> response = httpClient.send(
                request,
                HttpResponse.BodyHandlers.ofString()
        );

        if (response.statusCode() < 200 || response.statusCode() >= 300) {
            throw new IllegalArgumentException("카카오 사용자 정보를 가져오지 못했습니다.");
        }

        JsonNode root = objectMapper.readTree(response.body());
        String id = root.path("id").asText();
        JsonNode kakaoAccount = root.path("kakao_account");
        JsonNode profile = kakaoAccount.path("profile");
        String email = kakaoAccount.path("email").asText(null);
        String nickname = profile.path("nickname").asText("카카오 사용자");

        return new KakaoUserInfo(id, email, nickname);
    }

    private void ensureFirebaseUser(String uid, KakaoUserInfo kakaoUser)
            throws FirebaseAuthException {
        UserRecord.UpdateRequest updateRequest = new UserRecord.UpdateRequest(uid)
                .setDisplayName(kakaoUser.nickname());

        if (kakaoUser.email() != null && !kakaoUser.email().isBlank()) {
            updateRequest.setEmail(kakaoUser.email());
        }

        try {
            FirebaseAuth.getInstance().updateUser(updateRequest);
        } catch (FirebaseAuthException error) {
            if (error.getAuthErrorCode() != AuthErrorCode.USER_NOT_FOUND) {
                throw error;
            }

            UserRecord.CreateRequest createRequest = new UserRecord.CreateRequest()
                    .setUid(uid)
                    .setDisplayName(kakaoUser.nickname());

            if (kakaoUser.email() != null && !kakaoUser.email().isBlank()) {
                createRequest.setEmail(kakaoUser.email());
            }

            FirebaseAuth.getInstance().createUser(createRequest);
        }
    }
}
