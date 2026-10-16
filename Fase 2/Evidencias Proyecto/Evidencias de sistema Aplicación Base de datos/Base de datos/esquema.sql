-- =====================================================================================
-- Esquema de la base de datos — Chatbot de Soporte Genérico Alloxentric (Grupo 2)
-- Base desplegada en Supabase: PostgreSQL 17 + pgvector.
-- Generado el 16-10-2026 a partir de los modelos SQLAlchemy (proyecto/backend/app/models.py)
-- compilados con el dialecto postgresql, más el índice HNSW de la migración 0001
-- (proyecto/backend/alembic/versions/0001_initial.py), copiado textual.
-- No se extrajo de la base de producción: es el esquema que define el código y que las
-- migraciones Alembic 0001 a 0013 aplican a Supabase.
-- 19 tablas, 218 columnas.
--
-- Notas:
--  * Los valores por defecto (UUID, fechas, estados) los asigna la aplicación al insertar,
--    no la base: por eso las columnas no llevan DEFAULT.
--  * Las claves foráneas van sin nombre, como las crea create_all. En Supabase, las que
--    agregaron las migraciones 0004 y 0007 sobre la base existente se llaman
--    fk_conversations_end_user_id y fk_tickets_resolved_by.
--  * Alembic agrega además la tabla alembic_version (revisión aplicada), que no es parte
--    del modelo.
--  * La dimensión del vector (1536) sale de EMBEDDING_DIM en app/core/config.py.
--
-- Se regenera con clases/recursos/avances/fase-2/scripts/bd_esquema_y_diccionario.py
-- =====================================================================================

CREATE EXTENSION IF NOT EXISTS vector;

-- platform_settings · Operación · 8 columnas
CREATE TABLE platform_settings (
    id INTEGER NOT NULL,
    default_base_url VARCHAR(200) NOT NULL,
    default_model VARCHAR(60) NOT NULL,
    fallback_base_url VARCHAR(200),
    fallback_model VARCHAR(60),
    escalation_threshold INTEGER NOT NULL,
    default_token_limit_month INTEGER NOT NULL,
    alert_pct INTEGER NOT NULL,
    PRIMARY KEY (id)
);

-- tenants · Empresas y acceso · 38 columnas
CREATE TABLE tenants (
    id UUID NOT NULL,
    name VARCHAR(80) NOT NULL,
    slug VARCHAR(40) NOT NULL,
    legal_name VARCHAR(200) NOT NULL,
    tax_id VARCHAR(60) NOT NULL,
    country VARCHAR(2) NOT NULL,
    language VARCHAR(2) NOT NULL,
    status VARCHAR(20) NOT NULL,
    purge_at TIMESTAMP WITH TIME ZONE,
    bot_name VARCHAR(60) NOT NULL,
    about TEXT,
    business_rules TEXT,
    welcome_message VARCHAR(500) NOT NULL,
    languages JSON NOT NULL,
    widget_color VARCHAR(7) NOT NULL,
    web_published BOOLEAN NOT NULL,
    allowed_domains JSON NOT NULL,
    whatsapp_phone_number_id VARCHAR(60),
    whatsapp_waba_id VARCHAR(60),
    whatsapp_phone_masked VARCHAR(30),
    escalation_when VARCHAR(40) NOT NULL,
    escalation_fallback VARCHAR(20) NOT NULL,
    business_hours JSON,
    timezone VARCHAR(50) NOT NULL,
    website_url VARCHAR(500),
    auto_rescan_days INTEGER NOT NULL,
    scan_max_depth INTEGER NOT NULL,
    scan_max_pages INTEGER NOT NULL,
    scan_include_paths JSON NOT NULL,
    scan_exclude_paths JSON NOT NULL,
    scan_mode VARCHAR(10) NOT NULL,
    scan_urls JSON NOT NULL,
    token_limit_month INTEGER,
    deepseek_key_status VARCHAR(20) NOT NULL,
    deepseek_key_masked VARCHAR(30),
    llm_base_url VARCHAR(300),
    llm_model VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    PRIMARY KEY (id)
);
CREATE UNIQUE INDEX ix_tenants_slug ON tenants (slug);

-- bot_agents · Conversación y atención · 9 columnas
CREATE TABLE bot_agents (
    id UUID NOT NULL,
    tenant_id UUID NOT NULL,
    agent_type VARCHAR(10) NOT NULL,
    enabled BOOLEAN NOT NULL,
    display_name VARCHAR(60) NOT NULL,
    topics VARCHAR(300) NOT NULL,
    system_prompt TEXT NOT NULL,
    knowledge_scope VARCHAR(30) NOT NULL,
    escalation_target VARCHAR(20) NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT uq_bot_agent UNIQUE (tenant_id, agent_type),
    FOREIGN KEY(tenant_id) REFERENCES tenants (id)
);
CREATE INDEX ix_bot_agents_tenant_id ON bot_agents (tenant_id);

-- chunks · Conocimiento · 9 columnas
CREATE TABLE chunks (
    id UUID NOT NULL,
    tenant_id UUID NOT NULL,
    source_kind VARCHAR(10) NOT NULL,
    source_id UUID,
    source_name VARCHAR(300) NOT NULL,
    chat_type VARCHAR(10) NOT NULL,
    content TEXT NOT NULL,
    embedding VECTOR(1536),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    PRIMARY KEY (id),
    FOREIGN KEY(tenant_id) REFERENCES tenants (id)
);
CREATE INDEX ix_chunks_chat_type ON chunks (chat_type);
CREATE INDEX ix_chunks_source_id ON chunks (source_id);
CREATE INDEX ix_chunks_tenant_id ON chunks (tenant_id);

-- documents · Conocimiento · 15 columnas
CREATE TABLE documents (
    id UUID NOT NULL,
    tenant_id UUID NOT NULL,
    filename VARCHAR(300) NOT NULL,
    chat_type VARCHAR(10) NOT NULL,
    size_bytes INTEGER NOT NULL,
    content_hash VARCHAR(64) NOT NULL,
    blob_path VARCHAR(500),
    status VARCHAR(15) NOT NULL,
    progress_pct INTEGER NOT NULL,
    chunks INTEGER NOT NULL,
    error_detail TEXT,
    extracted_content TEXT,
    version INTEGER NOT NULL,
    uploaded_at TIMESTAMP WITH TIME ZONE NOT NULL,
    indexed_at TIMESTAMP WITH TIME ZONE,
    PRIMARY KEY (id),
    CONSTRAINT uq_doc_tenant_hash UNIQUE (tenant_id, content_hash),
    FOREIGN KEY(tenant_id) REFERENCES tenants (id)
);
CREATE INDEX ix_documents_content_hash ON documents (content_hash);
CREATE INDEX ix_documents_tenant_id ON documents (tenant_id);

-- end_users · Empresas y acceso · 7 columnas
CREATE TABLE end_users (
    id UUID NOT NULL,
    tenant_id UUID NOT NULL,
    email VARCHAR(200) NOT NULL,
    name VARCHAR(120),
    password_hash VARCHAR(200) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    last_login_at TIMESTAMP WITH TIME ZONE,
    PRIMARY KEY (id),
    CONSTRAINT uq_end_user_email UNIQUE (tenant_id, email),
    FOREIGN KEY(tenant_id) REFERENCES tenants (id)
);
CREATE INDEX ix_end_users_tenant_id ON end_users (tenant_id);

-- faq_improvements · Conocimiento · 8 columnas
CREATE TABLE faq_improvements (
    id UUID NOT NULL,
    tenant_id UUID NOT NULL,
    kind VARCHAR(10) NOT NULL,
    target_faq_ids JSON NOT NULL,
    proposal TEXT NOT NULL,
    rationale TEXT NOT NULL,
    status VARCHAR(10) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    PRIMARY KEY (id),
    FOREIGN KEY(tenant_id) REFERENCES tenants (id)
);
CREATE INDEX ix_faq_improvements_tenant_id ON faq_improvements (tenant_id);

-- faq_suggestions · Conocimiento · 11 columnas
CREATE TABLE faq_suggestions (
    id UUID NOT NULL,
    tenant_id UUID NOT NULL,
    question VARCHAR(300) NOT NULL,
    suggested_answer TEXT NOT NULL,
    chat_type VARCHAR(10) NOT NULL,
    frequency INTEGER NOT NULL,
    target_document VARCHAR(200) NOT NULL,
    sample_conversations JSON NOT NULL,
    status VARCHAR(10) NOT NULL,
    window_days INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    PRIMARY KEY (id),
    FOREIGN KEY(tenant_id) REFERENCES tenants (id)
);
CREATE INDEX ix_faq_suggestions_tenant_id ON faq_suggestions (tenant_id);

-- faqs · Conocimiento · 7 columnas
CREATE TABLE faqs (
    id UUID NOT NULL,
    tenant_id UUID NOT NULL,
    question VARCHAR(300) NOT NULL,
    answer TEXT NOT NULL,
    chat_type VARCHAR(10) NOT NULL,
    source VARCHAR(12) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL,
    PRIMARY KEY (id),
    FOREIGN KEY(tenant_id) REFERENCES tenants (id)
);
CREATE INDEX ix_faqs_tenant_id ON faqs (tenant_id);

-- tenant_messages · Operación · 6 columnas
CREATE TABLE tenant_messages (
    id UUID NOT NULL,
    tenant_id UUID NOT NULL,
    key VARCHAR(60) NOT NULL,
    lang VARCHAR(2) NOT NULL,
    text VARCHAR(1000) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT uq_tenant_message UNIQUE (tenant_id, key, lang),
    FOREIGN KEY(tenant_id) REFERENCES tenants (id)
);
CREATE INDEX ix_tenant_messages_tenant_id ON tenant_messages (tenant_id);

-- usage_events · Operación · 6 columnas
CREATE TABLE usage_events (
    id UUID NOT NULL,
    tenant_id UUID NOT NULL,
    bot_type VARCHAR(10) NOT NULL,
    channel VARCHAR(10) NOT NULL,
    tokens INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    PRIMARY KEY (id),
    FOREIGN KEY(tenant_id) REFERENCES tenants (id)
);
CREATE INDEX ix_usage_events_created_at ON usage_events (created_at);
CREATE INDEX ix_usage_events_tenant_id ON usage_events (tenant_id);

-- users · Empresas y acceso · 17 columnas
CREATE TABLE users (
    id UUID NOT NULL,
    tenant_id UUID,
    name VARCHAR(80) NOT NULL,
    email VARCHAR(200) NOT NULL,
    password_hash VARCHAR(200),
    role VARCHAR(20) NOT NULL,
    lang VARCHAR(2) NOT NULL,
    theme VARCHAR(10) NOT NULL,
    status VARCHAR(20) NOT NULL,
    invitation_token VARCHAR(100),
    invitation_expires_at TIMESTAMP WITH TIME ZONE,
    reset_token VARCHAR(100),
    reset_expires_at TIMESTAMP WITH TIME ZONE,
    escalation_type VARCHAR(10),
    channel VARCHAR(10),
    presence VARCHAR(10) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    PRIMARY KEY (id),
    FOREIGN KEY(tenant_id) REFERENCES tenants (id)
);
CREATE UNIQUE INDEX ix_users_email ON users (email);
CREATE INDEX ix_users_invitation_token ON users (invitation_token);
CREATE INDEX ix_users_reset_token ON users (reset_token);
CREATE INDEX ix_users_tenant_id ON users (tenant_id);

-- website_scans · Conocimiento · 12 columnas
CREATE TABLE website_scans (
    id UUID NOT NULL,
    tenant_id UUID NOT NULL,
    status VARCHAR(10) NOT NULL,
    progress_pct INTEGER NOT NULL,
    pages_indexed INTEGER NOT NULL,
    pages_excluded INTEGER NOT NULL,
    new_pages INTEGER NOT NULL,
    error_detail TEXT,
    started_at TIMESTAMP WITH TIME ZONE NOT NULL,
    finished_at TIMESTAMP WITH TIME ZONE,
    state JSON,
    lease_until TIMESTAMP WITH TIME ZONE,
    PRIMARY KEY (id),
    FOREIGN KEY(tenant_id) REFERENCES tenants (id)
);
CREATE INDEX ix_website_scans_tenant_id ON website_scans (tenant_id);

-- conversations · Conversación y atención · 23 columnas
CREATE TABLE conversations (
    id UUID NOT NULL,
    tenant_id UUID NOT NULL,
    channel VARCHAR(10) NOT NULL,
    chat_type VARCHAR(10) NOT NULL,
    status VARCHAR(12) NOT NULL,
    priority VARCHAR(6) NOT NULL,
    lang VARCHAR(2) NOT NULL,
    user_name VARCHAR(120),
    user_email VARCHAR(200),
    user_plan VARCHAR(60),
    end_user_id UUID,
    wa_from VARCHAR(30),
    page_url VARCHAR(500),
    bot_failures INTEGER NOT NULL,
    escalation_reason VARCHAR(300),
    topic VARCHAR(200),
    sentiment VARCHAR(30),
    claimed_by UUID,
    escalated_at TIMESTAMP WITH TIME ZONE,
    resolved_at TIMESTAMP WITH TIME ZONE,
    rating VARCHAR(4),
    rating_comment VARCHAR(500),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    PRIMARY KEY (id),
    FOREIGN KEY(tenant_id) REFERENCES tenants (id),
    FOREIGN KEY(end_user_id) REFERENCES end_users (id),
    FOREIGN KEY(claimed_by) REFERENCES users (id)
);
CREATE INDEX ix_conversations_created_at ON conversations (created_at);
CREATE INDEX ix_conversations_end_user_id ON conversations (end_user_id);
CREATE INDEX ix_conversations_status ON conversations (status);
CREATE INDEX ix_conversations_tenant_id ON conversations (tenant_id);
CREATE INDEX ix_conversations_wa_from ON conversations (wa_from);

-- refresh_tokens · Empresas y acceso · 8 columnas
CREATE TABLE refresh_tokens (
    id UUID NOT NULL,
    user_id UUID NOT NULL,
    token VARCHAR(100) NOT NULL,
    family VARCHAR(40) NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    revoked BOOLEAN NOT NULL,
    rotated BOOLEAN NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    PRIMARY KEY (id),
    FOREIGN KEY(user_id) REFERENCES users (id)
);
CREATE INDEX ix_refresh_tokens_family ON refresh_tokens (family);
CREATE UNIQUE INDEX ix_refresh_tokens_token ON refresh_tokens (token);
CREATE INDEX ix_refresh_tokens_user_id ON refresh_tokens (user_id);

-- website_pages · Conocimiento · 10 columnas
CREATE TABLE website_pages (
    id UUID NOT NULL,
    tenant_id UUID NOT NULL,
    url VARCHAR(500) NOT NULL,
    title VARCHAR(300),
    content TEXT NOT NULL,
    site_content TEXT NOT NULL,
    scanned_at TIMESTAMP WITH TIME ZONE NOT NULL,
    edited BOOLEAN NOT NULL,
    edited_at TIMESTAMP WITH TIME ZONE,
    edited_by UUID,
    PRIMARY KEY (id),
    CONSTRAINT uq_website_page_url UNIQUE (tenant_id, url),
    FOREIGN KEY(tenant_id) REFERENCES tenants (id),
    FOREIGN KEY(edited_by) REFERENCES users (id)
);
CREATE INDEX ix_website_pages_tenant_id ON website_pages (tenant_id);

-- messages · Conversación y atención · 7 columnas
CREATE TABLE messages (
    id UUID NOT NULL,
    conversation_id UUID NOT NULL,
    role VARCHAR(8) NOT NULL,
    content TEXT NOT NULL,
    agent_name VARCHAR(80),
    agent_type VARCHAR(10),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    PRIMARY KEY (id),
    FOREIGN KEY(conversation_id) REFERENCES conversations (id)
);
CREATE INDEX ix_messages_conversation_id ON messages (conversation_id);
CREATE INDEX ix_messages_created_at ON messages (created_at);

-- rag_suggestions · Conversación y atención · 7 columnas
CREATE TABLE rag_suggestions (
    id UUID NOT NULL,
    conversation_id UUID NOT NULL,
    content TEXT NOT NULL,
    source_document VARCHAR(300) NOT NULL,
    confidence FLOAT NOT NULL,
    used BOOLEAN NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    PRIMARY KEY (id),
    FOREIGN KEY(conversation_id) REFERENCES conversations (id)
);
CREATE INDEX ix_rag_suggestions_conversation_id ON rag_suggestions (conversation_id);

-- tickets · Conversación y atención · 10 columnas
CREATE TABLE tickets (
    id UUID NOT NULL,
    tenant_id UUID NOT NULL,
    number INTEGER NOT NULL,
    conversation_id UUID NOT NULL,
    status VARCHAR(10) NOT NULL,
    priority VARCHAR(6) NOT NULL,
    assignee_id UUID,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    resolved_at TIMESTAMP WITH TIME ZONE,
    resolved_by UUID,
    PRIMARY KEY (id),
    CONSTRAINT uq_ticket_number UNIQUE (tenant_id, number),
    FOREIGN KEY(tenant_id) REFERENCES tenants (id),
    UNIQUE (conversation_id),
    FOREIGN KEY(conversation_id) REFERENCES conversations (id),
    FOREIGN KEY(assignee_id) REFERENCES users (id),
    FOREIGN KEY(resolved_by) REFERENCES users (id)
);
CREATE INDEX ix_tickets_status ON tickets (status);
CREATE INDEX ix_tickets_tenant_id ON tickets (tenant_id);

-- Índice vectorial de la migración 0001 (búsqueda por similitud coseno en chunks)
CREATE INDEX IF NOT EXISTS ix_chunks_embedding ON chunks USING hnsw (embedding vector_cosine_ops);
