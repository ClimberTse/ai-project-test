package com.example.demo.config;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

/**
 * Application custom configuration.
 */
@Configuration
@ConfigurationProperties(prefix = "app")
public class AppConfig {

    /**
     * Application name.
     */
    private String name = "ai-project-test";

    /**
     * Application version.
     */
    private String version = "1.0.0-SNAPSHOT";

    /**
     * Deployment environment.
     */
    private String env = "dev";

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getVersion() {
        return version;
    }

    public void setVersion(String version) {
        this.version = version;
    }

    public String getEnv() {
        return env;
    }

    public void setEnv(String env) {
        this.env = env;
    }
}
