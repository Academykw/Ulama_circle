package com.ulama.circle.lectures.ulama_circle;

import androidx.annotation.NonNull;

import com.ryanheise.audioservice.AudioServiceActivity;

import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

// Extends AudioServiceActivity (required by audio_service for background audio)
// and exposes a channel so Dart can minimise the app to the background
// (moveTaskToBack) — the "back = minimise, keep playing" behaviour.
public class MainActivity extends AudioServiceActivity {
    private static final String CHANNEL = "ulama/app";

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
            .setMethodCallHandler((call, result) -> {
                if ("moveToBack".equals(call.method)) {
                    moveTaskToBack(true);
                    result.success(true);
                } else {
                    result.notImplemented();
                }
            });
    }
}
