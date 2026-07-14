package com.example.demo.service;

import org.springframework.stereotype.Service;

/**
 * Greeting business service.
 */
@Service
public class GreetingService {

    /**
     * Generate a greeting message for the given name.
     *
     * @param name the name to greet
     * @return greeting message
     */
    public String greet(String name) {
        if (name == null || name.trim().isEmpty()) {
            name = "World";
        }
        return String.format("Hello, %s! Welcome to the AI Project Test CI/CD Platform.", name.trim());
    }

    /**
     * Generate a farewell message.
     *
     * @param name the name to say goodbye to
     * @return farewell message
     */
    public String farewell(String name) {
        if (name == null || name.trim().isEmpty()) {
            name = "World";
        }
        return String.format("Goodbye, %s! See you next time.", name.trim());
    }
}
