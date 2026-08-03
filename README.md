# HRAgent — 企业招聘 AI 助手

> 面向企业招聘场景的 AI 辅助系统，聚焦两大高频业务：**智能问答**与**简历审查**。  
> 基于 **LangChain 1.2.10 + LangGraph 1.0.9 + FastAPI** 构建，核心大模型为 **DeepSeek**。

---

## 项目背景

企业招聘团队日常面对两类重复性高、耗费人力的业务：

| 场景 | 痛点 |
|------|------|
| 候选人答疑 | 同类问题反复出现，HR 精力有限 |
| 简历审查 | HR 无暇逐份精读打分 |

HRAgent 将这两类业务分别封装为独立的 AI Agent，每个 Agent 融合了企业私有知识、内置了完整业务流程，并配备了工程化容错机制。

---

## 两大核心 Agent

| Agent | 业务能力 | 核心技术范式 |
|-------|---------|------------|
| **智能问答（QA）** | 基于企业知识库实时答疑 | RAG 混合检索 + BGE-M3 + Reranker 精排 + SSE 流式 |
| **简历审查（Resume）** | 六维度评分并给出改进建议 | PDF 解析 + 结构化抽取 + 多维度并行评分 |

两个 Agent 之上由 **Orchestrator 编排层**统一做意图识别与路由。

---

## 技术栈

| 层面 | 选型 |
|------|------|
| 开发语言 | Python 3.11（严格锁定） |
| Web 框架 | FastAPI + SSE-Starlette |
| Agent 框架 | LangChain 1.2.10 + LangGraph 1.0.9 |
| 主力大模型 | DeepSeek（OpenAI 兼容接口） |
| 向量数据库 | Milvus |
| 关系数据库 | PostgreSQL + SQLAlchemy（全异步） |
| 缓存 | Redis |
| 对象存储 | MinIO |
| 嵌入模型 | BGE-M3（进程内，dense + sparse 双输出） |
| 精排模型 | BGE-Reranker-large（进程内） |
| 意图分类 | MiniLM-L6-v2（进程内） |
| 前端 | Vue3 + TypeScript + Element Plus |

> BGE-M3、BGE-Reranker、MiniLM **三个本地模型均为进程内调用**，无需单独起服务，启动时随后端进程并行预热。

---

## 系统架构

```
┌─────────────────────────────────────────────────┐
│              前端层   Vue3 SPA (:3000)            │
└────────────────────┬────────────────────────────┘
                     │ HTTP / SSE
┌────────────────────▼────────────────────────────┐
│            API 层   FastAPI (:8000)              │
│          JWT 鉴权 / SSE 流式 / 文件上传            │
└────────────────────┬────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────┐
│          编排层   Orchestrator                   │
│      MiniLM 意图识别 → 单 Agent 路由 / 澄清       │
└──────────┬──────────────────────┬───────────────┘
           │                      │
      ┌────▼────┐            ┌────▼────┐
      │   QA    │            │ Resume  │   ← LangGraph StateGraph × 2
      │  Agent  │            │  Agent  │
      └─────────┘            └─────────┘
                       公共层
       ├── LLM Factory（DeepSeek API 统一封装）
       ├── BGE-Reranker / MiniLM / MemorySaver
       └── MCP Server（知识库检索 + Web 搜索）
                     │
┌────────────────────▼────────────────────────────┐
│   数据层   PostgreSQL · Redis · Milvus · MinIO   │
└─────────────────────────────────────────────────┘
```

---

## 环境要求

- Python **3.11**（严格锁定，不兼容其他版本）
- Conda（推荐用于环境隔离）
- Docker & Docker Compose
- DeepSeek API Key

---

## 快速开始

### 1. 克隆项目 & 创建环境

```bash
git clone <repo-url>
cd HRAgent

conda create -n hr_agent python=3.11 -y
conda activate hr_agent
pip install -r requirments.txt
```

### 2. 配置环境变量

```bash
cp .env.example .env.local
```

打开 `.env.local`，填写必填项：

```ini
DB_USER=your_db_user
DB_PASSWORD=your_db_password
DEEPSEEK_API_KEY=sk-xxxxxxxxxxxxxxxx
JWT_SECRET_KEY=any-random-secret-string
```

### 3. 启动基础设施

```bash
docker-compose --env-file .env.local up -d postgres redis minio etcd milvus langfuse
```

### 4. 初始化数据（首次运行）

```bash
python scripts/init_minio.py        # 创建 MinIO Bucket
python scripts/init_milvus.py       # 创建 Milvus Collection
python scripts/seed_data.py         # 写入测试用户
```

### 5. 验证环境

```bash
python scripts/verify_env.py
```

### 6. 启动后端

```bash
# 在项目根目录（HRAgent/）下执行
uvicorn backend.main:app --host 0.0.0.0 --port 8000
```

### 7. 启动前端

```bash
cd frontend
npm install
npm run dev
```

---

## 服务端口

| 服务 | 端口 | 说明 |
|------|------|------|
| FastAPI 后端 | **8000** | REST + SSE 接口，`/docs` 查看 Swagger |
| Vue3 前端 | **3000** | 候选人 / HR / 管理员界面 |
| PostgreSQL | **5433** | 宿主机 5432 已占用，隔离到 5433 |
| Redis | **6380** | 宿主机 6379 已占用 |
| MinIO API | **9002** | 宿主机 9000 已占用 |
| MinIO 控制台 | **9003** | 对象存储管理 |
| Milvus | **19531** | 宿主机 19530 已占用 |
| Langfuse | **3001** | LLM 调用追踪与可观测性 |

> 所有连接配置统一从 `.env.local` 读取，**禁止硬编码端口号**。

---

## 访问地址 & 测试账号

| 地址 | 说明 |
|------|------|
| http://localhost:3000 | 前端应用 |
| http://localhost:8000/docs | FastAPI 接口文档（Swagger） |
| http://localhost:3001 | Langfuse 可观测性平台 |
| http://localhost:9003 | MinIO 控制台 |

| 角色 | 用户名 | 密码 |
|------|------|------|
| 管理员 | admin | Admin@123456 |
| HR | hr01 | Hr@123456 |
| 候选人 | candidate01 | Candidate@123456 |

---

## 目录结构

```
HRAgent/
├── backend/
│   ├── main.py                  # FastAPI 入口 & lifespan（模型预热 + DB 迁移）
│   ├── config.py                # pydantic-settings 配置（从 .env.local 读取）
│   ├── dependencies.py          # JWT 鉴权依赖注入
│   ├── api/v1/                  # 路由：qa / resume / auth / unified_chat
│   ├── agents/                  # 两大 Agent
│   │   ├── qa/                  # graph.py / nodes.py / state.py / prompts.py
│   │   └── resume/
│   ├── core/
│   │   ├── llm_factory.py       # LLM 统一工厂（DeepSeek via OpenAI 兼容接口）
│   │   ├── orchestrator.py      # 编排器（意图路由）
│   │   ├── knowledge_base.py    # BGE-M3 向量检索
│   │   ├── reranker.py          # BGE-Reranker 精排
│   │   ├── memory.py            # MemorySaver 对话记忆管理
│   │   └── retry.py             # 三层兜底重试
│   ├── db/migrations.py         # 启动时自动执行的幂等 DDL 补丁
│   ├── models/                  # 本地模型权重（.gitignore，启动时自动下载）
│   └── mcp/                     # MCP Server（知识库检索 + Web 搜索）
├── frontend/src/
│   ├── views/                   # 页面（qa / resume / login / dashboard）
│   ├── api/                     # HTTP 客户端封装
│   └── stores/                  # Pinia 状态管理
├── scripts/
│   ├── init_milvus.py           # 初始化向量集合
│   ├── seed_data.py             # 填充测试数据
│   ├── build_knowledge_base.py  # 导入知识库文档
│   └── verify_env.py            # 环境自检
├── tests/                       # 单元测试 + 集成测试
├── requirments.txt
├── docker-compose.yml
└── .env.example
```

---

## 知识库导入

首次使用或知识库重建后，需手动导入岗位文档：

```bash
# 重建 Milvus Collection
python scripts/init_milvus.py

# 导入文档（支持 PDF / Word / Markdown）
python scripts/build_knowledge_base.py --file <文档路径> --position_id <岗位UUID>
```

---

## 容错机制

系统内置三层兜底，任何情况下用户都能拿到响应：

| 层级 | 触发条件 | 处理方式 |
|------|---------|---------|
| 第一层：自动重试 | 网络抖动 / LLM 超时 | 间隔 1s / 3s 重试，最多 2 次 |
| 第二层：Agent 降级 | 重试后仍失败 | 问答直答 / 简历给格式提示 |
| 第三层：系统兜底 | 所有降级均失败 | 友好提示 + 已完成结果持久化 + 错误记录 |

---

## 常见问题

**Q: 后端启动报 `extra inputs are not permitted`**

`.env.local` 中保留旧字段没有问题，`config.py` 已设置 `extra = "ignore"` 自动忽略。

**Q: Milvus 连接超时**

确认 etcd 和 milvus-standalone 容器均已 healthy：

```bash
docker-compose ps | grep -E "milvus|etcd"
```

**Q: 前端 SSE 无流式效果**

智能问答的 SSE 接口直连 `http://localhost:8000`，不经过 Vite proxy，属于正常设计。

---

## License

本项目仅供学习与演示使用。
