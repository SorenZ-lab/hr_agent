-- ============================================================
-- 企业招聘智能助手 PostgreSQL 数据库初始化脚本
-- Docker 启动时自动执行（挂载到 /docker-entrypoint-initdb.d/）
-- ============================================================

-- 启用 UUID 自动生成扩展
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- 用户与权限表
-- ============================================================
CREATE TABLE IF NOT EXISTS users (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id       VARCHAR(64) NOT NULL DEFAULT 'tenant_default',
    username        VARCHAR(64) NOT NULL,
    email           VARCHAR(128) NOT NULL,
    password_hash   VARCHAR(256) NOT NULL,
    role            VARCHAR(16) NOT NULL CHECK (role IN ('candidate', 'hr', 'admin')),
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (tenant_id, email)
);
CREATE INDEX idx_users_tenant_id ON users (tenant_id);
CREATE INDEX idx_users_role ON users (role);

-- ============================================================
-- 知识库待补充队列
-- ============================================================
CREATE TABLE IF NOT EXISTS knowledge_pending_queue (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id       VARCHAR(64) NOT NULL DEFAULT 'tenant_default',
    question        TEXT NOT NULL,
    candidate_id    UUID REFERENCES users(id),
    confidence      FLOAT NOT NULL,
    status          VARCHAR(16) NOT NULL DEFAULT 'pending'
                    CHECK (status IN ('pending', 'resolved', 'dismissed')),
    resolved_by     UUID REFERENCES users(id),
    resolved_at     TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_knowledge_pending_queue_tenant_id ON knowledge_pending_queue (tenant_id);
CREATE INDEX idx_knowledge_pending_queue_status ON knowledge_pending_queue (status);

-- ============================================================
-- 简历审查相关表
-- ============================================================
CREATE TABLE IF NOT EXISTS resume_reviews (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id       VARCHAR(64) NOT NULL DEFAULT 'tenant_default',
    candidate_id    UUID REFERENCES users(id),
    pdf_minio_path  VARCHAR(512) NOT NULL,
    structured_data JSONB,
    scores          JSONB,
    issues          JSONB,
    summary         JSONB,
    status          VARCHAR(16) NOT NULL DEFAULT 'pending'
                    CHECK (status IN ('pending', 'processing', 'done', 'failed')),
    error_msg       TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_resume_reviews_tenant_id ON resume_reviews (tenant_id);
CREATE INDEX idx_resume_reviews_candidate_id ON resume_reviews (candidate_id);
CREATE INDEX idx_resume_reviews_status ON resume_reviews (status);

-- ============================================================
-- 问答会话表
-- ============================================================
CREATE TABLE IF NOT EXISTS qa_sessions (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id       VARCHAR(64) NOT NULL DEFAULT 'tenant_default',
    candidate_id    UUID REFERENCES users(id),
    thread_id       VARCHAR(128) NOT NULL UNIQUE,
    summary         TEXT,
    summary_version INT NOT NULL DEFAULT 0,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_qa_sessions_tenant_id ON qa_sessions (tenant_id);
CREATE INDEX idx_qa_sessions_candidate_id ON qa_sessions (candidate_id);
CREATE INDEX idx_qa_sessions_thread_id ON qa_sessions (thread_id);

-- ============================================================
-- 自动更新 updated_at 触发器
-- ============================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE
    t TEXT;
BEGIN
    FOREACH t IN ARRAY ARRAY[
        'users',
        'resume_reviews', 'qa_sessions'
    ]
    LOOP
        EXECUTE format('
            CREATE TRIGGER trg_%s_updated_at
            BEFORE UPDATE ON %s
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
        ', t, t);
    END LOOP;
END;
$$;
