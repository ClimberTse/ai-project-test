package com.example.demo.controller;

import com.example.demo.service.GreetingService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.test.web.servlet.MockMvc;

import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;
import static org.hamcrest.Matchers.is;

/**
 * HealthController unit tests.
 */
@WebMvcTest(HealthController.class)
class HealthControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private GreetingService greetingService;

    @Test
    @DisplayName("Health endpoint should return UP status")
    void healthShouldReturnUp() throws Exception {
        mockMvc.perform(get("/health"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status", is("UP")))
                .andExpect(jsonPath("$.service", is("ai-project-test")));
    }

    @Test
    @DisplayName("Ready endpoint should return ready true")
    void readyShouldReturnTrue() throws Exception {
        mockMvc.perform(get("/ready"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.ready", is(true)));
    }

    @Test
    @DisplayName("Greeting API should return greeting message")
    void greetingShouldReturnMessage() throws Exception {
        when(greetingService.greet(anyString()))
                .thenReturn("Hello, Test! Welcome to the AI Project Test CI/CD Platform.");

        mockMvc.perform(get("/api/greeting").param("name", "Test"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").exists());
    }

    @Test
    @DisplayName("Greeting API should use default name when not provided")
    void greetingShouldUseDefaultName() throws Exception {
        when(greetingService.greet(anyString()))
                .thenReturn("Hello, World! Welcome to the AI Project Test CI/CD Platform.");

        mockMvc.perform(get("/api/greeting"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").exists());
    }

    @Test
    @DisplayName("Info endpoint should return application info")
    void infoShouldReturnAppInfo() throws Exception {
        mockMvc.perform(get("/api/info"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.application", is("ai-project-test")))
                .andExpect(jsonPath("$.version").exists());
    }
}
