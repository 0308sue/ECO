package com.eco.backend.auth.dto;

public record NaverUserInfo(
        String id,
        String email,
        String nickname
) {
}
