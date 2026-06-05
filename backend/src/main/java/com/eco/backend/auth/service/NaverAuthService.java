package com.eco.backend.auth.service;

import com.eco.backend.auth.dto.KakaoLoginResponse;
import com.eco.backend.auth.dto.NaverUserInfo;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.google.firebase.auth.AuthErrorCode;
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
public class NaverAuthService {

    private static final URI NAVER_USER_INFO_URI =
            URI.create("https://openapi.naver.com/v1/nid/me");

    private final HttpClient httpClient = HttpClient.newHttpClient();
    private final ObjectMapper objectMapper = new ObjectMapper();

    public KakaoLoginResponse login(String accessToken)
            throws IOException, InterruptedException, FirebaseAuthException {
        NaverUserInfo naverUser = requestNaverUserInfo(accessToken);
        String uid = "naver_" + naverUser.id();

        ensureFirebaseUser(uid, naverUser);

        Map<String, Object> claims = Map.of(
                "provider", "naver",
                "naverId", naverUser.id()
        );
        String customToken = FirebaseAuth.getInstance()
                .createCustomToken(uid, claims);

        return new KakaoLoginResponse(
                customToken,
                uid,
                naverUser.email(),
                naverUser.nickname()
        );
    }

    private NaverUserInfo requestNaverUserInfo(String accessToken)
            throws IOException, InterruptedException {
        HttpRequest request = HttpRequest.newBuilder(NAVER_USER_INFO_URI)
                .header("Authorization", "Bearer " + accessToken)
                .GET()
                .build();

        HttpResponse<String> response = httpClient.send(
                request,
                HttpResponse.BodyHandlers.ofString()
        );

        if (response.statusCode() < 200 || response.statusCode() >= 300) {
            throw new IllegalArgumentException("네이버 사용자 정보를 가져오지 못했습니다.");
        }

        JsonNode root = objectMapper.readTree(response.body());
        if (!"00".equals(root.path("resultcode").asText())) {
            throw new IllegalArgumentException("네이버 로그인 응답이 올바르지 않습니다.");
        }

        JsonNode profile = root.path("response");
        String id = profile.path("id").asText();
        String email = profile.path("email").asText(null);
        String nickname = profile.path("nickname").asText("네이버 사용자");

        return new NaverUserInfo(id, email, nickname);
    }

    private void ensureFirebaseUser(String uid, NaverUserInfo naverUser)
            throws FirebaseAuthException {
        UserRecord.UpdateRequest updateRequest = new UserRecord.UpdateRequest(uid)
                .setDisplayName(naverUser.nickname());

        if (naverUser.email() != null && !naverUser.email().isBlank()) {
            updateRequest.setEmail(naverUser.email());
        }

        try {
            FirebaseAuth.getInstance().updateUser(updateRequest);
        } catch (FirebaseAuthException error) {
            if (error.getAuthErrorCode() != AuthErrorCode.USER_NOT_FOUND) {
                throw error;
            }

            UserRecord.CreateRequest createRequest = new UserRecord.CreateRequest()
                    .setUid(uid)
                    .setDisplayName(naverUser.nickname());

            if (naverUser.email() != null && !naverUser.email().isBlank()) {
                createRequest.setEmail(naverUser.email());
            }

            FirebaseAuth.getInstance().createUser(createRequest);
        }
    }
}
