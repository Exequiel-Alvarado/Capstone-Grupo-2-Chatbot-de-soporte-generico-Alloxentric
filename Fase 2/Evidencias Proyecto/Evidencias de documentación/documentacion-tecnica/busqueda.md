# Búsqueda del motor: embeddings, umbral de relevancia y clasificador

Qué cambió el 9 de octubre de 2026 y por qué. El origen es una prueba contra el bot desplegado:
respondía bien, pero tenía tres fallas (secciones 1 a 3). La sección 4 es una cuarta, encontrada
el 16 de octubre con la base de conocimiento de Duoc UC.

## 1. Producción usa embeddings `hash`

Mirando un vector guardado en la base de producción: 110 de 1536 valores distintos de cero. Es el
embedding `hash` de desarrollo, no uno real (Azure no está configurado). La búsqueda es **por
palabras, no por significado**: «se me olvidó la contraseña» no encuentra un texto que dice «clave».

Mientras no haya un proveedor de embeddings, se mejoró el `hash` (`services/embeddings.py`):

| Antes | Ahora |
|---|---|
| Cortaba por espacios: «¿cómo», «cómo» y «como» eran palabras distintas | Minúsculas, **sin tildes ni signos** |
| Contaba «de», «el», «es», «la»… | **Sin palabras vacías** en español, inglés y portugués |

Las palabras vacías eran el problema mayor: hacían que **cualquier pregunta se pareciera a
cualquier texto**. «¿Cuál es el horario del metro de Santiago?» sacaba tanto puntaje como una
pregunta real del negocio.

**Al desplegarlo hay que recalcular los vectores ya guardados**, que quedan con el cálculo viejo:
`python -m scripts.reembeber_fragmentos`. Hasta correrlo, la búsqueda en producción se degrada.

**Lo que sigue siendo un límite:** con `hash` no hay sinónimos. Para eso hacen falta embeddings
reales (Azure OpenAI, configurado con `EMBEDDINGS_BACKEND=azure_openai`), recalibrar el umbral y
volver a correr `reembeber_fragmentos`.

## 2. La búsqueda no tenía umbral de relevancia

Siempre devolvía los 5 fragmentos más parecidos, sirvieran o no. Consecuencias:

- El bot **nunca contaba un fallo**, porque «sin fuentes» solo pasaba si la empresa no tenía
  ningún documento. La regla «derivar a una persona tras dos fallos» **no se activaba nunca**.
- El modelo recibía pasajes que no tenían nada que ver.

Ahora `vectorstore.search` solo devuelve los pasajes con similitud de al menos `RAG_MIN_SCORE`.
Si no se configura, usa el calibrado para el backend en uso: **0,10 con `hash`**.

### Cómo se calibró

`python -m scripts.calibrar_umbral`, sobre las cuatro empresas simuladas
([datos-simulados.md](datos-simulados.md)). Mide el mejor puntaje de cinco grupos de preguntas:

| Umbral | FAQ tal cual | Mismas, otras palabras | Sin respuesta | De otra empresa | Ajenas al negocio |
|---|---|---|---|---|---|
| 0,06 | 97 % | 90 % | 75 % | 69 % | 56 % |
| 0,08 | 97 % | 85 % | 25 % | 41 % | 31 % |
| **0,10** | **90 %** | **85 %** | **25 %** | **30 %** | **18 %** |
| 0,12 | 82 % | 65 % | 25 % | 16 % | 6 % |
| 0,15 | 82 % | 45 % | 12 % | 5 % | 6 % |

Cada celda es la parte de ese grupo que **pasa** el umbral. Se busca lo más alto posible en las dos
primeras columnas y lo más bajo posible en las tres últimas. 0,10 es el mejor punto: pierde poco de
lo relevante y descarta tres de cada cuatro preguntas sin respuesta. Desde 0,12 se empiezan a perder
preguntas legítimas dichas con otras palabras.

El 10 % de las FAQ que no pasa en 0,10 no es culpa del umbral: son preguntas que **el clasificador
manda al agente equivocado**. Por ejemplo, «¿Qué incluye la integración con mi sistema de recursos
humanos?» no tiene ninguna palabra comercial de la lista y no ve la FAQ comercial.

El umbral de Azure (0,30) es provisional: con embeddings reales la escala cambia y hay que
recalibrarlo.

## 3. El clasificador confundía problemas técnicos con temas comerciales

Busca palabras comerciales sueltas. «No puedo **cancelar** mi hora médica, la app se cae» o «la
**factura** no se descarga, da error 500» iban al agente comercial.

Ahora, si el mensaje **cuenta que algo falla**, gana el agente técnico. Se reconoce por frases como
«no funciona», «no carga», «no se descarga», «se cae», «error», «falla», «doesn't load», «broken»,
«não carrega» o «erro». Son **frases y no palabras sueltas** a propósito: «¿cómo funciona el plan?» y
«¿cuándo cae el pago?» siguen siendo comerciales. Los 21 casos de regresión anteriores siguen pasando.

Desde el 14 de octubre las reglas son solo el primer paso: si no tienen señal clara, deciden los
temas que la empresa escribió para cada agente y, si tampoco, el modelo, con un tope de 3 s
([motor](motor-langgraph.md)).

## 4. Búsqueda exacta dentro de cada empresa (16 de octubre)

En producción, para «¿Puedo matricularme si estoy en Dicom?», la búsqueda de Duoc UC devolvió los
pasajes 2 al 6 (similitud 0,146 a 0,121) y dejó fuera la pregunta frecuente que la respondía
(0,447 en la búsqueda exacta). El bot dijo que no sabía e inventó un teléfono.

**Por qué.** Duoc UC tiene casi todas las filas de `chunks`. Filtrar por empresa no descarta nada,
y el planificador de PostgreSQL recorre el índice HNSW de la migración 0001, que es
**aproximado**. Con los embeddings `hash`, dispersos y casi ortogonales, el recorrido del grafo del
índice se pierde en las preguntas cortas.

**Arreglo (PR #30).** `vectorstore.search` ordena por `dist + 0`, lo que impide usar el índice:
filtra por empresa y ordena exacto. Con miles de fragmentos por empresa cuesta milisegundos. El
índice sigue creado, pero la búsqueda no lo usa; vuelve a tener sentido con decenas de miles de
fragmentos por empresa y embeddings reales.

**Por qué el CI no lo veía.** Las pruebas crean las tablas con `create_all` y no con las
migraciones, así que el índice no existía. La prueba nueva (solo PostgreSQL) lo crea, le da a una
empresa la mayoría de las filas y comprueba en el plan de la consulta que no se usa.

**Lo que sigue siendo un límite.** La búsqueda sigue siendo por palabras. En Duoc UC se compensó con
la base de conocimiento: resúmenes por carrera, un documento por semestre de cada malla y preguntas
frecuentes redactadas como las haría un alumno. El nodo `reformular` agrega sinónimos a la búsqueda
cuando el proveedor responde.

## Pruebas

- `tests/test_relevancia.py`:
  - el embedding normalizado;
  - una pregunta ajena ya no se parece a nada;
  - el umbral y su configuración;
  - **de punta a punta en el chat público**: dos preguntas sin respuesta terminan en ticket, y una con respuesta no cuenta como fallo.
- `tests/test_intent.py`: 11 casos nuevos, siete de fallas con palabra comercial y cuatro comerciales que se parecen a una falla.
- `tests/test_semantic_search.py`: `test_the_search_is_exact_and_does_not_use_the_approximate_index`
  (solo PostgreSQL) crea el índice HNSW, carga 1500 fragmentos y revisa con `EXPLAIN` que la
  búsqueda no lo usa. Con el código anterior falla.
