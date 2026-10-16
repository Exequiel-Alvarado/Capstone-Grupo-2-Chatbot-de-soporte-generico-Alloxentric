# Evidencias de sistema / aplicación (Fase 2)

**Proyecto:** Chatbot de Soporte Genérico (Alloxentric). Capstone Grupo 2, Duoc UC.
**Fecha de captura:** 16-10-2026
**Entorno:** producción

| Componente | URL |
|---|---|
| Frontend (aplicación web) | https://frontend-one-liart-11.vercel.app |
| Backend (API REST) | https://backend-nine-coral-58.vercel.app/api/v1 |

## Índice de capturas

| N° | Archivo | Qué muestra | Cuenta usada | Requisito o historia de usuario que evidencia |
|---|---|---|---|---|
| 1 | `01-portada-directorio-empresas.png` | Portada pública (`/`) con la propuesta del producto (aprende de los documentos, deriva a una persona, dos agentes) y el directorio de las 6 empresas con chat activo. Arriba, el selector ES/EN/PT y el botón de modo oscuro. | Sin sesión (público) | Multiempresa; acceso público al chat de cada empresa |
| 2 | `02-login.png` | Inicio de sesión único del módulo de administración (`/login`). | Sin sesión | Autenticación y acceso según rol |
| 3 | `03-plataforma-dashboard-global.png` | Dashboard global (`/platform`): conversaciones, % resuelto por el bot, derivadas a agente y tokens del modelo de los últimos 7 días, con la actividad desglosada por empresa. | `root@alloxentric.com` (admin de plataforma) | Multiempresa; métricas de uso y consumo de tokens por empresa |
| 4 | `04-plataforma-empresas-cliente.png` | Empresas cliente (`/platform/tenants`): API key, base de conocimiento (documentos, FAQ, sitio), enlace de chat, estado y botón «Gestionar». | `root@alloxentric.com` | Multiempresa (alta y gestión de empresas cliente) |
| 5 | `05-plataforma-ficha-empresa-duoc.png` | Ficha de Duoc UC abierta con «Gestionar»: estado Activo, razón social, idioma, proveedor y modelo, bots por canal y botón «Desactivar empresa» (solo se muestra, no se pulsó). | `root@alloxentric.com` | Gestión del ciclo de vida de la empresa cliente (activar o desactivar) |
| 6 | `06-directa-dashboard-empresa.png` | Dashboard de la empresa (`/company`): conversaciones, resueltas por el bot, tickets pendientes, derivadas a agente, tokens consumidos (% del límite), chat de prueba empotrado y temas más consultados. | `admin@directa.cl` (admin de Directa) | Métricas por empresa; probar el chatbot desde el panel |
| 7 | `07-duoc-documentos.png` | Documentos del cliente (`/company/documents`): carga de PDF, DOCX, TXT y MD, tipo de chat (técnico, comercial o ambos), estado «Indexado» y fragmentos de cada documento. | `duoc@demo.cl` (admin de Duoc UC) | Base de conocimiento: documentos |
| 8 | `08-duoc-sitio-web-escaneo.png` | Pestaña «Sitio web»: URL de duoc.cl, último escaneo completado (200 páginas) y reglas de qué escanear. | `duoc@demo.cl` | Base de conocimiento: escaneo del sitio web |
| 9 | `09-duoc-sitio-web-paginas-indexadas.png` | Páginas indexadas del sitio (172), con fecha de escaneo, tamaño y origen («Del sitio» o «Editado a mano»). | `duoc@demo.cl` | Base de conocimiento: escaneo del sitio web |
| 10 | `10-duoc-agentes-del-bot.png` | Agentes del bot (`/company/bot-agents`): agente técnico («Orientación académica Duoc UC») y comercial («Admisión y aranceles Duoc UC»), con temas, prompt personalizado y métricas de 7 días. | `duoc@demo.cl` | Motor RAG con dos agentes (técnico y comercial) |
| 11 | `11-duoc-cadena-de-prompts.png` | «Ver lo que recibe la IA»: la cadena de prompts del agente técnico. Tiene tres pasos: 1. Generar la respuesta, 2. Verificar (aprobada, sin sustento o fuera de alcance) y 3. Reglas del negocio. | `duoc@demo.cl` | Motor RAG: respuesta generada y verificada contra la documentación |
| 12 | `12-directa-tickets.png` | Tickets (`/company/tickets`) con usuario, tema, tipo, prioridad, estado, ejecutivo asignado, fecha de creación y de resolución, y sus filtros. | `admin@directa.cl` | Derivación a humano: tickets |
| 13 | `13-directa-ejecutivos.png` | Agentes humanos (`/company/human-agents`): ejecutiva técnica y ejecutivo comercial, con canal, estado y carga (en vivo y tickets). | `admin@directa.cl` | Derivación a humano: ejecutivos por tipo de consulta |
| 14 | `14-chat-duoc-ramos-tercer-semestre.png` | Chat público de Duoc UC (`/c/duoc`). Pregunta: «¿Qué ramos tiene el tercer semestre de Ingeniería en Informática mención Desarrollo de Software?». La respuesta trae los 4 ramos con sus siglas. | Público (sin sesión) | Chat público; el motor RAG responde con la base de conocimiento |
| 15 | `15-chat-duoc-certificaciones.png` | En la misma conversación: «¿Qué certificaciones obtengo en Ingeniería en Desarrollo de Software?». Responde con las 3 certificaciones (FullStack, Aplicaciones Móviles y Cloud Native) y sus asignaturas. | Público (sin sesión) | Motor RAG; memoria de la conversación |
| 16 | `16-chat-directa-plan-fibra.png` | Chat público de Directa (`/c/directa`). Pregunta: «¿Cuánto cuesta el plan de fibra óptica?». Responde con los planes de 300, 600 y 1000 Mbps y sus precios. | Público (sin sesión) | Multiempresa: cada empresa responde con su propia base de conocimiento |
| 17 | `17-consola-ejecutivo-en-vivo.png` | Consola del ejecutivo (`/console`): bandeja con «En vivo (1)» y «Tickets (7)», una conversación derivada con su historial bot-usuario, el motivo de la derivación, los datos del usuario y las acciones Tomar, Devolver al bot y Resolver. | `tecnico@directa.cl` (ejecutiva de Directa) | Derivación a humano con el contexto de la conversación |
| 18 | `18-consola-ejecutivo-ticket.png` | En la consola, el ticket #T-1002 asignado a la ejecutiva, con su conversación y contexto. | `tecnico@directa.cl` | Derivación a humano: atención de tickets |
| 19 | `19-panel-ingles-modo-oscuro.png` | Dashboard de Directa en inglés y modo oscuro, incluido el chat empotrado. | `admin@directa.cl` | Interfaz ES/EN/PT y modo oscuro |
| 20 | `20-tickets-ingles-modo-oscuro.png` | Tickets en inglés y modo oscuro, con estados, prioridades y tipos traducidos. | `admin@directa.cl` | Interfaz ES/EN/PT y modo oscuro |
| 21 | `21-movil-chat-duoc.png` | Chat público de Duoc UC en un teléfono (390 × 844, página completa) con la conversación de las capturas 14 y 15. | Público (sin sesión) | Diseño adaptable a móvil |

## Cómo se tomaron

- Chrome automatizado con Playwright, ventana de 1440 × 900 e idioma es-CL. La vista móvil usa 390 × 844.
- Solo se navegó y se leyó: no se cambió ninguna configuración, documento, agente ni usuario. Las únicas escrituras fueron tres preguntas en los chats públicos (dos a Duoc UC y una a Directa) y la conversación vacía que abre el chat de prueba del dashboard de Directa.
- El idioma y el modo oscuro se cambiaron en el navegador. Es una preferencia local que no se guarda en la cuenta.
- En la consola no se pidieron las respuestas sugeridas por IA, para no gastar tokens del modelo. Por eso el panel muestra «Sin sugerencias por ahora».
