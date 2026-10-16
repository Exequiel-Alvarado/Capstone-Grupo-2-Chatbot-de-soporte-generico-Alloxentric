# Migraciones de la base de datos (Alembic 0001 a 0013)

Las migraciones están en `proyecto/backend/alembic/versions/` y forman una cadena lineal: cada
una declara la anterior en `down_revision`. Son las que se aplican a la base de producción en
Supabase (PostgreSQL 17 + pgvector) con `alembic upgrade head`.

**Fechas.** Solo la 0001 trae fecha en el archivo (`Create Date: 2026-08-08`, heredada del
sistema que entregó Alloxentric). Para las demás se usa la fecha del commit que agregó el archivo
al repositorio (`git log`). La historia de Jira sale del docstring o del mensaje de ese commit.

| N° | Archivo | Fecha | Historia | Qué cambia | Tablas |
|---|---|---|---|---|---|
| 0001 | `0001_initial.py` | 08-08-2026 (en el archivo); en el repositorio desde el 04-09-2026 | — | Esquema inicial: crea la extensión `vector` (pgvector), todas las tablas del modelo con `Base.metadata.create_all` y el índice HNSW `ix_chunks_embedding` sobre `chunks.embedding` (`vector_cosine_ops`). | Todas (16 cuando se selló) |
| 0002 | `0002_proveedor_plataforma.py` | 01-10-2026 (commit) | SCRUM-22 | Proveedor de modelo configurable a nivel de plataforma: agrega `default_base_url` (varchar 200, obligatoria), ensancha `default_model` de varchar(40) a varchar(60) y reemplaza los modelos que DeepSeek retiró (`deepseek-chat`, `deepseek-reasoner`) por `openai/gpt-oss-120b` en Groq. Es la primera migración con DDL propio (`ALTER TABLE`). | `platform_settings` |
| 0003 | `0003_reglas_escaneo_web.py` | 08-10-2026 (commit) | — | Reglas del escaneo web por empresa: `scan_max_depth` (3), `scan_max_pages` (150), `scan_include_paths` y `scan_exclude_paths` (JSON, lista vacía). Las empresas existentes quedan con esos valores. | `tenants` |
| 0004 | `0004_cuentas_usuario_final.py` | 09-10-2026 (commit) | — | Cuentas del usuario final en el chat: crea `end_users` (correo único por empresa, `uq_end_user_email`; índice `ix_end_users_tenant_id`) y agrega `conversations.end_user_id` con la clave foránea `fk_conversations_end_user_id` y su índice. Las conversaciones anteriores quedan anónimas. | `end_users`, `conversations` |
| 0005 | `0005_modo_escaneo_web.py` | 09-10-2026 (commit) | SCRUM-184 | Modo del escaneo: `scan_mode` (page, section, site o list; las empresas existentes quedan en site) y `scan_urls` (JSON) para el modo lista. | `tenants` |
| 0006 | `0006_proveedor_por_empresa.py` | 09-10-2026 (commit) | SCRUM-158 | Proveedor de modelo por empresa: `llm_base_url` (varchar 300) y `llm_model` (varchar 100), en NULL = heredar el de la plataforma. A propósito no renombra `deepseek_key_status` ni `deepseek_key_masked` (el código las llama `llm_key_*`), para poder aplicarla antes de desplegar. | `tenants` |
| 0007 | `0007_resolucion_tickets.py` | 09-10-2026 (commit) | SCRUM-128 | Cuándo y quién resolvió cada ticket: `resolved_at` y `resolved_by` (clave foránea `fk_tickets_resolved_by` → `users`). Los tickets ya resueltos toman la fecha de cierre de su conversación; quién los resolvió queda vacío. | `tickets` |
| 0008 | `0008_paginas_sitio_web.py` | 09-10-2026 (commit) | SCRUM-187 | Páginas que trajo el escaneo del sitio, para verlas, editarlas y quitarlas: crea `website_pages` (única por empresa y URL, `uq_website_page_url`; índice `ix_website_pages_tenant_id`). Solo agrega: los fragmentos web anteriores se asocian a su página desde el código. | `website_pages` |
| 0009 | `0009_sobre_la_empresa.py` | 09-10-2026 (commit) | SCRUM-188 | «Sobre la empresa»: `about` (text, NULL), que va en las instrucciones del bot. | `tenants` |
| 0010 | `0010_mensajes_del_bot.py` | 14-10-2026 (commit) | — | Mensajes del bot editables por empresa e idioma: crea `tenant_messages` (único por empresa, clave e idioma, `uq_tenant_message`; índice `ix_tenant_messages_tenant_id`). Los textos por defecto siguen en `app/data/mensajes.json`. | `tenant_messages` |
| 0011 | `0011_reglas_del_negocio.py` | 14-10-2026 (commit) | — | Reglas del negocio de cada empresa, que el motor aplica a cada respuesta: `business_rules` (text, NULL). | `tenants` |
| 0012 | `0012_escaneo_por_tandas.py` | 14-10-2026 (commit) | — | Escaneo por tandas: `state` (JSON con la cola, las vistas y las indexadas) y `lease_until` (hasta cuándo una petición tiene el turno). | `website_scans` |
| 0013 | `0013_proveedor_respaldo.py` | 14-10-2026 (commit) | — | Proveedor de respaldo de la plataforma: `fallback_base_url` (varchar 200) y `fallback_model` (varchar 60), vacías = sin respaldo. La clave va en la variable `LLM_FALLBACK_API_KEY`, no en la base. | `platform_settings` |

## En números

- **Al sellar la 0001:** 16 tablas.
- **Hoy (0013):** 19 tablas y 218 columnas. Las migraciones 0002 a 0013 agregaron 3 tablas
  (`end_users`, `website_pages`, `tenant_messages`), 18 columnas en tablas existentes (10 en
  `tenants`, 3 en `platform_settings`, 2 en `website_scans`, 2 en `tickets`, 1 en
  `conversations`) y cambiaron el tipo de una (`platform_settings.default_model`).
- **Además de las 19 tablas**, Alembic mantiene en la base la tabla `alembic_version`, con la
  revisión aplicada.

## Cómo están escritas

- **La 0001 no es una foto fija.** Hace `create_all` con los modelos *actuales*. En una base
  vacía crea de una vez las 19 tablas, y las 0002 a 0013 no tienen nada que hacer. En la base
  que ya existía (Supabase, sellada en la 0001 con 16 tablas), las 0002 a 0013 agregan lo que
  falta paso a paso.
- **Por eso desde la 0002 cada cambio va condicionado:** primero revisa si la tabla o la columna
  ya existe y solo la crea si falta.
- **Primero se migra y después se despliega.** Casi todas solo agregan columnas que admiten NULL o
  tablas nuevas que el código anterior no lee. Así se pueden aplicar antes de desplegar, porque
  Vercel despliega solo al subir a `main`.
- **Las columnas obligatorias se agregan con un valor por defecto en la base** para rellenar las
  filas existentes (0002, 0003, 0005). Después ese valor se retira en PostgreSQL: el valor por
  defecto lo decide la aplicación.

## Revisión modelos ↔ migraciones (16-10-2026)

Se compararon los modelos del commit que agregó la 0001 (`e48ba00`, 04-09-2026) con los
modelos actuales. **Toda diferencia está cubierta por una migración**: las 3 tablas nuevas, las
18 columnas agregadas y el cambio de tipo. Ninguna columna del modelo quedó sin su migración.
Ninguna migración agrega algo que el modelo no tenga. Diferencias menores:

1. **Nombres de dos claves foráneas.** En Supabase, las migraciones 0004 y 0007 las crearon como
   `fk_conversations_end_user_id` y `fk_tickets_resolved_by`. En una base nueva (solo la 0001)
   quedan con el nombre automático de PostgreSQL (`conversations_end_user_id_fkey`,
   `tickets_resolved_by_fkey`). La restricción es la misma; solo cambia el nombre.
2. **Nombre de columna distinto del atributo.** `llm_key_status` y `llm_key_masked` del código
   apuntan a las columnas `deepseek_key_status` y `deepseek_key_masked`. Es a propósito (ver la
   0006).
3. **Los estados intermedios no se reconstruyen.** Como la 0001 usa los modelos actuales, una
   base vacía llevada a `alembic upgrade 0003` no queda como estaba la base real en la 0003.
   Queda con el esquema completo de hoy.
