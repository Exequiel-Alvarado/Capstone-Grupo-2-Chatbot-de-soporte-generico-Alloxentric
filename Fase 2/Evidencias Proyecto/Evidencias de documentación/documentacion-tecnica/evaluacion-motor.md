# Evaluación del motor de Exequiel

El comando evalúa el clasificador y la recuperación que usa el motor contra la base
configurada en `backend/.env`. No genera respuestas, no llama a DeepSeek y no modifica
documentos ni conversaciones. Con embeddings Azure sí realiza consultas al proveedor
de embeddings configurado.

## Preparar el banco con Cristian

1. Cargar documentos reales de cada piloto y comprobar que estén indexados.
2. Definir preguntas técnicas y comerciales representativas, también en ES/EN/PT.
3. Etiquetar el agente esperado y todos los chunks relevantes antes de ejecutar la evaluación.
   Si el comercial está desactivado, la ruta esperada es técnica.
4. Reservar preguntas para validación que no se usen al ajustar el clasificador.

Guardar un arreglo JSON con este formato; los identificadores siguientes son ejemplos
y deben reemplazarse por los de la base evaluada:

```json
[
  {
    "id": "piloto-1-tecnico-001",
    "tenant_slug": "slug-del-piloto",
    "question": "¿Cómo recupero mi contraseña?",
    "expected_agent": "technical",
    "relevant_chunk_ids": ["00000000-0000-0000-0000-000000000001"]
  }
]
```

Los chunks se pueden consultar en la base con una consulta parametrizada:

```sql
SELECT c.id, c.source_name, c.chat_type, c.content
FROM chunks c JOIN tenants t ON t.id = c.tenant_id
WHERE t.slug = :tenant_slug;
```

No usar nombres de archivo como identificador: pueden repetirse. Al reindexar,
revisar las etiquetas porque los IDs de chunks cambian. El evaluador rechaza IDs
que no existen o pertenecen a otra empresa, bancos vacíos y casos con ID repetido.

Para que el banco no dependa de los IDs, cada caso puede nombrar sus pasajes correctos por
fuente y una frase que contienen. Las FAQ tienen como fuente «FAQ»; la frase las distingue.
`language` (`es`, `en` o `pt`) es opcional y agrega el desglose `by_language`:

```json
{
  "id": "directa-es-02", "tenant_slug": "directa", "language": "es",
  "question": "La luz de internet del módem está en rojo", "expected_agent": "technical",
  "relevant": [{"source": "FAQ", "contains": "luz del router está roja"},
               {"source": "Manual del router Directa X200", "contains": "Internet roja"}]
}
```

El evaluador rechaza una referencia que no encuentra ningún chunk: así una etiqueta vieja no
cuenta como fallo de la búsqueda.
Los casos sin respuesta documental se evalúan aparte: este banco exige al menos
un chunk relevante para que recall tenga denominador válido.

## Ejecutar

Desde `proyecto/backend`, con las dependencias del motor instaladas:

```powershell
.venv-motor/Scripts/python.exe -m scripts.evaluate_motor ../docs/evaluaciones/banco.json --output ../docs/evaluaciones/resultado.json
```

El backend de embeddings debe coincidir con el usado para indexar. Si se cambia,
hay que reindexar antes de medir. El evaluador rechaza `hash` salvo que se agregue
`--allow-hash`; en ese caso el informe lleva `test_embeddings: true` y solo demuestra
el funcionamiento del evaluador. No representa calidad semántica real.

## Interpretar

- `accuracy`: proporción de consultas enrutadas al agente esperado.
- Matriz de confusión: filas = etiqueta esperada; columnas = predicción.
- `mean_recall_at_5`: media por pregunta de chunks relevantes recuperados entre los
  cinco primeros, divididos por todos los chunks etiquetados como relevantes.
  Incluye el efecto de una clasificación incorrecta sobre la recuperación.
- `hit_rate_at_5`: proporción de preguntas con al menos un pasaje correcto entre los cinco
  primeros. Es el criterio de SCRUM-145 (80 %).
- `retrieval_ms`: media, p50 y p95 por rango más cercano. Incluye embeddings y consulta
  de recuperación; excluye clasificación y generación de la respuesta.
- `classification_ms`: duración de clasificación por caso en `results`.
- `by_tenant`: métricas separadas por piloto; el resumen global pondera cada pregunta
  por igual y no cada empresa.

La ejecución es secuencial, una consulta por caso y sin calentamiento automático.
Anotar tamaño del banco, entorno, backend de embeddings y fecha al comparar informes.
El archivo de salida omite preguntas y contenido documental, pero contiene IDs y slugs.
Este informe no mide calidad de la respuesta, latencia completa del chat ni concurrencia.
La aceptación y el etiquetado independiente corresponden a Cristian.

## Banco de la simulación

`docs/evaluaciones/banco-simulacion.json` tiene 40 preguntas sobre las cuatro empresas
simuladas, dichas con otras palabras que sus FAQ, cada una en español, inglés y portugués
(120 casos). Se corre sin base propia:

```powershell
python -m scripts.evaluar_simulacion --output ../docs/evaluaciones/resultado-simulacion.json
```

El script crea `var/evaluacion-simulacion.db`, carga los documentos y las FAQ de
`simulacion_contenido.py` (sin las páginas web) y evalúa. `tests/test_banco_simulacion.py`
comprueba en la CI que todas las etiquetas sigan encontrando su pasaje.

Primera medición, 9 de octubre de 2026, con embeddings `hash` (los de producción):

| | Clasificación | Acierto en 5 | Recall en 5 |
|---|---|---|---|
| Total (120) | 74,2 % | 34,2 % | 21,9 % |
| Español | 75,0 % | 60,0 % | 42,1 % |
| Inglés | 77,5 % | 20,0 % | 11,2 % |
| Portugués | 70,0 % | 22,5 % | 12,5 % |

Lectura:

- **Ni la clasificación (meta 90 %) ni la recuperación en español (meta 80 %) llegan.**
- De los 16 fallos en español, 10 son preguntas comerciales que el clasificador manda al
  agente técnico: «¿cuánto vale Xentric al mes?», «¿dónde puedo pagar la cuenta?», «¿el
  contrato incluye soporte?». El técnico no busca en el conocimiento comercial y no encuentra
  el pasaje. Mejorar el clasificador (DUCG2-23) sube las dos métricas.
- En inglés y portugués la búsqueda casi no encuentra nada: con `hash` la búsqueda compara
  palabras y el contenido está en español. Es lo que tiene que resolver el spike de embeddings
  reales (DUCG2-10).
- Este banco lo armó el mismo autor del motor. Antes de ajustar el clasificador con él, conviene
  separar preguntas de validación y que Cristian etiquete un banco independiente.

### Segunda medición: clasificador con vocabulario completo (SCRUM-119)

El banco se partió en dos mitades (`split`): **ajuste**, que se miró para mejorar las reglas,
y **validacion**, que no se miró hasta el final. Las tres traducciones de una pregunta caen en
la misma mitad, para que la de validación no sea una versión ya vista de una de ajuste.

Las reglas se completaron por familias de palabras en los tres idiomas (precio, pago,
contrato, plan, prueba gratis, ventas), no con las palabras de las preguntas que fallaban.
El evaluador mide reglas y temas, **sin el modelo** (`usar_modelo=False`): no gasta tokens ni
depende de un proveedor externo, así que lo que agregue el modelo no está en estas cifras.

| | Antes | Después |
|---|---|---|
| Clasificación, mitad de validación | 68,3 % | **81,7 %** |
| Clasificación, mitad de ajuste | 80,0 % | 93,3 % |
| Clasificación, total | 74,2 % | 87,5 % |
| Acierto en 5, español | 60,0 % | 67,5 % |

Lo que sigue fallando en validación son preguntas sin ninguna palabra comercial («¿trabajan
con bancos?», «¿en cuánto tiempo queda funcionando?», «¿atienden en España?»). Es lo que
resuelven los temas de cada empresa y la consulta al modelo; para medirlos hace falta cargar
temas en la simulación y correr con un proveedor. «¿Cuánto vale…?» y «¿cuánto sale…?» también
fallan, pero no se agregaron a las reglas: se vieron en la mitad de validación, y agregarlas
inflaría la cifra.

### Tercera medición: con los temas de cada empresa

Los agentes de la simulación ahora tienen temas (`simulacion_contenido.py`, clave `temas`),
sacados de los títulos de sección de los documentos de cada empresa, como los escribiría su
admin. `--sin-temas` mide como antes.

| Validación, sin el modelo | Sin temas | Con temas |
|---|---|---|
| Clasificación, total | 81,7 % | 83,3 % |
| Clasificación, español | 75 % | 80 % |

Ayudan poco porque la comparación es por palabras: «¿trabajan con bancos?» no dice
«industrias», y los temas están en español, así que no ayudan con preguntas en inglés o
portugués. Ese hueco es el del modelo, que recibe los temas en el prompt. Con temas, el
acierto en 5 en español queda en 70 % (empezó en 60 %).

Los temas los escribió la misma persona que armó el banco; lo ideal es que otro integrante
escriba los de una empresa sin mirar las preguntas.

### Cuarta medición: WellQ con su contenido real

Las 12 preguntas de WellQ del banco se reescribieron porque su contenido cambió (SCRUM-189):
ahora preguntan por su plataforma real, con otras palabras que sus FAQ nuevas. Son preguntas que
el clasificador no había visto, y bajan las cifras: clasificación en validación 78,3 %, acierto en
5 en español 62,5 %. Las de WellQ que fallan son paráfrasis sin palabras en común con su FAQ
(«¿puedo probarlo sin pagar?» frente a «prueba gratis»): el límite de la búsqueda léxica con
`hash`. No se tocaron las FAQ para que calcen con el banco.
