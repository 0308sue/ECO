package com.eco.backend.auth.controller;

import com.eco.backend.auth.dto.KakaoLoginRequest;
import com.eco.backend.auth.dto.KakaoLoginResponse;
import com.eco.backend.auth.dto.NaverLoginRequest;
import com.eco.backend.auth.service.KakaoAuthService;
import com.eco.backend.auth.service.NaverAuthService;
import com.google.firebase.auth.FirebaseAuthException;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.io.IOException;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final KakaoAuthService kakaoAuthService;
    private final NaverAuthService naverAuthService;

    public AuthController(
            KakaoAuthService kakaoAuthService,
            NaverAuthService naverAuthService
    ) {
        this.kakaoAuthService = kakaoAuthService;
        this.naverAuthService = naverAuthService;
    }

    @PostMapping("/kakao")
    public ResponseEntity<KakaoLoginResponse> loginWithKakao(
            @RequestBody KakaoLoginRequest request
    ) throws IOException, InterruptedException, FirebaseAuthException {
        return ResponseEntity.ok(kakaoAuthService.login(request.accessToken()));
    }

    @PostMapping("/naver")
    public ResponseEntity<KakaoLoginResponse> loginWithNaver(
            @RequestBody NaverLoginRequest request
    ) throws IOException, InterruptedException, FirebaseAuthException {
        return ResponseEntity.ok(naverAuthService.login(request.accessToken()));
    }
}
