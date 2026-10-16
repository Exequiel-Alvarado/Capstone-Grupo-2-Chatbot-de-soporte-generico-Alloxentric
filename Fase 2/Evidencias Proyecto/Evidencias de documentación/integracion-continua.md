# Integración continua del repositorio

Repositorio: [Exequiel-Alvarado/Capstone-Grupo-2](https://github.com/Exequiel-Alvarado/Capstone-Grupo-2) · flujo de trabajo **CI** (`.github/workflows/ci.yml`) · [historial completo en GitHub Actions](https://github.com/Exequiel-Alvarado/Capstone-Grupo-2/actions/workflows/ci.yml?query=branch%3Amain)

Generado el 16-10-2026 con `gh run list --branch main --limit 25` y `gh run view`. Horas en hora de Chile continental (UTC−3).

## Resumen

- **Últimas 25 ejecuciones en `main`: 25 exitosas** (del 09-10-2026 al 16-10-2026).
- La más reciente corresponde al commit `2fc196b` («Merge pull request #31 from Exequiel-Alvarado/backend/comprobar-datos…»), que es el que está en producción.
- Historial completo en `main`: 82 ejecuciones, 45 exitosas y 37 fallidas.
- Las 37 fallidas ocurrieron entre el 28-08-2026 y el 22-09-2026, y todas fallaron en el job de backend. En las que se revisaron (la primera, una intermedia y la última) la causa es la misma: `ModuleNotFoundError: No module named 'app'`, porque `pytest` no dejaba el directorio del backend en el camino de importación. Se corrigió con `pythonpath = .` en `proyecto/backend/pytest.ini`. Desde entonces, las 45 ejecuciones en `main` terminaron en verde.

## Cuándo se ejecuta

En cada `push` a `main` y en cada pull request hacia `main`, de modo que cada PR muestra el resultado antes de fusionarse. Trabaja sobre `proyecto/`, la copia de trabajo del equipo; `base-alloxentric/` (el sistema tal como lo entregó Alloxentric) queda congelado como referencia y no se valida.

## Jobs

Los tres jobs corren en paralelo en `ubuntu-latest`.

| Job | Qué hace | Por qué | Duración en la última ejecución |
|---|---|---|---|
| **Backend · ruff + pytest** | Python 3.12; instala `requirements.txt`, `pytest`, `pytest-asyncio` y `ruff`. Corre `ruff check app tests` (lint) y luego `pytest -q`. Las pruebas usan SQLite (aiosqlite), embeddings `hash` deterministas y un proveedor de modelo simulado. | Ninguna prueba necesita PostgreSQL ni credenciales de servicios externos, y ninguna gasta tokens. Es la verificación rápida de cada cambio. | 2 min 39 s |
| **Backend · pytest en PostgreSQL** | Levanta un PostgreSQL 16 con pgvector como servicio del job (imagen `pgvector/pgvector:pg16`), activa la extensión `vector` con `psql` y corre la misma suite con `DATABASE_URL` apuntando a esa base. | SQLite serializa todas las escrituras y oculta las carreras entre peticiones simultáneas: así pasaron sin verse los números de ticket repetidos y las posiciones de cola iguales. Aquí las pruebas corren contra el mismo motor de producción (Supabase usa PostgreSQL con pgvector). Además corre la prueba del índice HNSW, que en SQLite se salta. | 3 min 09 s |
| **Frontend · build** | Node 20; `npm install` y `npm run build` (Vite) en `proyecto/frontend`. | Comprueba que la SPA de React compila antes de que llegue al despliegue. | 20 s |

El despliegue no es parte de este flujo: lo hace la integración de Vercel con el repositorio, que publica el backend y el frontend cuando llega un cambio a `main` (en el commit más reciente, los estados «Vercel – backend» y «Vercel – frontend» figuran como completados).

## Últimas 25 ejecuciones en `main`

| # | Fecha y hora | Commit | Descripción | Flujo | Resultado | Ejecución |
|---:|---|---|---|---|---|---|
| 1 | 16-10-2026 03:58 | [`2fc196b`](https://github.com/Exequiel-Alvarado/Capstone-Grupo-2/commit/2fc196b5e692ebef248125b1571bb63ce3924b53) | Merge pull request #31 from Exequiel-Alvarado/backend/comprobar-datos… | CI | Exitosa | [ver](https://github.com/Exequiel-Alvarado/Capstone-Grupo-2/actions/runs/38864259747) |
| 2 | 16-10-2026 01:36 | [`4b96941`](https://github.com/Exequiel-Alvarado/Capstone-Grupo-2/commit/4b96941bf9b24f9dea5e1fd75d8d5766ef76fa4e) | Merge pull request #30 from Exequiel-Alvarado/backend/busqueda-exacta… | CI | Exitosa | [ver](https://github.com/Exequiel-Alvarado/Capstone-Grupo-2/actions/runs/38851465402) |
| 3 | 15-10-2026 22:57 | [`418538a`](https://github.com/Exequiel-Alvarado/Capstone-Grupo-2/commit/418538af695f93878a5c21e7a8a1136494202b50) | Merge pull request #29 from Exequiel-Alvarado/feature/mjansen/empresas | CI | Exitosa | [ver](https://github.com/Exequiel-Alvarado/Capstone-Grupo-2/actions/runs/38837889425) |
| 4 | 14-10-2026 13:40 | [`368622a`](https://github.com/Exequiel-Alvarado/Capstone-Grupo-2/commit/368622af730645917484ccd4f658f6449427571b) | Integra proveedor de respaldo de la plataforma | CI | Exitosa | [ver](https://github.com/Exequiel-Alvarado/Capstone-Grupo-2/actions/runs/38600082658) |
| 5 | 14-10-2026 13:13 | [`a6ea287`](https://github.com/Exequiel-Alvarado/Capstone-Grupo-2/commit/a6ea287fe22fd20e4114903dcb6254796834b5ef) | Integra manejo del limite de uso del proveedor | CI | Exitosa | [ver](https://github.com/Exequiel-Alvarado/Capstone-Grupo-2/actions/runs/38596299795) |
| 6 | 14-10-2026 13:01 | [`e9bc2c1`](https://github.com/Exequiel-Alvarado/Capstone-Grupo-2/commit/e9bc2c1803512cae5d25e967f48d3e5ec68b92b2) | Integra conversacion mas humana, reformulacion y continuidad del chat | CI | Exitosa | [ver](https://github.com/Exequiel-Alvarado/Capstone-Grupo-2/actions/runs/38594425856) |
| 7 | 14-10-2026 12:44 | [`65e35ff`](https://github.com/Exequiel-Alvarado/Capstone-Grupo-2/commit/65e35ff69adffb5ae8641be4543adcb14b8e0032) | Integra escaneo del sitio por tandas | CI | Exitosa | [ver](https://github.com/Exequiel-Alvarado/Capstone-Grupo-2/actions/runs/38592000967) |
| 8 | 14-10-2026 12:20 | [`55ffe07`](https://github.com/Exequiel-Alvarado/Capstone-Grupo-2/commit/55ffe07e7b5d706461705a0687db7903f70a66a7) | Integra prompts visibles en Agentes del bot | CI | Exitosa | [ver](https://github.com/Exequiel-Alvarado/Capstone-Grupo-2/actions/runs/38588423622) |
| 9 | 14-10-2026 12:09 | [`c2d295c`](https://github.com/Exequiel-Alvarado/Capstone-Grupo-2/commit/c2d295cd5014c5a6fbc1f0e9d9f94e8a6f52daf0) | Integra verificacion y reglas de negocio en el motor | CI | Exitosa | [ver](https://github.com/Exequiel-Alvarado/Capstone-Grupo-2/actions/runs/38586922080) |
| 10 | 14-10-2026 11:47 | [`1b0eb57`](https://github.com/Exequiel-Alvarado/Capstone-Grupo-2/commit/1b0eb5738ea3db172c561c328ed6986d995441ca) | Usuarios y empresas de prueba de seed_demo en scripts/datos/demo.json | CI | Exitosa | [ver](https://github.com/Exequiel-Alvarado/Capstone-Grupo-2/actions/runs/38583610770) |
| 11 | 14-10-2026 11:35 | [`69f321a`](https://github.com/Exequiel-Alvarado/Capstone-Grupo-2/commit/69f321a41ec0c792d09b03b22738fdcbaf211933) | Integra textos como datos y mensajes del bot por empresa | CI | Exitosa | [ver](https://github.com/Exequiel-Alvarado/Capstone-Grupo-2/actions/runs/38581886758) |
| 12 | 14-10-2026 10:55 | [`d71588c`](https://github.com/Exequiel-Alvarado/Capstone-Grupo-2/commit/d71588c8de75e6584542f29d5ef6df8919186c95) | Integra SCRUM-123 (historial de conversaciones del usuario final) | CI | Exitosa | [ver](https://github.com/Exequiel-Alvarado/Capstone-Grupo-2/actions/runs/38575889147) |
| 13 | 09-10-2026 15:30 | [`55d7756`](https://github.com/Exequiel-Alvarado/Capstone-Grupo-2/commit/55d77560dcbdfd9111e9759bcdf81489daea1742) | Merge branch 'backend/empresa-wellq/exequiel' | CI | Exitosa | [ver](https://github.com/Exequiel-Alvarado/Capstone-Grupo-2/actions/runs/37973775584) |
| 14 | 09-10-2026 14:08 | [`b4825e6`](https://github.com/Exequiel-Alvarado/Capstone-Grupo-2/commit/b4825e6ec0912ee8a16b2d2e263d62fcdc6cd5f1) | Respuestas coherentes en los tickets resueltos de la simulacion | CI | Exitosa | [ver](https://github.com/Exequiel-Alvarado/Capstone-Grupo-2/actions/runs/37964131591) |
| 15 | 09-10-2026 13:59 | [`f89e03c`](https://github.com/Exequiel-Alvarado/Capstone-Grupo-2/commit/f89e03cb276b18adeeb2d8545d4dd2a75390c6ea) | Simulacion con temas por agente y tickets resueltos completos | CI | Exitosa | [ver](https://github.com/Exequiel-Alvarado/Capstone-Grupo-2/actions/runs/37963006291) |
| 16 | 09-10-2026 13:29 | [`f997d7e`](https://github.com/Exequiel-Alvarado/Capstone-Grupo-2/commit/f997d7ee2c6b33380033c500482520c23910a3df) | Merge branch 'backend/clasificador/exequiel' | CI | Exitosa | [ver](https://github.com/Exequiel-Alvarado/Capstone-Grupo-2/actions/runs/37959518551) |
| 17 | 09-10-2026 12:13 | [`4460fa1`](https://github.com/Exequiel-Alvarado/Capstone-Grupo-2/commit/4460fa152d99db88f3151d180c7e6f738ad1e6f0) | Merge branch 'backend/idiomas-escaneo/exequiel' | CI | Exitosa | [ver](https://github.com/Exequiel-Alvarado/Capstone-Grupo-2/actions/runs/37950136961) |
| 18 | 09-10-2026 10:29 | [`1060315`](https://github.com/Exequiel-Alvarado/Capstone-Grupo-2/commit/1060315ef55f8f551920dcf8a940c00c404e8fba) | up | CI | Exitosa | [ver](https://github.com/Exequiel-Alvarado/Capstone-Grupo-2/actions/runs/37937245709) |
| 19 | 09-10-2026 02:05 | [`712912b`](https://github.com/Exequiel-Alvarado/Capstone-Grupo-2/commit/712912b5bf0db4d01f981430ff159ef9aeb81c0e) | Merge pull request #28 from Exequiel-Alvarado/backend/no-rederivar/ex… | CI | Exitosa | [ver](https://github.com/Exequiel-Alvarado/Capstone-Grupo-2/actions/runs/37886953835) |
| 20 | 09-10-2026 01:39 | [`a2154b2`](https://github.com/Exequiel-Alvarado/Capstone-Grupo-2/commit/a2154b2308e16e2985a23b65150c1ddfd1190927) | Merge pull request #24 from Exequiel-Alvarado/backend/historial-usuar… | CI | Exitosa | [ver](https://github.com/Exequiel-Alvarado/Capstone-Grupo-2/actions/runs/37884937884) |
| 21 | 09-10-2026 01:37 | [`b6962c8`](https://github.com/Exequiel-Alvarado/Capstone-Grupo-2/commit/b6962c8cbcd8cf57a99e5b98641602c91f56b71c) | Merge pull request #25 from Exequiel-Alvarado/backend/motor-langgraph… | CI | Exitosa | [ver](https://github.com/Exequiel-Alvarado/Capstone-Grupo-2/actions/runs/37884776968) |
| 22 | 09-10-2026 01:37 | [`0000c8e`](https://github.com/Exequiel-Alvarado/Capstone-Grupo-2/commit/0000c8e96e983eb46d4faf539c0b2df71003e7e7) | Merge pull request #27 from Exequiel-Alvarado/backend/relevancia-busq… | CI | Exitosa | [ver](https://github.com/Exequiel-Alvarado/Capstone-Grupo-2/actions/runs/37884750320) |
| 23 | 09-10-2026 01:36 | [`4418984`](https://github.com/Exequiel-Alvarado/Capstone-Grupo-2/commit/4418984f690dd3b69d6e5c05dbd65aed62551032) | Merge pull request #23 from Exequiel-Alvarado/backend/base-conocimien… | CI | Exitosa | [ver](https://github.com/Exequiel-Alvarado/Capstone-Grupo-2/actions/runs/37884638270) |
| 24 | 09-10-2026 01:35 | [`5ba5aa4`](https://github.com/Exequiel-Alvarado/Capstone-Grupo-2/commit/5ba5aa424ac1e432898d487d487cb342ff72de3c) | Merge pull request #22 from Exequiel-Alvarado/backend/escaneo-web/exe… | CI | Exitosa | [ver](https://github.com/Exequiel-Alvarado/Capstone-Grupo-2/actions/runs/37884618460) |
| 25 | 09-10-2026 01:35 | [`0a107e1`](https://github.com/Exequiel-Alvarado/Capstone-Grupo-2/commit/0a107e1633605682e316f375f9a87d4ddc933287) | Merge pull request #21 from Exequiel-Alvarado/backend/usuarios-demo/e… | CI | Exitosa | [ver](https://github.com/Exequiel-Alvarado/Capstone-Grupo-2/actions/runs/37884583337) |

Las descripciones son el título del commit tal como figura en GitHub (los títulos largos de los merge vienen recortados por GitHub con «…»).
