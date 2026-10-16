# Chatbot de Soporte Genérico · Backend

Backend FastAPI del módulo de administración y chat de soporte multiempresa de Alloxentric.
Parte de los 76 endpoints REST y 2 canales WebSocket de la *Especificación de API Backend v1.1*
(documento en la carpeta del proyecto). Al 16 de octubre de 2026 son **106 endpoints REST + 2
canales WebSocket**: se sumaron el escaneo del sitio por páginas y por tandas, las cuentas del
usuario final en el chat, los mensajes del bot editables, el proveedor de modelo con respaldo y
la resolución de tickets. Stack: **FastAPI · PostgreSQL (pgvector) · JWT RS256 (access + refresh)
· LangGraph · React como frontend consumidor**. En producción corre en Vercel con Supabase
([ADR 0001](../docs/adr/0001-despliegue.md)).

## Arranque rápido (docker-compose)

```bash
cp .env.example .env          # revisa las variables
docker compose up --build     # db (pgvector) + redis + api + worker
# API:    http://localhost:8000        (docs interactivas en /docs)
# Salud:  http://localhost:8000/health
```

Las migraciones Alembic corren automáticamente al arrancar el contenedor `api`
(`alembic upgrade head`). Sin Docker: `pip install -r requirements.txt`,
levanta PostgreSQL con pgvector y Redis, y ejecuta `alembic upgrade head &&
uvicorn app.main:app --reload`.

## Tests

```bash
pip install -r requirements.txt pytest pytest-asyncio
pytest
```

La suite (402 pruebas al 16-10-2026) cubre, entre otras cosas: login/refresh con rotación y detección de reutilización,
control de roles, creación de tenants y duplicados, aislamiento multi-tenant,
subida/edición/borrado de documentos con ingesta e indexación, CRUD y export de FAQ,
import CSV, flujo completo de chat público → derivación → consola de agente
(claim atómico, respuesta, resolución, valoración), derivación a ticket sin agentes, el
motor de 7 nodos con sus revisiones (verificar, reglas, comprobar), el escaneo por tandas y
el aislamiento entre empresas.
Los tests corren sobre SQLite (aiosqlite) con embeddings deterministas, y en el CI también
contra PostgreSQL 16 con pgvector; en producción
la búsqueda vectorial usa pgvector. Es exacta dentro de cada empresa: el índice HNSW de la
migración 0001 sigue creado, pero la búsqueda no lo usa porque se saltaba la mejor
coincidencia (ver `services/vectorstore.search`).

## Integraciones reales y modos de desarrollo

Cada integración externa tiene cliente real y un backend local para desarrollar sin credenciales:

| Integración | Cliente real | Modo dev (variable) |
|---|---|---|
| LLM | Cualquier proveedor con formato OpenAI `chat/completions` (httpx); proveedor, modelo y clave de la plataforma, que cada empresa puede sustituir | — (sin key responde error controlado `LLM_KEY_MISSING`) |
| Embeddings | Azure OpenAI (`EMBEDDINGS_BACKEND=azure_openai`) | `hash` (determinista, para dev/tests) |
| Secretos | Azure Key Vault (`SECRETS_BACKEND=keyvault`) | `env` (var/secrets.json, chmod 600) |
| Archivos | Azure Blob Storage + SAS (`STORAGE_BACKEND=azure_blob`) | `local` (var/storage) |
| WhatsApp | Meta Cloud API (envío + webhook con firma HMAC) | firma opcional sin `WHATSAPP_APP_SECRET` |
| Colas | arq sobre Redis (`WORKERS_INLINE=false` + servicio `worker`) | `true` = tareas inline |
| Tiempo real | Redis pub/sub entre réplicas | fallback en memoria |

**Nota de arquitectura:** la especificación menciona Azure Service Bus + Celery como opción de colas;
esta implementación usa **arq** (async-nativo sobre Redis) por coherencia con SQLAlchemy async.
En Azure se despliega igual (Container Apps + Azure Cache for Redis); si se exige Service Bus,
`app/workers/tasks.py::enqueue` es el único punto a sustituir.

## Estructura

```
app/
  main.py               # app FastAPI, CORS, manejador del formato de error {"error": {...}}
  models.py             # 19 tablas SQLAlchemy 2.0 (multi-tenant, pgvector en chunks)
  core/                 # config (pydantic-settings), seguridad JWT RS256, deps de auth, errores
  db/                   # sesión async, tipo EmbeddingVector (pgvector ↔ JSON en tests)
  schemas/              # Pydantic v2: auth, admin, knowledge, chat
  api/v1/
    auth.py             # §6  login, refresh (rotación), logout, me, invitaciones, reset (7)
    platform.py         # §7  dashboard global, CRUD tenants, activar/desactivar, agentes, usage por período, proveedor y respaldo (13)
    company.py          # §8  dashboard + detalle de KPIs, settings, proveedor de modelo y su API key (8)
    documents.py        # §9  documentos por tipo de chat, contenido editable, reingesta (10)
    faqs.py             # §10 CRUD, import CSV, sugerencias IA, mejoras, export pdf/json/docx (11)
    website.py          # §11 URL, reglas de escaneo, escaneos por tandas (seguir/detener), páginas guardadas editables (13)
    bot_agents.py       # §12 agentes técnico/comercial + preview RAG (3)
    bot_messages.py     # mensajes del bot editables por empresa e idioma (3)
    human_agents.py     # §13 CRUD agentes humanos con reasignación (4)
    channels.py         # §14 web/widget/dominios, derivación, WhatsApp (5)
    public_chat.py      # §15 config widget, sesiones, mensajes RAG, escalate, rating (7)
    public_account.py   # cuenta del usuario final en el chat: registro, ingreso, historial y retomar conversaciones (8)
    agent_console.py    # §17 colas, claim atómico, mensajes, sugerencias RAG, tickets (9)
    tickets.py          # tickets de la empresa: lista, detalle y resolución (3)
    webhooks.py         # §18 WhatsApp (verificación + eventos firmados) (2)
    ws.py               # §19 /ws/chat/{session_id} y /ws/agent
  services/             # llm (proveedor + respaldo), embeddings, vectorstore, rag (grafo de 7 nodos),
                        # comprobacion, intent, memory, textos, ingestion, crawler, website_pages,
                        # escalation, suggestions, exporter, whatsapp, storage, secrets, usage,
                        # realtime, ratelimit, motor_evaluation
  workers/tasks.py      # tareas arq: ingesta, escaneo, sugerencias, reindexado
  data/                 # textos como datos (ver «Textos del producto» abajo)
alembic/                # migraciones 0001 a 0013 (la 0001 crea la extensión vector, el esquema y el índice HNSW)
tests/                  # 402 pruebas (ver arriba)
```

## Textos del producto

Ningún texto que diga el bot o que se le dé al modelo está escrito en el código: todo sale
de `app/data/` por medio de `app/services/textos.py`.

| Archivo | Qué tiene | Quién lo cambia |
|---|---|---|
| `app/data/mensajes.json` | Lo que el bot y el sistema dicen en el chat (bienvenida, error técnico, ticket creado o resuelto, ejecutivo se unió…) y algunos textos del panel, en es/en/pt | Los del chat, cada empresa en **Mensajes del bot** (tabla `tenant_messages`); los valores por defecto, editando el JSON |
| `app/data/prompts.json` | Las instrucciones de la plataforma al modelo: reglas de respuesta, clasificador, resumen de memoria, propuesta de «Sobre la empresa», redactor de FAQ | Solo la plataforma. Lo propio de cada empresa va en la instrucción de cada agente, «Sobre la empresa» y los temas |
| `app/data/vocabulario.json` | Las listas de palabras de las reglas: comerciales y técnicas, frases de falla, detección de idioma, palabras vacías | Solo la plataforma. Cada empresa suma lo suyo con los temas de sus agentes |

En el código se piden por nombre: `textos.mensaje_empresa(db, tenant, "ticket_resuelto", lang, numero=…)`,
`textos.prompt("respuesta")`, `textos.palabras("intencion", "comerciales")`. Las variables van
entre llaves y se reemplazan sin `str.format`, así un texto escrito por una empresa no puede
leer nada del servidor. Una prueba (`tests/test_mensajes_bot.py`) verifica que cada mensaje
esté en los tres idiomas y con sus variables.

El contenido de la simulación (empresas, documentos, FAQ, conversaciones) y los usuarios de
prueba (`demo.json`) están en `scripts/datos/`: JSON y Markdown que leen los scripts de carga.

## Primer arranque funcional

1. Crear el superadmin (una vez, en `python -c` o shell):
   ```python
   import asyncio
   from app.db.session import SessionLocal
   from app.models import User
   from app.core.security import hash_password
   async def main():
       async with SessionLocal() as db:
           db.add(User(name="Admin", email="admin@alloxentric.com", role="platform_admin",
                       password_hash=hash_password("<contraseña-segura>"), status="active"))
           await db.commit()
   asyncio.run(main())
   ```
2. `POST /api/v1/auth/login` → crear empresas con `POST /api/v1/platform/tenants`
   (aprovisiona agentes del bot, guarda la API key del proveedor si se indica e invita al admin de empresa).
3. El admin de empresa activa su cuenta (`/auth/invitations/accept`), sube documentos,
   FAQ y URL del sitio, y comparte `soporte.allox.ai/{slug}` o el widget.

## Despliegue Azure de referencia

Container Apps (api + worker) · PostgreSQL Flexible Server con `vector` ·
Azure Cache for Redis · Blob Storage · Key Vault (claves JWT y secretos por tenant vía
`DefaultAzureCredential`) · Static Web Apps (frontend React) · Application Insights.
