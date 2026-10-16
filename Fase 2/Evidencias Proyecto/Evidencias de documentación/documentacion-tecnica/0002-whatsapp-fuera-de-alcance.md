# ADR 0002 — WhatsApp queda fuera de la v1

- **Estado:** aceptado
- **Fecha:** 4 de septiembre de 2026
- **Decide:** el equipo

## Contexto

El documento del cliente (§3.1) pone el **canal WhatsApp** dentro del alcance: el bot debe
responder por WhatsApp mediante la API oficial de WhatsApp Business, aunque los agentes humanos
atiendan solo por chat web. El proyecto recibido trae ese canal implementado: 4 endpoints —dos de
webhook con verificación de firma y dos para conectar y desconectar el número— sobre
`app/services/whatsapp.py`, que llama a la Meta Graph API.

Que el código exista no significa que el canal se pueda demostrar.

## Por qué sale

1. **La habilitación no depende del equipo.** WhatsApp Business Cloud API exige una cuenta de
   Meta Business verificada, un número dedicado y la aprobación de plantillas de mensaje. El
   trámite toma semanas y lo resuelve Meta, no nosotros. Un entregable cuya fecha de
   disponibilidad decide un tercero no puede estar en el camino crítico de una defensa de título.
2. **El número de prueba no sirve de demo real.** El *sandbox* de Meta permite un puñado de
   destinatarios registrados a mano: alcanza para un video, no para "el chatbot atiende a los
   usuarios finales de WellQ".
3. **No agrega capacidad al motor.** WhatsApp es una segunda puerta de entrada al mismo motor
   conversacional. La tesis del proyecto —multi-tenant, dos agentes especializados, RAG sobre el
   conocimiento de cada empresa, derivación a humano— se demuestra entera por el canal web.
4. **Lo que sí falta medir compite por el mismo tiempo.** El clasificador de intención es una
   heurística de palabras clave sin métrica, no hay set de preguntas de prueba y no hay
   despliegue. Con una sola persona programando, esas tres brechas valen más que un canal extra.

## Decisión

La v1 se define y se defiende como **plataforma de soporte por chat web** (enlace único + widget
embebible).

El código de WhatsApp **no se borra**: queda en el repositorio, inactivo, como extensión
documentada. Borrarlo destruye trabajo hecho y no aporta nada; dejarlo permite mostrar en la
defensa que el motor es agnóstico al canal.

## Consecuencias

- La pantalla "Canales y enlace" del módulo de administración muestra WhatsApp como **no
  disponible en esta versión**, no como error de conexión.
- Los documentos académicos, la presentación y los diagramas dicen "chat web" donde antes decían
  "web y WhatsApp".
- El objetivo específico 4 del documento del cliente queda cumplido a medias, y así se declara en
  [`../alcance.md`](../alcance.md): honestidad de alcance en vez de una casilla marcada de más.
- Si Alloxentric consigue la verificación de Meta durante el semestre, reactivar el canal es
  configuración —conectar el número desde la propia pantalla de canales—, no desarrollo.

## Alternativa descartada

*Dejar WhatsApp dentro y "ya veremos".* Es lo que estaba pasando: el canal figuraba como alcance
en los entregables sin que nadie hubiera iniciado el trámite. Sostener un alcance que no se va a
cumplir es peor que recortarlo con una razón escrita.
