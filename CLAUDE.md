# AI Project Test - 全链路 CI/CD 自动化平台

## 项目概述
Spring Boot 2.7.18 + Java 11 项目，集成 Harness Platform 实现代码构建→单元测试→代码审查→镜像打包→部署→发布→回滚的全链路自动化。

## 技术栈
- **框架**: Spring Boot 2.7.18, Spring 5.3.31
- **JDK**: 11 (Oracle JDK 11.0.21)
- **构建**: Maven 3.8.4
- **测试**: JUnit5 + JaCoCo (覆盖率 ≥80%)
- **代码审查**: Checkstyle 3.2.0 + SpotBugs 4.7.3.6
- **容器**: Docker 多阶段构建 → Alpine JRE11
- **部署**: Docker Compose (蓝绿策略 + 自动回滚)
- **CI/CD**: Harness Platform (7 阶段 Pipeline)
- **OS**: Windows 11

## 环境信息
- **Maven 仓库**: 私有 Nexus `http://192.168.2.252:9091/repository/maven-public/`
- **本地仓库**: `D:\repo`
- **Maven Home**: `D:\Develop\apache-maven-3.8.4`
- **JDK Home**: `C:\Program Files\Java\jdk-11.0.21`
- **Docker**: 未安装（需要 Docker Desktop）

## 核心文件

| 文件 | 用途 |
|------|------|
| `pom.xml` | Maven 配置，含所有插件 |
| `Dockerfile` | 多阶段构建（Maven build → JRE11 Alpine） |
| `docker-compose.yml` | 开发环境部署 |
| `docker-compose.prod.yml` | 生产环境覆盖（资源限制、日志） |
| `Makefile` | 本地快捷命令集合 |
| `.harness/pipeline.yaml` | Harness 7阶段流水线定义 |
| `.harness/services.yaml` | 服务/环境/审批门禁配置 |
| `config/checkstyle.xml` | 代码风格检查规则 |
| `config/spotbugs-exclude.xml` | SpotBugs 误报排除 |

## 自动化脚本（scripts/）

| 脚本 | 功能 |
|------|------|
| `build.sh [profile] [--skip-tests]` | Maven 编译打包 |
| `test.sh` | 单元测试 + JaCoCo 覆盖率检查 |
| `code-review.sh` | Checkstyle + SpotBugs |
| `docker-build.sh [registry] [tag]` | Docker 镜像构建推送 |
| `deploy.sh [tag] [env]` | 蓝绿部署 + 健康检查 + 自动回滚 |
| `rollback.sh [tag]` | 回滚到指定版本 |
| `health-check.sh [url] [timeout]` | 服务健康轮询 |
| `release.sh <version>` | 版本发布（tag + changelog） |

## 常用命令

```bash
# 本地开发
make build           # 编译
make test            # 测试
make code-review     # 代码审查
make run             # 本地启动 (mvn spring-boot:run)
make clean           # 清理

# Docker
make docker-build    # 构建镜像
make deploy          # 部署 (dev)
make deploy-prod     # 部署 (prod)
make rollback        # 回滚上一版本
make health          # 健康检查

# 全流程
make ci              # CI: build + test + code-review
make cd              # CD: docker-build + deploy + health
make full            # 完整 CI/CD
```

## API 端点 (端口 8080)

| 路径 | 用途 |
|------|------|
| `GET /health` | 健康检查（K8s/Docker探针） |
| `GET /ready` | 就绪探针 |
| `GET /api/greeting?name=xxx` | 示例 API |
| `GET /api/info` | 应用版本信息 |

## 源码结构

```
src/main/java/com/example/demo/
├── DemoApplication.java          # Spring Boot 入口
├── controller/
│   └── HealthController.java     # 健康检查 + API 端点
├── service/
│   └── GreetingService.java      # 业务逻辑
└── config/
    └── AppConfig.java            # 自定义配置

src/test/java/com/example/demo/
├── DemoApplicationTests.java     # 上下文加载测试
├── controller/
│   └── HealthControllerTest.java # Controller 层测试 (5 用例)
└── service/
    └── GreetingServiceTest.java  # Service 层测试 (6 用例)
```

## Harness Pipeline 7 阶段

1. **Build** — Maven 编译
2. **Unit Test** — JUnit5 + JaCoCo (≥80%)
3. **Code Review** — Checkstyle + SpotBugs (0 严重违规)
4. **Docker Build** — 多阶段构建 + Trivy 安全扫描
5. **Deploy** — Docker Compose 蓝绿部署
6. **Health Check** — 烟雾测试
7. **Rollback** — 仅在失败时自动触发

## 待办
- [ ] 安装 Docker Desktop
- [ ] 在 Harness Platform 创建项目并导入 `.harness/` 配置
- [ ] 配置 Harness Connectors（Docker Registry, Deploy Host）
- [ ] Push 代码到 Git 仓库，配置 Webhook Trigger
