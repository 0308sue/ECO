package com.eco.backend.my;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/my-page")
public class MyPageController {

    private final MyPageService myPageService;

    public MyPageController(MyPageService myPageService) {
        this.myPageService = myPageService;
    }

    @GetMapping("/{userId}")
    public ResponseEntity<MyPageResponse> getMyPage(
            @PathVariable String userId
    ) {
        return ResponseEntity.ok(myPageService.getMyPage(userId));
    }
}
