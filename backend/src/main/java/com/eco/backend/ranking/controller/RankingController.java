package com.eco.backend.ranking.controller;

import com.eco.backend.ranking.dto.RankingUserResponse;
import com.eco.backend.ranking.service.RankingService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/rankings")
public class RankingController {

    private final RankingService rankingService;

    public RankingController(RankingService rankingService) {
        this.rankingService = rankingService;
    }

    @GetMapping
    public ResponseEntity<List<RankingUserResponse>> getRankings(
            @RequestParam(required = false) Integer limit
    ) {
        return ResponseEntity.ok(rankingService.getRankings(limit));
    }
}
