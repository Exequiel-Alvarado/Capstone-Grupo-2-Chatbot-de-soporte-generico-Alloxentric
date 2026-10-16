# Evidencias de documentación · Fase 2

**Proyecto:** Chatbot de Soporte Genérico Alloxentric · APT122 Capstone · Grupo 2
**Integrantes:** Exequiel Alvarado, Diana Guerrero, Manuel Jansen, Cristian Jorquera
**Fecha:** 16-10-2026 (informe de avance de la Fase 2, semana 11)
**Repositorio:** [github.com/Exequiel-Alvarado/Capstone-Grupo-2](https://github.com/Exequiel-Alvarado/Capstone-Grupo-2), rama `main`, commit `2fc196b` (el que está en producción)

Esta carpeta reúne la documentación técnica del proyecto y los registros que respaldan cómo se
trabajó durante la Fase 2: el backlog de Jira, los pull requests, la integración continua y las
pruebas automatizadas.

## Contenido

| Archivo | Qué es |
|---|---|
| `LEEME.md` | Este índice. |
| `backlog-jira.xlsx` | Las 55 historias de usuario y tareas del proyecto SCRUM en Jira, con épica, estado, sprint y responsable, coloreadas por estado. La hoja «Resumen» cuenta por estado, tipo, sprint, responsable y épica con fórmulas sobre la primera hoja. |
| `pull-requests.xlsx` | Los 31 pull requests del repositorio, con autor, fechas de creación y fusión, estado y enlace a GitHub. La hoja «Resumen» cuenta los PR por autor y por mes con fórmulas. |
| `integracion-continua.md` | El flujo de GitHub Actions (qué hace cada job y por qué) y las últimas 25 ejecuciones en `main`, con enlace a cada una. |
| `reporte-pruebas/resumen.md` | Resultado de la suite completa del backend: totales, pruebas por archivo y qué cubre cada uno, pruebas de aislamiento entre empresas y criterios pendientes (xfail). |
| `reporte-pruebas/salida-pytest.txt` | Salida completa de pytest, con el resultado de cada una de las 402 pruebas. |
| `reporte-pruebas/junit.xml` | El mismo resultado en formato JUnit (legible por herramientas de CI). |
| `documentacion-tecnica/README-proyecto.md` | README de `proyecto/`: qué es la plataforma, alcance, stack, despliegue en Vercel + Supabase y sus límites, arquitectura y cómo levantarla. |
| `documentacion-tecnica/README-backend.md` | README del backend: arranque, pruebas, integraciones y modos de desarrollo, estructura de carpetas y primer arranque. |
| `documentacion-tecnica/alcance.md` | Alcance cerrado de la v1: objetivos del documento del cliente frente a lo que entra y lo que queda fuera. |
| `documentacion-tecnica/0001-despliegue.md` | ADR 0001: dónde se despliega la plataforma (Vercel + Supabase) y qué se descartó. |
| `documentacion-tecnica/0002-whatsapp-fuera-de-alcance.md` | ADR 0002: por qué WhatsApp queda fuera de la v1. |
| `documentacion-tecnica/busqueda.md` | Búsqueda del motor: embeddings `hash`, umbral de relevancia calibrado y correcciones del clasificador. |
| `documentacion-tecnica/motor-langgraph.md` | El motor conversacional como grafo de LangGraph: nodos, piezas de LangChain, aislamiento entre empresas y latencia. |
| `documentacion-tecnica/evaluacion-motor.md` | Cómo se evalúan el clasificador y la recuperación con un banco de preguntas, y las mediciones hechas. |
| `documentacion-tecnica/datos-simulados.md` | Datos de demostración: las cuatro empresas iniciales con su conocimiento y un mes de actividad. |
| `documentacion-tecnica/diagrama-despliegue.png` | **Diagrama de despliegue UML** de producción (16-10-2026), pedido por el docente en la Fase 1: navegador, Vercel (CDN y funciones con la API), Supabase (PostgreSQL 17 + pgvector), proveedor del modelo de lenguaje, sitios de los clientes y GitHub Actions, con el protocolo de cada conexión. Reemplaza al diagrama de componentes como vista de arquitectura. |
| `documentacion-tecnica/arquitectura-componentes.png` | Diagrama de componentes del sistema leído del código (versión del 10-09-2026; ver «Desfases conocidos»). |

## Qué evidencia cada cosa

| Evidencia | Dónde se ve |
|---|---|
| **Repositorio con integración continua** | `integracion-continua.md`: cada push y cada PR a `main` pasa por lint, la suite en SQLite, la suite en PostgreSQL con pgvector y el build del frontend; las últimas 25 ejecuciones en `main` terminaron en verde. `pull-requests.xlsx`: el trabajo entra por PR, y 13 de los 31 títulos nombran su historia de Jira (SCRUM-xx). |
| **Backlog basado en historias de usuario** | `backlog-jira.xlsx`: 37 historias y 18 tareas, varias redactadas como «Como … quiero … para …», agrupadas en épicas y asignadas a sprints y responsables, con su estado al 16-10-2026. |
| **Decisiones de arquitectura** | `0001-despliegue.md` y `0002-whatsapp-fuera-de-alcance.md` (ADR), `motor-langgraph.md` (paso de LangChain a LangGraph), `busqueda.md` (umbral y búsqueda exacta), `arquitectura-componentes.png`. |
| **Alcance cerrado** | `alcance.md` (dentro y fuera del alcance) y el ADR 0002. Responde a la observación de la Fase 1 de que el alcance debía cerrarse. |
| **Pruebas automatizadas** | `reporte-pruebas/`: 391 pruebas pasan, 19 de ellas fijan el aislamiento entre empresas; 10 xfail documentan criterios de aceptación aún pendientes, cada uno con su historia de Jira. |

## Cifras al 16-10-2026

| Qué | Cifra | Fuente |
|---|---|---|
| Historias y tareas en Jira | 55: 21 finalizadas, 11 en revisión, 9 en curso, 14 por hacer | `backlog-jira.xlsx` |
| Pull requests | 31, de los cuales 30 fusionados: Exequiel Alvarado 23, Cristian Jorquera 5, Manuel Jansen 2, Diana Guerrero 1 | `pull-requests.xlsx` |
| Integración continua en `main` | Últimas 25 ejecuciones exitosas; en verde sin interrupción desde el 22-09-2026 | `integracion-continua.md` |
| Pruebas del backend | 402 ejecutadas: 391 pasan, 10 xfail, 1 saltada (solo corre en PostgreSQL), 0 fallidas | `reporte-pruebas/resumen.md` |

## Notas sobre las copias

- Los documentos de `documentacion-tecnica/` son **copias** tomadas de `proyecto/` el
  16-10-2026; los originales siguen en el repositorio. Los enlaces relativos entre documentos
  apuntan a la estructura del repositorio y pueden no abrirse desde esta carpeta.
- **Sin contraseñas.** En la copia de `datos-simulados.md` se omitió la contraseña de las cuentas
  de demostración y en `README-backend.md` la del ejemplo de creación del superadministrador
  quedó como `<contraseña-segura>`. No se incluye nada de la carpeta `local/`.
- Los títulos de PR y de commits, y los nombres de épicas y resúmenes de Jira, se copian tal como
  están en GitHub y en Jira (algunos sin tildes).

### Desfases conocidos

Los documentos de `documentacion-tecnica/` se actualizaron el 16-10-2026 con el estado real del
proyecto (PR #32: 106 endpoints REST, 19 tablas, motor de 7 nodos, despliegue en Vercel). Queda
una pieza escrita antes:

| Documento | Qué dice | Situación al 16-10-2026 |
|---|---|---|
| `arquitectura-componentes.png` (10-09-2026) | Modelo DeepSeek; 76 endpoints REST; PostgreSQL 16; embeddings Azure OpenAI; Redis y worker `arq` | Modelo: cualquier proveedor compatible con OpenAI, hoy Groq `openai/gpt-oss-120b`. 106 endpoints REST + 2 WebSocket. Producción en Supabase (PostgreSQL 17 + pgvector) con embeddings `hash`; Azure OpenAI está programado, sin credenciales. Redis y `arq` son opcionales: sin ellos las tareas corren en línea y el tiempo real usa memoria (`README-backend.md`). La vista vigente es `diagrama-despliegue.png`. |

## Cómo se generó

Los archivos se generaron con los scripts de `clases/recursos/avances/fase-2/scripts/`, a partir
de `historias-jira.csv` y `prs.tsv` (exportados de Jira y GitHub el 16-10-2026), de `gh` (GitHub
CLI) para la integración continua y de una ejecución de pytest sobre una copia limpia de
`origin/main`:

| Script | Genera |
|---|---|
| `copiar_documentacion.py` | `documentacion-tecnica/` |
| `backlog_jira.py` | `backlog-jira.xlsx` |
| `pull_requests.py` | `pull-requests.xlsx` |
| `recalcular_excel.ps1` | Recalcula las fórmulas de los dos libros con Excel |
| `integracion_continua.py` | `integracion-continua.md` |
| `resumen_pruebas.py` | `reporte-pruebas/resumen.md` |
