# ADR 0001 — Dónde se despliega la plataforma

- **Estado:** ejecutado · todo en Vercel + Supabase · falta decidir dónde corre el chat en vivo con WebSocket
- **Fecha:** 4 de septiembre de 2026 · **revisado:** 22 de septiembre y 16 de octubre de 2026
- **Decide:** el equipo

## Estado al 16 de octubre de 2026

Lo que está en producción, y que reemplaza la propuesta de más abajo (Render, Neon, Upstash):

| Pieza | Dónde | Dirección |
|---|---|---|
| Frontend (React + Vite) | Vercel | `frontend-one-liart-11.vercel.app` |
| API (FastAPI) | Vercel, como función de Python | `backend-nine-coral-58.vercel.app` |
| Base de datos | Supabase, PostgreSQL 17 + pgvector, pooler de sesión | — |
| Proveedor de modelo | Groq, `openai/gpt-oss-120b`, con un proveedor de respaldo | — |

La contradicción entre Render y Azure quedó resuelta en los hechos: ninguno de los dos. La API
terminó en Vercel porque se cambió lo que la dejaba fuera:

- **Sin worker ni Redis.** `WORKERS_INLINE=true`: las tareas de fondo (ingesta, sugerencias,
  reindexado) corren dentro de la misma petición. El escaneo del sitio avanza **por tandas** de 20 s (`SCAN_BATCH_SECONDS`) y
  guarda en qué va, para no pasar el tiempo máximo de una función.
- **Sin WebSocket.** El chat público y la consola del ejecutivo intentan abrir el WebSocket y, si no
  pueden, consultan lo nuevo cada pocos segundos. Así la derivación a una persona funciona en
  Vercel, con algo más de demora que en local.
- **La clave del proveedor viaja en variables de entorno** (`LLM_PLATFORM_API_KEY`, `LLM_FALLBACK_API_KEY`).
  Después de un límite de uso (429) se saltan por 60 s los pasos auxiliares del motor, para no
  agotar la cuota.

**Lo que sigue sin funcionar en Vercel**, porque escribe en disco y el disco de una función es de
solo lectura:

- Subir archivos PDF, Word o de texto (`POST /company/documents` guarda el original con
  `STORAGE_BACKEND=local`). La alternativa ya programada es Azure Blob Storage, sin credenciales.
  Mientras tanto, la base de conocimiento de producción se carga con preguntas frecuentes, el
  escaneo del sitio y documentos de texto escritos en el panel (`POST /company/documents/text`),
  que no pasan por disco. Así se cargaron, por la API, las mallas de Duoc UC.
- Que una empresa guarde su propia clave del proveedor (`SECRETS_BACKEND=env`, archivo cifrado en
  `var/`). Todas usan la clave compartida de la plataforma.

**Pendiente:**

- `API_BASE_URL` en Vercel sigue en `http://localhost:8000`, así que el chat público intenta abrir
  el WebSocket contra `ws://localhost:8000` antes de pasar a consultar. No rompe nada, pero
  ensucia la consola del navegador. Se arregla poniendo la URL de la API en esa variable.
- Si el chat en vivo instantáneo es parte de la demo, hace falta un host con procesos largos
  (Render, Railway o Azure) para la parte de WebSocket. La alternativa es defender la consulta
  periódica como suficiente para la v1.
- CORS sigue abierto a cualquier origen (ver más abajo).

Lo que sigue es la historia de la decisión, tal como se escribió en septiembre.

## Qué cambió desde que se escribió esto (22 de septiembre)

Tres semanas después, parte de la propuesta ya ocurrió y parte quedó contradicha. Conviene
leerlo antes del resto del documento, porque cambia la conversación que falta tener.

**El frontend ya está desplegado en Vercel.** Funciona. El proyecto estaba configurado con la
raíz apuntando a `recursos/proyecto/frontend`, que es una ruta de la estructura anterior del
repositorio y no existe, así que **ningún despliegue había llegado nunca a compilar**: todos
morían en `build-container-init`. Corregida la raíz a `proyecto/frontend`, compila en ocho
segundos.

**La base de datos ya no está por decidir: es Supabase.** Este documento ofrecía "Neon o
Supabase"; en los hechos se levantó Supabase, con PostgreSQL 17.6 y `pgvector` 0.8.2, y el
backend conecta contra ella por el *pooler de sesión*. Dos detalles que costaron tiempo y
conviene dejar escritos: la **conexión directa de Supabase es solo IPv6** y no resuelve desde
cualquier red, y el **pooler transaccional del puerto 6543 rompe con `asyncpg`**, porque
PgBouncer en modo transacción no admite sentencias preparadas. Hay que usar el pooler de sesión,
puerto 5432, y el prefijo `postgresql+asyncpg://`.

**Había un proyecto de Vercel para el backend.** Estaba conectado al repositorio y fallaba en
cada push, ensuciando los chequeos de todos los PR con un rojo que no significaba nada. Quedó
apagado, no borrado: sin despliegues de vista previa y con el paso de compilación saltado. Se
revierte cuando se decida dónde vive la API. Desplegar esta API en Vercel sigue sin ser viable,
por los motivos de la sección siguiente.

**Y hay una contradicción que alguien tiene que resolver.** Este ADR propone Render. El
documento de planificación de roles le asigna a Manuel *"despliegue en Azure"* en la semana 6 y
*"despliegue estable"* en la 7. Las dos cosas no pueden ser ciertas. Como el despliegue es área
de Manuel, la decisión es suya, pero tiene que quedar escrita en un solo lugar.

## Contexto

La planificación de la Fase 1 asumía una VPS propia con Docker Compose. Esa decisión ya no se
sostiene: nadie del equipo quiere administrar un servidor durante el semestre, y el proyecto
recibido trae referencias a Azure que tampoco tenemos contratado.

**Vercel** aparece como opción. Conviene separar el problema en dos, porque la respuesta no es
la misma para las dos mitades.

## El frontend sí cabe en Vercel

`proyecto/frontend/` es una SPA de **React 18 + Vite** que compila a estáticos. Es el caso de uso
exacto de Vercel: se conecta el repositorio de GitHub, se define `proyecto/frontend` como raíz
del proyecto, `npm run build`, salida en `dist/`, y cada push a `main` despliega. El plan Hobby
alcanza de sobra y da HTTPS y dominio.

Hay que mover al build tres cosas que hoy resuelve el proxy de Vite (`vite.config.js`):

- `VITE_API_URL` apuntando al host real de la API.
- Las llamadas a `/api` dejan de ir por proxy: van a esa URL absoluta.
- El WebSocket (`/ws/chat/...` y `/ws/agent`) igual, con esquema `wss://`.

Y en la API hay que abrir CORS al dominio de Vercel.

## El backend NO cabe en Vercel

Vercel ejecuta funciones serverless. Tres cosas del backend no funcionan ahí:

1. **WebSockets.** La consola de agente y el chat en vivo son `@router.websocket`. Las funciones
   serverless de Vercel no mantienen conexiones persistentes. Sin esto se cae la Fase 4 completa,
   que es la mejor cubierta por tests y una de las más vistosas en la demo.
2. **El worker `arq`.** La ingesta de documentos y el escaneo de sitios corren en un proceso
   aparte, permanente, que consume una cola de Redis. No hay dónde vivir en Vercel.
3. **PostgreSQL con pgvector.** Vercel no lo hospeda; hay que contratarlo aparte de todos modos.

## Alternativas para la API

| Opción | A favor | En contra |
|---|---|---|
| **Render** | Docker directo, WebSockets, un *background worker* para `arq`, plan gratuito | El plan gratuito duerme el servicio tras 15 min de inactividad, malo para una demo en vivo |
| **Railway** | Despliega el `docker-compose` casi tal cual, incluido Redis | Créditos limitados en el plan de entrada |
| **Fly.io** | Contenedores con WebSockets, buen rendimiento | Más configuración; pide tarjeta |
| **Azure Container Apps** | Es lo que la especificación del cliente propone | Sin suscripción; escalar a cero corta los WebSockets |

Servicios de datos, en cualquiera de los casos:

- **PostgreSQL + pgvector:** Neon o Supabase, ambos con `pgvector` disponible en plan gratuito.
- **Redis:** Upstash (plan gratuito) o el Redis administrado del propio host.

## Propuesta

**Frontend en Vercel + API y worker en Render + Postgres en Neon + Redis en Upstash.**

Es la combinación que sostiene los WebSockets y el worker sin tarjeta de crédito. El costo es el
arranque en frío del plan gratuito de Render: se mitiga despertando el servicio unos minutos
antes de cada demo, o subiendo al plan pago el mes de la defensa.

## Consecuencias

- ~~Hay que escribir un `vercel.json` con el *rewrite* del ruteo de React Router.~~ **Hecho.**
  Está en `proyecto/frontend/vercel.json`. Sin él, entrar a `/company/documents` y recargar
  devolvía 404, porque esa ruta la resuelve React Router en el navegador y no existe como
  archivo. Vercel sirve primero los archivos que existen, así que `widget.js` y los estáticos
  no se ven afectados por la reescritura.
- Hay que parametrizar `VITE_API_URL` y `VITE_PUBLIC_BASE` en las variables de entorno de Vercel.
  `VITE_API_URL` no se puede completar hasta que exista una API desplegada; mientras tanto el
  sitio carga y se ve, pero el login falla, porque las llamadas a `/api/v1/...` pegan contra el
  propio dominio de Vercel y dan 404.
- **El backend también necesita su propia URL pública en `API_BASE_URL`.** El chat público
  devuelve `ws_base_url` derivándolo de esa variable, así que si queda en `http://localhost:8000`
  el widget intentará abrir el WebSocket contra la máquina del visitante. Es el tipo de detalle
  que aparece el día de la demo y no antes.
- El widget embebible y el enlace único de chat quedan bajo el dominio de Vercel: eso hay que
  reflejarlo en la pantalla "Canales y enlace".
- La CI de GitHub Actions sigue corriendo `ruff` y `pytest`; el despliegue lo hacen los propios
  hosts al detectar el push.

## Dos cosas que conviene revisar antes de la defensa

**CORS está abierto a cualquier origen.** `app/main.py` usa
`allow_origin_regex=r"https?://.*"` junto con `allow_credentials=True`. Esto no es un descuido
del todo: el widget tiene que poder embeberse en el sitio de cualquier empresa cliente, y los
endpoints públicos validan el `Origin` contra los dominios autorizados de cada tenant. Pero deja
igual de abiertos los endpoints de administración. No lo cambiamos por cuenta propia porque
restringirlo puede romper el widget; hay que decidirlo con la regla en la mano.

**La protección SSO de Vercel está activada.** Para ver el sitio hay que tener sesión en Vercel
y pertenecer al equipo. Si la demo con Max o con el profesor guía se hace por enlace, no van a
poder entrar. Se quita en Settings → Deployment Protection, y es una decisión consciente porque
abre el sitio al público. **Al 16 de octubre ya está quitada:** el sitio y la API se abren sin
sesión de Vercel.

## Pendiente (22 de septiembre; resuelto, ver «Estado al 16 de octubre»)

Confirmar el host de la API antes de la primera demo con la aplicación desplegada, y zanjar la
contradicción entre este documento y la planificación de roles.

La recomendación de quien escribe esta revisión es **desplegar temprano y a medias antes que
tarde y perfecto**: si se espera a la semana 6, los problemas de despliegue —CORS, el WebSocket
sobre `wss://`, las variables de entorno, el arranque en frío— van a aparecer a tres semanas de
la defensa y con todo lo demás encima. Render sirve para eso esta semana, sin tarjeta. Si Manuel
consigue **Azure for Students**, que son cien dólares sin tarjeta, la semana 6 se migra y este
ADR se cierra con Azure, que además es lo que la especificación del cliente propone y lo que el
código ya contempla con Blob Storage y Key Vault.
