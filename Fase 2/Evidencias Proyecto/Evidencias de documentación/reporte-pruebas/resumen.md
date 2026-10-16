# Reporte de pruebas automatizadas del backend

Ejecución del 16-10-2026 sobre el commit `2fc196b` de `main` (el que está en producción), en una copia limpia del repositorio (`git worktree` de `origin/main`), sin tocar el árbol de trabajo del equipo.

- **Entorno:** Windows 11 · Python 3.12.2 · pytest 9.1.1 · SQLite 3.43.1 (aiosqlite). Base de pruebas SQLite propia de la corrida, embeddings `hash` deterministas y proveedor de modelo simulado: las pruebas no llaman a servicios externos ni gastan tokens.
- **Comando** (desde `proyecto/backend`): `python -m pytest -q -p no:cacheprovider --junitxml=junit.xml -rA`
- **Archivos de esta carpeta:** `salida-pytest.txt` (salida completa de pytest, con el resultado de cada prueba) y `junit.xml` (el mismo resultado en formato JUnit, legible por herramientas de CI).

## Totales

| Resultado | Pruebas |
|---|---:|
| Pasadas | **391** |
| Fallo esperado (xfail) | 10 |
| Saltadas | 1 |
| Fallidas o con error | 0 |
| **Total ejecutadas** | **402** |

Archivos de prueba: 40 · duración: 113 s · línea final de pytest: `391 passed, 1 skipped, 10 xfailed in 113.36s (0:01:53)`.

- **xfail** (fallo esperado): pruebas escritas por QA para criterios de aceptación que la aplicación todavía no cumple. Fallan a propósito, no rompen la CI y, cuando se implemente el criterio, pasarán a figurar como XPASS. Se detallan más abajo.
- **Saltada**: la prueba del índice HNSW, que solo existe en PostgreSQL. Se ejecuta en el job «Backend · pytest en PostgreSQL» del CI (ver `../integracion-continua.md`).
- El total cuenta cada caso parametrizado por separado (por ejemplo, una prueba del clasificador que se repite con varias frases), por eso hay más pruebas que funciones.

## Pruebas por archivo

| Área | Archivo | Pruebas | Pasadas | xfail / saltadas | Qué cubre |
|---|---|---:|---:|---|---|
| Cuentas y acceso | `test_auth.py` | 7 | 7 | — | Autenticación (SCRUM-79): ingreso con credenciales correctas e incorrectas, rotación del token de renovación y rechazo de su reutilización, cierre de una sesión o de todas, acceso denegado por rol y sin token. |
| Cuentas y acceso | `test_cuentas_usuario_final.py` | 16 | 16 | — | Cuenta del usuario final en el chat (SCRUM-177): registro, ingreso e historial de conversaciones anteriores. |
| Cuentas y acceso | `test_secrets.py` | 8 | 8 | — | Clave del proveedor por empresa (SCRUM-18): no se puede leer abriendo el almacén, el administrador solo ve la versión enmascarada y una clave rechazada no deja la empresa en un estado incoherente. |
| Administración | `test_bot_agents.py` | 4 | 4 | — | Los dos agentes del bot (SCRUM-91): una empresa nueva queda con ambos, desactivar el comercial manda sus consultas al técnico y el técnico no se puede desactivar. |
| Administración | `test_ejecutivos_empresa.py` | 26 | 24 | 2 xfail | Ejecutivos de la empresa (SCRUM-137, 138 a 140): alta con tipo de derivación y canal, edición, invitación y activación, eliminación con reasignación de conversaciones y tickets, advertencias de cobertura y aislamiento entre empresas. |
| Administración | `test_mensajes_bot.py` | 11 | 11 | — | Textos del producto como datos y mensajes del bot editables por empresa, en los tres idiomas y con sus variables; vista previa del agente y sugerencias de FAQ. |
| Administración | `test_platform.py` | 4 | 4 | — | Administración de plataforma: alta de empresas y rechazo de duplicados, detalle y consumo, desactivación y reactivación (PR #29), dashboard. |
| Administración | `test_prompts_visibles.py` | 4 | 4 | — | Agentes del bot: la instrucción que usa cada agente y la cadena de prompts que recibe la IA, en el panel de empresa y en el de plataforma. |
| Administración | `test_sobre_empresa.py` | 5 | 5 | — | «Sobre la empresa» va en las instrucciones del bot y se puede proponer desde el sitio (SCRUM-188). |
| Proveedor de modelo | `test_limite_proveedor.py` | 9 | 9 | — | Límite de uso del proveedor (429) y proveedor de respaldo de la plataforma: sin saldo, clave rechazada o caída también pasan al respaldo; si fallan los dos se avisa. |
| Proveedor de modelo | `test_proveedor.py` | 9 | 9 | — | Proveedor de modelo sustituible (SCRUM-22): sin clave propia la empresa usa la de la plataforma; con la suya deja de consumir el límite compartido; errores del proveedor bien diferenciados. |
| Proveedor de modelo | `test_proveedor_empresa.py` | 22 | 22 | — | Proveedor, modelo y clave por empresa (SCRUM-158): lo que no configura lo hereda de la plataforma, y la clave de la plataforma nunca viaja a otro proveedor. |
| Base de conocimiento | `test_base_conocimiento.py` | 3 | 3 | — | Base de conocimiento como CRUD: documentos escritos en el panel y edición de preguntas frecuentes. |
| Base de conocimiento | `test_chunking.py` | 5 | 5 | — | Troceo y vectorización (SCRUM-132): trozos por oración con solapamiento, etiquetados con empresa, tipo de chat y documento; reprocesar no duplica. |
| Base de conocimiento | `test_crawler.py` | 21 | 21 | — | Reglas del escaneo web (profundidad, máximo de páginas, rutas y reglas fijas) contra un sitio falso, sin salir a internet. |
| Base de conocimiento | `test_embeddings.py` | 4 | 4 | — | Generación de vectores (SCRUM-134): backend `hash` y cliente de Azure OpenAI con transporte simulado (URL, cabecera de la clave, orden de la respuesta y errores). |
| Base de conocimiento | `test_escaneo_tandas.py` | 5 | 5 | — | Escaneo por tandas: un sitio grande no queda a medias por el tiempo límite de una petición. |
| Base de conocimiento | `test_ingestion.py` | 17 | 17 | — | Extracción de texto de documentos (SCRUM-85): cada formato admitido, PDF a dos columnas, tablas de DOCX, archivos dañados o vacíos y textos que no vienen en UTF-8. |
| Base de conocimiento | `test_knowledge.py` | 3 | 3 | — | Subida, listado, edición y borrado de documentos; CRUD, exportación e importación CSV de preguntas frecuentes. |
| Base de conocimiento | `test_paginas_sitio.py` | 14 | 14 | — | Páginas que trajo el escaneo (SCRUM-187): verlas, editarlas, quitarlas y re-escanear sin perder las editadas; aislamiento entre empresas. |
| Búsqueda | `test_relevancia.py` | 6 | 6 | — | Relevancia de la búsqueda: embedding `hash` normalizado y umbral que permite contar fallos y activar la derivación. |
| Búsqueda | `test_semantic_search.py` | 7 | 6 | 1 saltada | Búsqueda filtrada por empresa y tipo de agente (SCRUM-145): solo devuelve pasajes de la propia empresa, falla explícitamente sin empresa y es exacta (no usa el índice aproximado, PR #30). |
| Motor conversacional | `test_banco_simulacion.py` | 1 | 1 | — | El banco de evaluación sigue apuntando a pasajes que existen en la simulación. |
| Motor conversacional | `test_clasificador_modelo.py` | 7 | 7 | — | Clasificador (SCRUM-119): consulta al modelo solo lo que las reglas y los temas no deciden. |
| Motor conversacional | `test_comprobacion.py` | 12 | 12 | — | Comprobación fija (PR #31): ningún enlace, correo, teléfono, monto o porcentaje que no esté en la base llega al cliente; casos reales de Duoc UC. |
| Motor conversacional | `test_intent.py` | 48 | 48 | — | Clasificador técnico o comercial por reglas, en tres idiomas, y temas de la empresa para los mensajes sin señales. |
| Motor conversacional | `test_language.py` | 17 | 17 | — | El asistente responde en el idioma en que le escriben (SCRUM-183). |
| Motor conversacional | `test_memory.py` | 10 | 10 | — | Memoria de conversación (SCRUM-57): lo reciente viaja literal, lo antiguo se resume, nada se pierde en la frontera y no se re-resume lo resumido. |
| Motor conversacional | `test_motor_evaluation.py` | 4 | 4 | — | Evaluador del motor: métricas de errores y recall parcial, y banco de preguntas que sobrevive a la reindexación. |
| Motor conversacional | `test_motor_langgraph.py` | 7 | 7 | — | Piezas de LangGraph y LangChain del motor: el grafo, el chat model, el retriever y las sugerencias en paralelo. |
| Motor conversacional | `test_rag_chain.py` | 7 | 7 | — | Cadena real con recuperación en SQLite y proveedor simulado: búsqueda acotada a la empresa, registro de consumo y rechazo de conversaciones de otra empresa. |
| Motor conversacional | `test_reformular.py` | 4 | 4 | — | Paso «reformular»: la pregunta completa y las palabras de búsqueda en el idioma de los documentos. |
| Motor conversacional | `test_verificacion_reglas.py` | 9 | 9 | — | Revisión de cada respuesta: generar → verificar → reglas de negocio. |
| Chat y derivación | `test_aviso_ticket_resuelto.py` | 7 | 7 | — | Aviso al usuario cuando su ticket se resuelve (SCRUM-186), por el chat abierto o por WhatsApp (simulado). |
| Chat y derivación | `test_chat_flow.py` | 5 | 5 | — | Flujo de punta a punta: sesión pública → mensaje → derivación → consola del ejecutivo, con el error controlado cuando falta el proveedor. |
| Chat y derivación | `test_derivacion_ejecutivos.py` | 14 | 9 | 5 xfail | Derivación a un ejecutivo disponible (SCRUM-35, subtareas 36 a 40): posición en cola, toma simultánea con un solo ganador y 20 derivaciones concurrentes sin tickets repetidos. |
| Chat y derivación | `test_public_chat.py` | 13 | 13 | — | Chat público (SCRUM-102, subtarea SCRUM-111): respuesta basada en la documentación, historial al recargar y límite de mensajes por minuto. |
| Chat y derivación | `test_tickets_escalation.py` | 15 | 12 | 3 xfail | Derivación con y sin ejecutivos disponibles (SCRUM-113, historia SCRUM-59): ticket con número correlativo por empresa, tipo y prioridad; transcripción para el ejecutivo. |
| Chat y derivación | `test_tickets_supervision.py` | 10 | 10 | — | Vista supervisora de tickets (SCRUM-128): filtros, detalle con la conversación, reasignación, resolución y reapertura, solo dentro de la propia empresa. |
| Infraestructura | `test_health.py` | 2 | 2 | — | Endpoint de salud: 200 con la base disponible y 503 si la base falla. |
| | **Total** | **402** | **391** | 10 xfail, 1 saltada | |

## Aislamiento entre empresas

Es la garantía central de una plataforma multiempresa y una de las evidencias comprometidas para la Fase 2. Estas 19 pruebas comprueban que una empresa no ve, no modifica ni recibe datos de otra (incluidas dos empresas atendidas a la vez por el grafo del motor):

| Archivo | Prueba | Resultado |
|---|---|---|
| `test_chat_flow.py` | `test_tenant_isolation` | Pasa |
| `test_cuentas_usuario_final.py` | `test_la_cuenta_de_una_empresa_no_sirve_en_otra` | Pasa |
| `test_cuentas_usuario_final.py` | `test_no_se_puede_guardar_una_conversacion_de_otra_empresa_ni_con_token_falso` | Pasa |
| `test_cuentas_usuario_final.py` | `test_nadie_retoma_una_conversacion_ajena_ni_de_otra_empresa` | Pasa |
| `test_ejecutivos_empresa.py` | `test_admin_solo_ve_los_ejecutivos_de_su_empresa` | Pasa |
| `test_ejecutivos_empresa.py` | `test_admin_no_puede_editar_ni_eliminar_ejecutivos_de_otra_empresa` | Pasa |
| `test_ejecutivos_empresa.py` | `test_alta_ignora_un_tenant_id_ajeno_enviado_en_el_body` | Pasa |
| `test_ejecutivos_empresa.py` | `test_eliminar_nunca_reasigna_a_ejecutivos_de_otra_empresa` | Pasa |
| `test_mensajes_bot.py` | `test_el_chat_usa_los_mensajes_de_la_empresa_y_no_los_de_otra` | Pasa |
| `test_motor_langgraph.py` | `test_el_grafo_no_mezcla_empresas_en_peticiones_simultaneas` | Pasa |
| `test_motor_langgraph.py` | `test_el_retriever_solo_ve_su_empresa_y_su_tipo` | Pasa |
| `test_paginas_sitio.py` | `test_un_admin_no_ve_ni_toca_las_paginas_de_otra_empresa` | Pasa |
| `test_public_chat.py` | `test_respuesta_no_mezcla_documentacion_de_otra_empresa` | Pasa |
| `test_rag_chain.py` | `test_rejects_conversation_from_other_tenant` | Pasa |
| `test_semantic_search.py` | `test_the_search_only_returns_passages_of_its_own_company` | Pasa |
| `test_semantic_search.py` | `test_building_a_search_without_a_company_fails_explicitly` | Pasa |
| `test_semantic_search.py` | `test_indexing_or_deleting_without_a_company_also_fails` | Pasa |
| `test_tickets_supervision.py` | `test_an_admin_never_sees_or_touches_tickets_of_another_company` | Pasa |
| `test_tickets_supervision.py` | `test_cannot_assign_an_agent_of_another_company` | Pasa |

Pasan 19 de 19. Además, `test_public_chat.py`, `test_derivacion_ejecutivos.py`, `test_tickets_escalation.py` y `test_tickets_supervision.py` crean una empresa propia por prueba, de modo que el resultado no depende de datos de otras.

## Criterios pendientes documentados como xfail (10)

Cada uno nombra la historia o subtarea de Jira cuyo criterio de aceptación falta.

| Archivo | Prueba | Qué falta (motivo registrado en la prueba) |
|---|---|---|
| `test_derivacion_ejecutivos.py` | `test_escalation_is_assigned_to_the_agent_with_least_active_conversations` | SCRUM-36: escalate() no asigna ejecutivo ni mira la carga; _available_agent toma el primero (.first()) |
| `test_derivacion_ejecutivos.py` | `test_ties_are_broken_the_same_way_every_time` | SCRUM-36: no hay desempate estable entre ejecutivos con la misma carga |
| `test_derivacion_ejecutivos.py` | `test_agent_cannot_claim_beyond_the_simultaneous_limit` | SCRUM-38: claim no limita cuántas conversaciones en vivo tiene un ejecutivo (el límite aún no está definido) |
| `test_derivacion_ejecutivos.py` | `test_agent_at_capacity_is_not_available_for_new_escalations` | SCRUM-38: un ejecutivo en su límite sigue contando como disponible y la derivación no pasa a ticket |
| `test_derivacion_ejecutivos.py` | `test_twenty_escalations_are_spread_evenly_across_three_agents` | SCRUM-40 depende de SCRUM-36/38: sin asignación por menor carga las derivaciones no se reparten entre los tres ejecutivos |
| `test_ejecutivos_empresa.py` | `test_alta_informa_que_se_envio_la_invitacion` | SCRUM-139: el alta genera el token pero no envía ni informa la invitación (falta invitation_sent, como en el alta de empresa) |
| `test_ejecutivos_empresa.py` | `test_admin_puede_reenviar_una_invitacion_vencida` | SCRUM-139: no hay forma de reenviar una invitación vencida aunque el error INVITE_EXPIRED lo indique (ruta propuesta: POST .../{agent_id}/invitation) |
| `test_tickets_escalation.py` | `test_ticket_includes_a_summary_of_the_problem` | SCRUM-61: el ticket no tiene resumen del problema; la cola solo muestra Conversation.topic |
| `test_tickets_escalation.py` | `test_confirmation_tells_the_user_the_response_channel` | SCRUM-112: la confirmación al usuario no indica por qué canal recibirá la respuesta |
| `test_tickets_escalation.py` | `test_ticket_priority_depends_on_the_case` | SCRUM-59 criterio 1: la prioridad del ticket siempre queda en medium; nada la asigna según el caso |

## Prueba saltada

| Archivo | Motivo |
|---|---|
| `test_semantic_search.py` | El índice HNSW de los embeddings solo existe en PostgreSQL |
