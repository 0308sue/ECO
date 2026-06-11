package com.example.front;

import android.content.pm.ApplicationInfo;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.os.Bundle;
import android.util.Base64;
import android.util.Log;

import androidx.annotation.NonNull;

import java.util.HashMap;
import java.util.Map;
import java.security.MessageDigest;

import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.android.FlutterFragmentActivity;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterFragmentActivity {
    private static final String CONFIG_CHANNEL = "eco/native_config";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        printKeyHash();
    }

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        new MethodChannel(
                flutterEngine.getDartExecutor().getBinaryMessenger(),
                CONFIG_CHANNEL
        ).setMethodCallHandler((call, result) -> {
            if ("getNaverConfigDebug".equals(call.method)) {
                result.success(getNaverConfigDebug());
            } else {
                result.notImplemented();
            }
        });
    }

    private void printKeyHash() {
        try {
            PackageInfo info = getPackageManager().getPackageInfo(
                    getPackageName(),
                    PackageManager.GET_SIGNATURES
            );

            for (android.content.pm.Signature signature : info.signatures) {
                MessageDigest messageDigest = MessageDigest.getInstance("SHA");
                messageDigest.update(signature.toByteArray());
                Log.d(
                        "KeyHash",
                        Base64.encodeToString(messageDigest.digest(), Base64.DEFAULT)
                );
            }
        } catch (Exception error) {
            Log.e("KeyHash", error.getMessage() == null ? "error" : error.getMessage());
        }
    }

    private Map<String, Object> getNaverConfigDebug() {
        Map<String, Object> debugInfo = new HashMap<>();
        debugInfo.put("packageName", getPackageName());

        try {
            ApplicationInfo appInfo = getPackageManager().getApplicationInfo(
                    getPackageName(),
                    PackageManager.GET_META_DATA
            );

            Bundle metaData = appInfo.metaData;
            String clientId = metaData == null
                    ? null
                    : metaData.getString("com.naver.sdk.clientId");
            String clientSecret = metaData == null
                    ? null
                    : metaData.getString("com.naver.sdk.clientSecret");
            String clientName = metaData == null
                    ? null
                    : metaData.getString("com.naver.sdk.clientName");

            debugInfo.put("clientIdPreview", preview(clientId));
            debugInfo.put("clientIdLength", clientId == null ? 0 : clientId.length());
            debugInfo.put("clientSecretPreview", preview(clientSecret));
            debugInfo.put("clientSecretLength", clientSecret == null ? 0 : clientSecret.length());
            debugInfo.put("hasClientSecret", clientSecret != null && !clientSecret.isEmpty());
            debugInfo.put("clientName", clientName == null ? "" : clientName);
            debugInfo.put(
                    "looksLikeExample",
                    (clientId != null && clientId.contains("your_"))
                            || (clientSecret != null && clientSecret.contains("your_"))
            );
        } catch (Exception error) {
            debugInfo.put("error", error.getMessage() == null ? "error" : error.getMessage());
        }

        return debugInfo;
    }

    private String preview(String value) {
        if (value == null || value.isEmpty()) {
            return "";
        }
        if (value.length() <= 8) {
            return value;
        }
        return value.substring(0, 4) + "..." + value.substring(value.length() - 4);
    }
}
