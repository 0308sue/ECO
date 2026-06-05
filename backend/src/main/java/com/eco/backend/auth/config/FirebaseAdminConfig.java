package com.eco.backend.auth.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import org.springframework.context.annotation.Configuration;

import java.io.IOException;

@Configuration
public class FirebaseAdminConfig {

    public FirebaseAdminConfig() throws IOException {
        if (!FirebaseApp.getApps().isEmpty()) {
            return;
        }

        FirebaseOptions options = FirebaseOptions.builder()
                .setCredentials(GoogleCredentials.getApplicationDefault())
                .build();

        FirebaseApp.initializeApp(options);
    }
}
