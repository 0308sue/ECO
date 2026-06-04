package com.eco.backend.auth.dto;

public record KakaoLoginResponse(
        String customToken,
        String uid,
        String email,
        String nickname
) {
}
