# Evidencias de base de datos — Fase 2

Base de datos del **Chatbot de Soporte Genérico Alloxentric** (Grupo 2, Capstone APT122, Duoc UC).
Producción corre en **Supabase: PostgreSQL 17 + pgvector**. El esquema tiene **19 tablas y 218
columnas**, con 23 claves foráneas, 34 índices (uno de ellos el HNSW vectorial) y 7 restricciones
de unicidad. Las migraciones Alembic van de la 0001 a la 0013.
Generado el 16-10-2026.

## Qué hay en la carpeta

| Archivo | Qué es | De dónde sale |
|---|---|---|
| `esquema.sql` | DDL de PostgreSQL de las 19 tablas. Empieza con `CREATE EXTENSION vector` y sigue con cada `CREATE TABLE` y sus índices. Termina con el índice HNSW de `chunks.embedding`. | Modelos SQLAlchemy (`proyecto/backend/app/models.py`) compilados con el dialecto `postgresql`. El índice HNSW está copiado textual de `alembic/versions/0001_initial.py`. |
| `diccionario-de-datos.xlsx` | Hoja **Tablas** (tabla, descripción, n° de columnas, dominio) y hoja **Columnas** (tipo, nulo, PK, FK, índice o unicidad, valor por defecto y descripción de las 218 columnas). | Tipos, claves e índices: de los modelos. Descripciones: de los comentarios y docstrings del código, de los esquemas de validación (`app/schemas/`) y de los servicios que usan cada columna. |
| `modelo-entidad-relacion.png` / `.svg` | Diagrama entidad-relación de 4000 × 2250 px (16:9) con fondo blanco. Las tablas están agrupadas en cuatro dominios. Cada caja muestra la PK, las FK y las columnas principales. Las relaciones llevan cardinalidad en notación pata de gallo. | Metadatos de los modelos, más la elección de qué columnas mostrar y dónde va cada caja. El SVG lleva el texto como texto, así que se puede buscar y editar. |
| `migraciones.md` | Las 13 migraciones con su fecha, historia de Jira, qué cambia y qué tablas toca. Cierra con la revisión de modelos contra migraciones. | Docstrings de `proyecto/backend/alembic/versions/` y `git log` del repositorio (fecha y mensaje del commit que agregó cada archivo). |
| `LEEME.md` | Este archivo. | — |

## Las tablas por dominio

| Dominio | Tablas |
|---|---|
| Empresas y acceso (4) | `tenants`, `users`, `refresh_tokens`, `end_users` |
| Conocimiento (7) | `documents`, `chunks`, `faqs`, `faq_suggestions`, `faq_improvements`, `website_scans`, `website_pages` |
| Conversación y atención (5) | `bot_agents`, `conversations`, `messages`, `tickets`, `rag_suggestions` |
| Operación (3) | `usage_events`, `tenant_messages`, `platform_settings` |

## Cómo leer el esquema

- **Multiempresa por `tenant_id`.** Lo llevan 14 de las 19 tablas. El aislamiento entre empresas
  lo hace la aplicación, que filtra por esa columna en cada consulta. **No hay RLS** en la base.
  - `messages` y `rag_suggestions` quedan aisladas a través de su conversación, y
    `refresh_tokens` a través de su usuario.
  - `tenants` y `platform_settings` son globales: `platform_settings` tiene una sola fila (id = 1).
  - En `users`, `tenant_id` es NULL solo para el administrador de plataforma.
- **Búsqueda vectorial.** `chunks.embedding` es `vector(1536)` (pgvector), con un índice HNSW por
  distancia coseno. La dimensión sale de `EMBEDDING_DIM` en `app/core/config.py`. Hoy los
  vectores los calcula el backend `hash` (léxico); Azure OpenAI está previsto, pero aún no tiene
  credenciales.
- **Enlaces sin clave foránea.** Hay dos, y en el diagrama van con línea discontinua:
  - `chunks.source_id` apunta a un documento, una FAQ o una página web, según `source_kind`.
  - `faq_improvements.target_faq_ids` es una lista JSON de FAQ.
- **Valores por defecto.** Los UUID, las fechas y los estados iniciales los pone la aplicación al
  insertar. Por eso `esquema.sql` no tiene `DEFAULT`, y el diccionario los muestra en la columna
  «Valor por defecto (lo asigna la aplicación)».
- **Columnas heredadas.** Se conservan en el esquema aunque su función quedó fuera:
  - Las de WhatsApp (`tenants.whatsapp_*`, `conversations.wa_from`) siguen ahí, pero el canal
    quedó fuera del alcance (ADR 0002).
  - `deepseek_key_status` y `deepseek_key_masked` mantienen su nombre antiguo aunque el código
    las llama `llm_key_*` (migración 0006).

## Cómo se regenera

Desde la raíz del repositorio, en PowerShell:

```powershell
# esquema.sql y diccionario-de-datos.xlsx (Python del backend: sqlalchemy, pgvector, openpyxl)
proyecto\backend\.venv\Scripts\python.exe -I clases\recursos\avances\fase-2\scripts\bd_esquema_y_diccionario.py

# modelo-entidad-relacion.png y .svg (Python con matplotlib)
C:\Python312\python.exe clases\recursos\avances\fase-2\scripts\bd_diagrama_er.py
```

- **Ninguno de los dos scripts se conecta a una base.** El primero corre desde su propia carpeta
  para que la configuración del backend no lea ningún `.env`.
- **El segundo pide los metadatos al primero** (`--json`). Revisa que el texto, las cajas y las
  líneas no choquen, y falla si una columna que el diagrama muestra ya no existe en el modelo.
- **`migraciones.md` y este `LEEME.md` se escribieron a mano.** Si se agrega una migración, hay
  que sumar su fila a `migraciones.md`.
- **Si cambia el modelo, el primer script lo avisa.** Una tabla nueva hace fallar el script hasta
  asignarle un dominio, y una columna nueva, hasta escribir su descripción.

## De dónde sale el esquema

El esquema de esta carpeta sale de los **modelos y las migraciones del repositorio**, que son lo
que se aplica a Supabase con `alembic upgrade head`. **No se leyó la base de producción**: no hay
acceso desde este equipo y tampoco se intentó.

Lo que sí se verificó es que modelos y migraciones calzan. Toda columna y tabla agregada después
de la 0001 tiene su migración (detalle en `migraciones.md`). Hay dos cosas que esta carpeta no
puede asegurar:

- **Que Supabase esté en la revisión 0013.** Se confirma en el editor SQL de Supabase con
  `SELECT version_num FROM alembic_version;`, que debe devolver `0013`.
- **Que nadie haya cambiado la base a mano por fuera de Alembic.**
