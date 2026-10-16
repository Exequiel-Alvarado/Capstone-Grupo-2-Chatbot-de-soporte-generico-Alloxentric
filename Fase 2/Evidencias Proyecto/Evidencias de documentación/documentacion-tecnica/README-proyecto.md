# proyecto/ — avance del equipo

Esta es **nuestra copia de trabajo**. Toma como base lo que la empresa entregó en
[`base-alloxentric/`](../base-alloxentric/), que a partir de ahora se deja **congelado como
referencia** y no se toca.

| Carpeta | Qué es | Se edita |
|---|---|---|
| `base-alloxentric/` | Lo que nos entregó Alloxentric: código, wireframes v1–v5, documento v2.0, especificación de API | ❌ no |
| `proyecto/` | Nuestro avance: el mismo código con nuestras decisiones, alcance y documentación | ✅ sí |
| `clases/` | Entregables académicos de APT122 con el nombre oficial | ✅ sí |

Bitácora de avances: [`BITACORA.md`](BITACORA.md) — se anota ahí, no en el mensaje de commit.

---

## Qué es el proyecto

Plataforma **multi-tenant** de soporte conversacional para Alloxentric. Cada empresa cliente
carga su documentación, sus preguntas frecuentes y la URL de su sitio; la plataforma construye
una base de conocimiento vectorizada y genera un chatbot de soporte web con **dos agentes RAG
especializados** (técnico y comercial), un **clasificador de intención** que enruta cada
consulta, y **derivación a agente humano** — en vivo si hay alguien disponible, como ticket si
no lo hay.

**Clientes iniciales:** WellQ (Reino Unido) · Alloxentric (Chile) · Directa (Chile) ·
Dani27001 (Chile). Están cargados en producción para la demo ([datos simulados](docs/datos-simulados.md)).
**Caso de prueba con un sitio real:** Duoc UC, con sus carreras, mallas y oferta académica.

**En producción:** frontend en `frontend-one-liart-11.vercel.app` y API en
`backend-nine-coral-58.vercel.app`, sobre Supabase ([ADR 0001](docs/adr/0001-despliegue.md)).

---

## Alcance de la v1

Detalle completo y trazado contra el documento del cliente: [`docs/alcance.md`](docs/alcance.md).

### Dentro

- Administración multi-tenant en dos niveles: admin de plataforma y admin de empresa
- Documentos (PDF/DOCX/TXT/MD) por tipo de chat, FAQ con sugerencias de IA y exportación a
  PDF/JSON/Word, escaneo del sitio del cliente
- Dos agentes del bot configurables por empresa; el comercial se puede desactivar
- **Chat web** con enlace único por cliente y widget embebible
- Derivación a humano: chat en vivo con consola de agente, o ticket si no hay nadie
- Dashboards por empresa y de plataforma, con consumo de tokens por período
- Interfaz en español, inglés y portugués, con modo claro y oscuro

### Fuera

- **Canal WhatsApp** — decisión del equipo, ver [ADR 0002](docs/adr/0002-whatsapp-fuera-de-alcance.md).
  El código existe y queda inactivo; la v1 se defiende como plataforma de **chat web**.
- Derivación a humanos por WhatsApp · telefonía, Telegram y redes sociales
- Facturación automática por uso de la plataforma

---

## Stack

| Capa | Tecnología |
|---|---|
| Frontend | **React 18 + Vite** (JavaScript) · React Router · SPA con login único y ruteo por rol |
| Backend | Python 3.11 + FastAPI · SQLAlchemy 2.0 async · 106 endpoints REST + 2 canales WebSocket (contados el 16-10-2026; la especificación del cliente traía 76) |
| Motor | **LangGraph** de 7 nodos: reformular → clasificar → recuperar → generar → verificar → reglas → comprobar ([motor](docs/motor-langgraph.md)) |
| Base de datos | **Supabase** (PostgreSQL 17 + pgvector) · 19 tablas · migraciones Alembic 0001 a 0013 · búsqueda exacta dentro de cada empresa ([búsqueda](docs/busqueda.md)) · PostgreSQL 16 en local vía Docker |
| Auth | JWT RS256 (30 min) + refresh opaco de un solo uso con rotación |
| LLM | **Cualquier proveedor compatible con OpenAI** (`/chat/completions`) · hoy **Groq** `openai/gpt-oss-120b`, que tiene plan gratuito · clave compartida de la plataforma, que cada empresa puede reemplazar por la suya cifrada · proveedor de respaldo si el principal falla |
| Embeddings | **`hash`** en producción: léxico, 1536 dimensiones, sin sinónimos · Azure OpenAI `text-embedding-3-small` programado, sin credenciales |
| Memoria del bot | Ventana de mensajes recientes + resumen de lo anterior, guardado en la propia conversación |
| Colas | `arq` sobre Redis en local · en Vercel, tareas en la misma petición (`WORKERS_INLINE`) y escaneo por tandas |
| Tiempo real | WebSockets + Redis pub/sub, con fallback en memoria · en Vercel, consulta cada pocos segundos |
| Despliegue | **Vercel** para el frontend y para la API · base en Supabase — ver [ADR 0001](docs/adr/0001-despliegue.md) y sus límites más abajo |
| CI | GitHub Actions: ruff + pytest sobre SQLite y sobre PostgreSQL con pgvector + build del frontend |

Cada integración externa tiene cliente real **y** modo de desarrollo sin credenciales, así que
el proyecto se levanta y se prueba entero sin contratar nada.

**Qué no funciona en el despliegue de Vercel, y por qué.** Vercel ejecuta funciones sin estado
y con el disco en solo lectura. Eso deja fuera dos cosas que en local sí funcionan: subir
documentos y que una empresa guarde su propia clave, porque ambas escriben en disco. El chat en
vivo sí funciona, pero sin WebSocket: el chat y la consola del ejecutivo consultan lo nuevo cada
pocos segundos. El bot responde, porque su clave compartida viaja en una variable de entorno.

---

## Arquitectura

```
CAPA DE INTERFACES
  Chat web (enlace único + widget)
  Módulo de administración           Consola de agente
                    │
CAPA DE APLICACIÓN  ▼
  API REST FastAPI · JWT RS256 · control de acceso por rol y por tenant
  cifrado de las API keys · límites de consumo · rate limit
                    │
CAPA DE DOMINIO     ▼
  MOTOR CONVERSACIONAL RAG (grafo de LangGraph)
  reformular → clasificar (técnico | comercial) → recuperar → generar
  → verificar → reglas del negocio → comprobar datos → respuesta o derivación
                    │
CAPA DE DATOS Y SERVICIOS ▼
  Pipeline de ingesta        Supabase + pgvector            Proveedor de modelo
  (arq o en la petición)     (19 tablas, búsqueda exacta)   (Groq + respaldo)
```

### Modelo de datos

19 tablas. Toda tabla de negocio lleva `tenant_id` y se filtra por él en la capa de aplicación.
Diagrama vigente: [`docs/diagramas/modelo-entidad-relacion.svg`](docs/diagramas/modelo-entidad-relacion.svg).

`tenants` · `users` · `refresh_tokens` · `end_users` · `documents` · `chunks` (con `embedding`) ·
`faqs` · `faq_suggestions` · `faq_improvements` · `website_scans` · `website_pages` ·
`bot_agents` · `conversations` · `messages` · `tickets` · `rag_suggestions` · `usage_events` ·
`tenant_messages` · `platform_settings`

- `role` ∈ `platform_admin` · `company_admin` · `human_agent`
- `chat_type` ∈ `technical` · `commercial` · `both`
- `conversations.status` ∈ `bot` · `queued` · `live` · `ticket` · `resolved` · `abandoned`

---

## Levantarlo

```bash
cd proyecto/backend
cp .env.example .env
docker compose up --build      # db (pgvector) + redis + api + worker
# API en http://localhost:8000 · docs en /docs · salud en /health

cd ../frontend
npm install && npm run dev     # http://localhost:5173
```

Tests del backend: `pip install -r requirements.txt pytest pytest-asyncio && pytest`
(402 pruebas al 16-10-2026, sobre SQLite con embeddings deterministas; en el CI también sobre
PostgreSQL con pgvector).

---

## Documentación

| Documento | Qué contiene |
|---|---|
| [`BITACORA.md`](BITACORA.md) | Registro de avances, fecha a fecha |
| [`docs/alcance.md`](docs/alcance.md) | Alcance v1 trazado contra el documento del cliente |
| [`docs/adr/0001-despliegue.md`](docs/adr/0001-despliegue.md) | Dónde corre todo (Vercel + Supabase), qué cambió para que la API cupiera y qué sigue sin funcionar ahí |
| [`docs/adr/0002-whatsapp-fuera-de-alcance.md`](docs/adr/0002-whatsapp-fuera-de-alcance.md) | Por qué WhatsApp sale de la v1 |
| [`docs/revision-mockups-v5.md`](docs/revision-mockups-v5.md) | Segunda opinión sobre el wireframe v5 |
| [`docs/pantallas-figma.md`](docs/pantallas-figma.md) | Inventario de pantallas a diseñar en Figma |
| [`docs/motor-langgraph.md`](docs/motor-langgraph.md) | El motor conversacional: los 7 nodos, las piezas de LangChain y el aislamiento entre empresas |
| [`docs/busqueda.md`](docs/busqueda.md) | Embeddings, umbral de relevancia, clasificador y búsqueda exacta por empresa |
| [`docs/evaluacion-motor.md`](docs/evaluacion-motor.md) | Banco de 120 preguntas y mediciones del clasificador y la recuperación |
| [`docs/datos-simulados.md`](docs/datos-simulados.md) | Las cuatro empresas de la demo, sus cuentas y de dónde sale su contenido |
| [`docs/diagramas/`](docs/diagramas/) | Diagramas de despliegue y entidad-relación vigentes; modelo de datos y casos de uso en Excalidraw |
| [`docs/wireframe.md`](docs/wireframe.md) | El rediseño de la interfaz (v11): qué arregla del v5, el fondo etéreo, cómo traduce y qué se mueve |
