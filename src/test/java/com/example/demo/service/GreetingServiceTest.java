package com.example.demo.service;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

/**
 * GreetingService unit tests.
 */
class GreetingServiceTest {

    private final GreetingService greetingService = new GreetingService();

    @Test
    @DisplayName("Greet should return greeting with given name")
    void greetShouldReturnGreetingWithName() {
        String result = greetingService.greet("Alice");
        assertNotNull(result);
        assertTrue(result.contains("Alice"));
        assertTrue(result.contains("Hello"));
    }

    @Test
    @DisplayName("Greet should default to World when name is null")
    void greetShouldDefaultWhenNameIsNull() {
        String result = greetingService.greet(null);
        assertNotNull(result);
        assertTrue(result.contains("World"));
    }

    @Test
    @DisplayName("Greet should default to World when name is empty")
    void greetShouldDefaultWhenNameIsEmpty() {
        String result = greetingService.greet("   ");
        assertNotNull(result);
        assertTrue(result.contains("World"));
    }

    @Test
    @DisplayName("Greet should trim whitespace from name")
    void greetShouldTrimWhitespace() {
        String result = greetingService.greet("  Bob  ");
        assertNotNull(result);
        assertTrue(result.contains("Bob"));
    }

    @Test
    @DisplayName("Farewell should return farewell with given name")
    void farewellShouldReturnFarewellWithName() {
        String result = greetingService.farewell("Alice");
        assertNotNull(result);
        assertTrue(result.contains("Alice"));
        assertTrue(result.contains("Goodbye"));
    }

    @Test
    @DisplayName("Farewell should default to World when name is null")
    void farewellShouldDefaultWhenNameIsNull() {
        String result = greetingService.farewell(null);
        assertNotNull(result);
        assertTrue(result.contains("World"));
    }
}
