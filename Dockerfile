# ==============================================
# Multi-stage Docker build for Spring Boot app
# Stage 1: Build with Maven
# Stage 2: Run with minimal JRE
# ==============================================

# ---- Stage 1: Build ----
FROM maven:3.8.8-eclipse-temurin-11 AS builder

WORKDIR /build

# Copy Maven POM first (leverage Docker layer caching)
COPY pom.xml ./
COPY config/ ./config/

# Download dependencies (cached unless pom.xml changes)
RUN mvn dependency:go-offline -B -q

# Copy source code
COPY src/ ./src/

# Build the application (skip tests to speed up; tests run in CI pipeline)
RUN mvn clean package -DskipTests -B -q

# Extract the layered jar for optimized runtime image
RUN java -Djarmode=layertools -jar target/demo.jar extract --destination target/extracted

# ---- Stage 2: Runtime ----
FROM eclipse-temurin:11-jre-alpine AS runtime

# Security: run as non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# Install curl for health checks (and clean up in same layer)
RUN apk add --no-cache curl && \
    rm -rf /var/cache/apk/*

# Copy extracted layers (ordered by change frequency for caching)
COPY --from=builder /build/target/extracted/dependencies/ ./
COPY --from=builder /build/target/extracted/spring-boot-loader/ ./
COPY --from=builder /build/target/extracted/snapshot-dependencies/ ./
COPY --from=builder /build/target/extracted/application/ ./

# Set ownership
RUN chown -R appuser:appgroup /app

# Switch to non-root user
USER appuser

# Expose application port
EXPOSE 8080

# Health check using Spring Boot actuator
HEALTHCHECK --interval=30s --timeout=5s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# JVM options for production
ENV JAVA_OPTS="-Xms256m -Xmx512m -XX:+UseG1GC -XX:MaxGCPauseMillis=200 \
-XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/tmp"

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS org.springframework.boot.loader.JarLauncher"]
