# Datos simulados: las cuatro empresas iniciales

Para ver la plataforma funcionando de punta a punta hacen falta empresas con conocimiento y con
actividad. `scripts/seed_simulacion.py` carga los cuatro clientes iniciales del proyecto
(README: WellQ, Alloxentric, Directa y Dani27001) con su conocimiento y un mes de conversaciones.

**Producción ya está cargada** desde el 9 de octubre de 2026.

## De dónde sale cada cosa

| Empresa | Sitio | Conocimiento | Qué es (para la demo) |
|---|---|---|---|
| **WellQ** | [wellq.co.uk](https://www.wellq.co.uk), real | 6 páginas reales del sitio, 12 FAQ y 2 documentos «(demo)» sobre su negocio real | Plataforma de salud musculoesquelética para clínicas (real) |
| **Alloxentric** | [alloxentric.com](https://alloxentric.com), real | 12 páginas reales del sitio, 10 FAQ y 2 documentos sintéticos marcados «(demo)», sin precios | Plataforma de comunicaciones Xentric |
| **Directa** | No tiene: `directa.cl` es un dominio en venta | 10 FAQ y 3 documentos sintéticos | Proveedor de internet y telefonía (inventado) |
| **Dani27001** | No tiene | 8 FAQ y 3 documentos sintéticos; **agente comercial desactivado** | Mesa de ayuda TI para pymes (inventada) |

**WellQ es real.** Hasta el 9 de octubre de 2026 sus FAQ hablaban de una consultora de salud
ocupacional inventada, que no calzaba con su sitio (una plataforma de salud musculoesquelética
para clínicas). Ahora su contenido sale de su sitio: planes Core, Pro y Enterprise, prueba gratis
de 3 meses, wearables Apple, Oura y WHOOP, dirección y correo. El uso paso a paso (invitar un
paciente, asignar ejercicios) es verosímil y va en documentos marcados «(demo)»; no hay precios ni
plazos inventados. Una base que ya tenía el contenido viejo se pasa al nuevo con
`python -m scripts.actualizar_wellq`.

Cada empresa trae además **«Sobre la empresa»** (`sobre` en `scripts/datos/simulacion/<empresa>/empresa.json`), que el bot
recibe en sus instrucciones. Las de WellQ y Alloxentric dicen solo lo que dicen sus sitios.

Las páginas reales se bajaron **respetando su robots.txt y su `Crawl-delay` de 10 segundos**. El
escáner del producto todavía no respeta `Crawl-delay`; por eso la simulación usa su propio lector.

## Actividad simulada

Por empresa, 30 días de conversaciones (25 a 60) que preguntan lo que cubren sus FAQ, más algunas que
el bot no sabe responder:

- **resueltas por el bot**, la mayoría con valoración;
- **abandonadas**;
- **derivadas a un ejecutivo** que las atendió en vivo;
- **convertidas en ticket**, abiertos, pendientes o resueltos, con prioridad y a veces asignados;
- **dos esperando en la cola**, recientes, para que aparezcan en la consola del ejecutivo.

Los tickets resueltos traen quién y cuándo los resolvió, la respuesta del ejecutivo y el aviso
al usuario, como los deja `services/tickets.py`. Los agentes del bot traen **temas** (los
títulos de sección de sus documentos), que usa el clasificador técnico/comercial.

Cada respuesta del bot registra su consumo de tokens. Así se llenan el dashboard de cada empresa
(conversaciones, porcentaje resuelto por el bot, derivaciones, tickets, tokens y temas frecuentes), el
dashboard de plataforma y la cola de la consola.

Las conversaciones llevan `page_url = simulacion://capstone`.

## Usuarios

Contraseña: *omitida en esta copia de evidencias*. Los de WellQ ya existían (ver `entorno-de-prueba.md`).

| Usuario | Empresa | Rol |
|---|---|---|
| `admin@alloxentric.com` | Alloxentric | Admin de empresa |
| `tecnico@alloxentric.com` | Alloxentric | Ejecutivo técnico |
| `comercial@alloxentric.com` | Alloxentric | Ejecutivo comercial |
| `admin@directa.cl` | Directa | Admin de empresa |
| `tecnico@directa.cl` | Directa | Ejecutivo técnico |
| `comercial@directa.cl` | Directa | Ejecutivo comercial |
| `admin@dani27001.cl` | Dani27001 | Admin de empresa |
| `tecnico@dani27001.cl` | Dani27001 | Ejecutivo técnico |

Los ejecutivos entran desconectados: para recibir derivaciones en vivo tienen que marcarse como
disponibles en su consola.

## Cargar y quitar

Desde `backend`, con la base migrada, `seed_demo.py` y `seed_wellq_faqs.py` ya corridos:

```
python -m scripts.seed_simulacion             # carga (baja los sitios: unos 3 minutos)
python -m scripts.seed_simulacion --sin-web   # carga sin bajar los sitios
python -m scripts.seed_simulacion --borrar    # deshace todo
```

**Es reversible.** Cada fila que crea queda anotada en `local/simulacion-registro-<huella>.json`
(uno por base de datos; `local/` no se versiona). `--borrar` lo deshace:

- a WellQ, que ya existía, le quita solo lo agregado y le devuelve su URL anterior;
- las empresas que creó las borra enteras.

Repetir la carga no duplica nada.

El registro de **producción** está en el equipo de Exequiel. Sin ese archivo, `--borrar` no sabe qué
quitar de WellQ.

Las conversaciones se generan con una semilla fija: cada carga produce los mismos datos, con las
fechas corridas al día en que se carga.
