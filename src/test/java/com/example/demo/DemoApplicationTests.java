package com.example.demo;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

/**
 * Application context load test.
 */
@SpringBootTest
@ActiveProfiles("dev")
class DemoApplicationTests {

    @Test
    void contextLoads() {
        // Verify Spring context loads successfully
    }
}
