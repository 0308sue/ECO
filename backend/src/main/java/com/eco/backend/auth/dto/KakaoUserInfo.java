package com.eco.backend.auth.dto;

public record KakaoUserInfo(
        String id,
        String email,
        String nickname
) {
}
