# Alcance de la v1

Trazado contra el documento del cliente *Chatbot de Soporte Genérico · Alloxentric · v2.0*
(agosto 2026), sección 3. La columna **v1** dice qué asume el equipo para esta entrega.

## Objetivos específicos del documento vs. nuestra v1

| # | Objetivo del documento (§2.2) | v1 | Nota |
|---|---|---|---|
| 1 | Módulo de administración por empresa | ✅ | Dos niveles: plataforma y empresa |
| 2 | Pipeline de ingesta (documentos, FAQ, sitio web) por tipo de chat | ✅ | PDF/DOCX/TXT/MD + crawler por tandas. En Vercel no se pueden subir archivos ([ADR 0001](adr/0001-despliegue.md)) |
| 3 | Motor RAG con dos agentes y clasificador de intención | ✅ | Grafo de LangGraph de 7 nodos ([motor](motor-langgraph.md)). Clasificador: reglas, temas de la empresa y modelo. Última medición, sin el modelo: 78,3 % de acierto en validación, con meta de 90 % ([evaluación](evaluacion-motor.md)) |
| 4 | Enlace de chat por cliente **y canal WhatsApp** | ⚠️ parcial | Enlace y widget sí; **WhatsApp no** — [ADR 0002](adr/0002-whatsapp-fuera-de-alcance.md) |
| 5 | Derivación a humano: chat en vivo y ticket, con consola de agente | ✅ | Colas por tipo. WebSocket en local; en Vercel, el chat y la consola consultan cada pocos segundos |
| 6 | Sugerencias de FAQ por IA y exportación PDF/JSON/Word | ✅ | |
| 7 | Aislamiento multi-tenant y visibilidad de plataforma | ✅ | Filtrado en la capa de aplicación, no RLS |
| 8 | Interfaz ES/EN/PT, claro/oscuro, bot en el idioma del usuario | ✅ | |
| 9 | Producción con los cuatro clientes iniciales | ⚠️ parcial | Desplegado en Vercel + Supabase. Las cuatro empresas están cargadas para la demo ([datos simulados](datos-simulados.md): contenido real del sitio de WellQ y Alloxentric, sintético en Directa y Dani27001), más Duoc UC como caso de prueba con su sitio real. Falta el alta con datos reales de cada cliente |

## Dentro del alcance

- **Administración multi-tenant en dos niveles.** Admin de plataforma (Alloxentric): dashboard
  global, ficha de cada empresa con datos legales, bots por canal y consumo de tokens por
  período, agentes de todas las empresas en modo lectura, configuración global. Admin de
  empresa: gestión completa de su tenant.
- **Conocimiento.** Subida y edición de documentos PDF/DOCX/TXT/MD, cada uno asignado al chat
  técnico, al comercial o a ambos. Escaneo del sitio del cliente. Editor de FAQ con sugerencias
  generadas por IA a partir de conversaciones reales y exportación a PDF, JSON y Word.
- **Motor conversacional.** Clasificador de intención + dos agentes RAG por empresa (técnico y
  comercial) con instrucciones, tono y fuentes propias. El comercial se puede desactivar.
  Generación con cualquier proveedor compatible con OpenAI (hoy Groq, `openai/gpt-oss-120b`),
  con clave compartida de la plataforma y un proveedor de respaldo; cada empresa puede poner su
  propia clave, guardada cifrada. Cada respuesta pasa por verificación contra la base de
  conocimiento y por una comprobación de los datos concretos (enlaces, correos, teléfonos,
  montos), para que el bot no invente.
- **Canal web.** Enlace único por cliente y widget embebible. El bot responde en el idioma del
  usuario (ES/EN/PT).
- **Derivación a humano.** Chat en vivo con consola de agente (WebSocket, o consulta periódica
  donde no hay WebSocket) —colas por tipo,
  transcripción con motivo de la derivación, panel de contexto del usuario, respuestas sugeridas
  por RAG y editables— o ticket cuando no hay ningún agente disponible del tipo correspondiente.
- **Métricas.** Dashboard por empresa con KPIs clickeables y detalle en modal; dashboard global
  de plataforma con consumo de tokens y selector de período.
- **Interfaz.** Español, inglés y portugués, con modo claro y oscuro.

## Fuera del alcance

| Queda fuera | Por qué |
|---|---|
| **Canal WhatsApp** | La verificación de Meta y la aprobación de plantillas no dependen del equipo y no caben en el calendario del ramo. [ADR 0002](adr/0002-whatsapp-fuera-de-alcance.md) |
| Derivación a humanos por WhatsApp | Ya estaba fuera en el documento del cliente (§3.2) |
| Telefonía/voz, Telegram, redes sociales | Ya estaba fuera en el documento del cliente (§3.2) |
| Facturación automática por uso | Ya estaba fuera en el documento del cliente (§3.2) |
| Row Level Security en PostgreSQL | El proyecto recibido filtra por `tenant_id` en la aplicación. Migrar a RLS es un refactor completo del acceso a datos; se documenta como mejora, no se ejecuta en la v1 |

## Lo que este alcance cambia en la defensa

El proyecto sigue siendo **multiempresa, con dos agentes especializados y derivación a humano**,
que es la tesis del caso. Lo que se pierde al sacar WhatsApp es un segundo canal de entrada, no
una capacidad del motor.

La frase para la comisión: *el motor conversacional es agnóstico al canal; lo demostramos con el
canal web, y WhatsApp queda como extensión documentada porque su habilitación depende de un
trámite con Meta que no controlamos.*
