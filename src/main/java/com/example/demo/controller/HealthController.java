package com.example.demo.controller;

import com.example.demo.service.GreetingService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Health check and API endpoints.
 */
@RestController
public class HealthController {

    @Autowired
    private GreetingService greetingService;

    /**
     * Kubernetes/Docker health check endpoint.
     * Returns application status for liveness and readiness probes.
     */
    @GetMapping("/health")
    public ResponseEntity<Map<String, Object>> health() {
        Map<String, Object> status = new LinkedHashMap<>();
        status.put("status", "UP");
        status.put("timestamp", Instant.now().toString());
        status.put("service", "ai-project-test");
        return ResponseEntity.ok(status);
    }

    /**
     * Readiness probe endpoint.
     */
    @GetMapping("/ready")
    public ResponseEntity<Map<String, Object>> ready() {
        Map<String, Object> status = new LinkedHashMap<>();
        status.put("ready", true);
        status.put("timestamp", Instant.now().toString());
        return ResponseEntity.ok(status);
    }

    /**
     * Example greeting API.
     */
    @GetMapping("/api/greeting")
    public ResponseEntity<Map<String, Object>> greeting(
            @RequestParam(value = "name", defaultValue = "World") String name) {
        String message = greetingService.greet(name);
        Map<String, Object> response = new LinkedHashMap<>();
        response.put("message", message);
        response.put("timestamp", Instant.now().toString());
        return ResponseEntity.ok(response);
    }

    /**
     * Application info endpoint.
     */
    @GetMapping("/api/info")
    public ResponseEntity<Map<String, Object>> info() {
        Map<String, Object> info = new LinkedHashMap<>();
        info.put("application", "ai-project-test");
        info.put("version", "1.0.0-SNAPSHOT");
        info.put("java", System.getProperty("java.version"));
        info.put("timestamp", Instant.now().toString());
        return ResponseEntity.ok(info);
    }
}
