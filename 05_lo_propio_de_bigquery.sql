-- =====================================================================
-- 05 · LO PROPIO DE BIGQUERY: ARRAYS, STRUCTS, PARTICIONES Y MÁS
-- =====================================================================
-- Datasets:
--   bigquery-public-data.thelook_ecommerce
--   bigquery-public-data.google_analytics_sample   (datos anidados)
--
-- Objetivo: entender lo que hace a BigQuery diferente de otras bases de
-- datos: datos anidados, tablas particionadas, clustering y tablas comodín.
-- =====================================================================


-- ---------------------------------------------------------------------
-- 1. ARRAYS: UNA LISTA DE VALORES EN UNA SOLA CELDA
-- ---------------------------------------------------------------------
SELECT
  ['rojo', 'verde', 'azul']            AS colores,
  ARRAY_LENGTH(['rojo', 'verde', 'azul']) AS num_colores,
  ['rojo', 'verde', 'azul'][OFFSET(0)]   AS primero,      -- índice desde 0
  ['rojo', 'verde', 'azul'][ORDINAL(1)]  AS primero_bis,  -- índice desde 1
  ['rojo', 'verde'][SAFE_OFFSET(5)]      AS fuera_de_rango; -- NULL, no error

-- Construir arrays a partir de filas con ARRAY_AGG:
SELECT
  user_id,
  ARRAY_AGG(order_id ORDER BY created_at) AS pedidos
FROM `bigquery-public-data.thelook_ecommerce.orders`
WHERE user_id < 50
GROUP BY user_id;


-- ---------------------------------------------------------------------
-- 2. STRUCTS: UN "MINI-REGISTRO" DENTRO DE UNA COLUMNA
-- ---------------------------------------------------------------------
SELECT
  STRUCT('Ana' AS nombre, 31 AS edad, 'Valencia' AS ciudad) AS persona;

-- Se accede con punto: persona.nombre, persona.edad...
-- Combinando ARRAY + STRUCT tienes una "tabla dentro de una fila":
SELECT
  user_id,
  ARRAY_AGG(STRUCT(order_id, status, created_at) ORDER BY created_at) AS historial
FROM `bigquery-public-data.thelook_ecommerce.orders`
WHERE user_id < 20
GROUP BY user_id;


-- ---------------------------------------------------------------------
-- 3. UNNEST: DESPLEGAR UN ARRAY EN FILAS
-- ---------------------------------------------------------------------
-- UNNEST convierte cada elemento del array en una fila.
SELECT color
FROM UNNEST(['rojo', 'verde', 'azul']) AS color;

-- Con datos reales: Google Analytics guarda los "hits" (páginas vistas,
-- eventos...) como un ARRAY<STRUCT> dentro de cada sesión.
-- Una fila = una sesión. Dentro: todos sus hits.

SELECT
  fullVisitorId,
  visitId,
  totals.pageviews,                -- STRUCT: se accede con punto
  ARRAY_LENGTH(hits) AS num_hits   -- ARRAY: cuántos hits hay
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170801`
LIMIT 10;

-- Desplegar los hits (una fila por hit):
SELECT
  s.fullVisitorId,
  s.visitId,
  h.hitNumber,
  h.type,
  h.page.pagePath
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170801` AS s,
  UNNEST(s.hits) AS h                         -- la coma equivale a CROSS JOIN
WHERE h.type = 'PAGE'
ORDER BY s.fullVisitorId, s.visitId, h.hitNumber
LIMIT 50;

-- ⚠️ La coma (CROSS JOIN) ELIMINA las filas cuyo array está vacío.
--    Si quieres conservarlas, usa LEFT JOIN:
--    FROM tabla AS s
--    LEFT JOIN UNNEST(s.hits) AS h

-- Páginas más visitadas del día:
SELECT
  h.page.pagePath   AS pagina,
  COUNT(*)          AS vistas
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170801`,
  UNNEST(hits) AS h
WHERE h.type = 'PAGE'
GROUP BY pagina
ORDER BY vistas DESC
LIMIT 10;

-- 💡 Subconsulta sobre el array SIN desplegar la tabla entera. Muy
--    eficiente y mantiene una fila por sesión:
SELECT
  fullVisitorId,
  visitId,
  (SELECT COUNT(*) FROM UNNEST(hits) WHERE type = 'PAGE') AS paginas_vistas,
  EXISTS(SELECT 1 FROM UNNEST(hits) h WHERE h.page.pagePath LIKE '%basket%') AS vio_carrito
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170801`
LIMIT 20;

-- ¿Por qué BigQuery usa datos anidados? Porque evita JOINs pesados:
-- la sesión y sus hits ya están juntos, almacenados uno al lado del otro.


-- ---------------------------------------------------------------------
-- 4. GENERATE_DATE_ARRAY: RELLENAR HUECOS EN SERIES TEMPORALES
-- ---------------------------------------------------------------------
-- Si un día no hubo ventas, simplemente no aparece en un GROUP BY.
-- En un gráfico, ese hueco desaparece y la línea "miente".
-- Solución: generar un calendario completo y hacer LEFT JOIN.

WITH calendario AS (
  SELECT dia
  FROM UNNEST(GENERATE_DATE_ARRAY('2024-01-01', '2024-01-31', INTERVAL 1 DAY)) AS dia
),
ventas AS (
  SELECT DATE(created_at) AS dia, COUNT(*) AS lineas
  FROM `bigquery-public-data.thelook_ecommerce.order_items`
  WHERE DATE(created_at) BETWEEN '2024-01-01' AND '2024-01-31'
    AND product_id = 13606            -- un producto con pocas ventas
  GROUP BY dia
)
SELECT
  c.dia,
  COALESCE(v.lineas, 0) AS lineas_vendidas
FROM calendario AS c
LEFT JOIN ventas AS v USING (dia)
ORDER BY c.dia;

-- Combinado con CROSS JOIN tienes el "esqueleto" completo
-- (todas las categorías × todos los días) para no perder ningún cero.


-- ---------------------------------------------------------------------
-- 5. TABLAS COMODÍN (WILDCARD) Y _TABLE_SUFFIX
-- ---------------------------------------------------------------------
-- Algunos datasets tienen una tabla por día: ga_sessions_20170801,
-- ga_sessions_20170802... Puedes consultarlas todas a la vez con *.

SELECT
  _TABLE_SUFFIX                      AS dia,
  COUNT(*)                           AS sesiones,
  SUM(totals.transactions)           AS transacciones
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
WHERE _TABLE_SUFFIX BETWEEN '20170701' AND '20170731'
GROUP BY dia
ORDER BY dia;

-- ⚠️ Filtra SIEMPRE por _TABLE_SUFFIX. Sin el filtro, BigQuery lee
--    TODAS las tablas que encajen con el patrón y la consulta tarda mucho más.


-- ---------------------------------------------------------------------
-- 6. TABLAS PARTICIONADAS
-- ---------------------------------------------------------------------
-- Una tabla particionada se divide físicamente en "trozos", normalmente
-- por fecha. Si filtras por esa columna, BigQuery solo lee los trozos
-- necesarios → consultas mucho más rápidas.
--
-- Es la versión moderna de las tablas por día del punto anterior.
-- (Sustituye mi_proyecto.mi_dataset por los tuyos.)

CREATE OR REPLACE TABLE `mi_proyecto.mi_dataset.order_items_particionada`
PARTITION BY DATE(created_at)
CLUSTER BY status, product_id
OPTIONS (
  require_partition_filter = TRUE,          -- obliga a filtrar por fecha
  description = 'Líneas de pedido particionadas por día'
) AS
SELECT *
FROM `bigquery-public-data.thelook_ecommerce.order_items`;

-- ✅ Lee solo una semana de datos:
SELECT status, SUM(sale_price) AS ingresos
FROM `mi_proyecto.mi_dataset.order_items_particionada`
WHERE DATE(created_at) BETWEEN '2024-03-01' AND '2024-03-07'
GROUP BY status;

-- 💡 require_partition_filter = TRUE es un salvavidas: si alguien
--    (incluido tú dentro de 6 meses) lanza una consulta sin filtro de
--    fecha, BigQuery la rechaza en lugar de leer la tabla entera.

-- ⚠️ El filtro tiene que poder evaluarse ANTES de ejecutar. Esto puede
--    impedir la poda de particiones:
--    WHERE DATE(created_at) >= (SELECT MAX(fecha) FROM otra_tabla)
--    Mejor calcula ese valor antes en una variable (ver punto 8).


-- ---------------------------------------------------------------------
-- 7. CLUSTERING
-- ---------------------------------------------------------------------
-- El clustering ordena los datos DENTRO de cada partición según las
-- columnas indicadas (hasta 4). Al filtrar por ellas, BigQuery se salta
-- bloques enteros.
--
-- Regla práctica:
--   · PARTITION BY → la columna de fecha por la que casi siempre filtras.
--   · CLUSTER BY   → columnas por las que filtras o agrupas a menudo
--                    (cliente, país, estado...). El orden importa: pon
--                    primero la que más filtras.

SELECT SUM(sale_price) AS ingresos
FROM `mi_proyecto.mi_dataset.order_items_particionada`
WHERE DATE(created_at) >= '2024-01-01'     -- poda por partición
  AND status = 'Complete';                 -- poda por clustering

-- Consulta los metadatos de las particiones de tu tabla:
SELECT partition_id, total_rows, total_logical_bytes
FROM `mi_proyecto.mi_dataset.INFORMATION_SCHEMA.PARTITIONS`
WHERE table_name = 'order_items_particionada'
ORDER BY partition_id DESC
LIMIT 10;


-- ---------------------------------------------------------------------
-- 8. SCRIPTING: VARIABLES Y VARIAS SENTENCIAS
-- ---------------------------------------------------------------------
-- BigQuery permite ejecutar varias sentencias con variables.
DECLARE fecha_inicio DATE DEFAULT DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY);
DECLARE fecha_fin    DATE DEFAULT CURRENT_DATE();

SELECT
  COUNT(*)        AS pedidos,
  SUM(num_of_item) AS items
FROM `bigquery-public-data.thelook_ecommerce.orders`
WHERE DATE(created_at) BETWEEN fecha_inicio AND fecha_fin;

-- Tablas temporales (solo viven durante el script / sesión):
CREATE TEMP TABLE clientes_top AS
SELECT user_id, SUM(sale_price) AS gasto
FROM `bigquery-public-data.thelook_ecommerce.order_items`
GROUP BY user_id
ORDER BY gasto DESC
LIMIT 100;

SELECT * FROM clientes_top;


-- ---------------------------------------------------------------------
-- 9. JSON
-- ---------------------------------------------------------------------
-- Cada vez es más habitual recibir columnas con JSON (APIs, eventos...).
SELECT
  JSON_VALUE(datos, '$.cliente.nombre')        AS nombre,
  CAST(JSON_VALUE(datos, '$.importe') AS NUMERIC) AS importe,
  JSON_QUERY_ARRAY(datos, '$.productos')        AS productos
FROM (
  SELECT '{"cliente": {"nombre": "Ana"}, "importe": "49.90", "productos": ["camiseta", "gorra"]}' AS datos
);

-- JSON_VALUE  → extrae un valor escalar como STRING
-- JSON_QUERY  → extrae un objeto o array como JSON
-- Si tienes el tipo JSON nativo, puedes acceder con datos.cliente.nombre


-- ---------------------------------------------------------------------
-- 10. OTROS ATAJOS QUE ME ENCANTAN
-- ---------------------------------------------------------------------
-- Pivotar filas a columnas:
SELECT *
FROM (
  SELECT EXTRACT(YEAR FROM created_at) AS anio, status
  FROM `bigquery-public-data.thelook_ecommerce.orders`
)
PIVOT (COUNT(*) FOR status IN ('Complete', 'Cancelled', 'Returned', 'Shipped', 'Processing'))
ORDER BY anio;

-- Funciones de usuario (UDF) temporales para no repetir lógica:
CREATE TEMP FUNCTION tramo_edad(edad INT64) AS (
  CASE
    WHEN edad < 25 THEN '18-24'
    WHEN edad < 35 THEN '25-34'
    WHEN edad < 50 THEN '35-49'
    ELSE '50+'
  END
);

SELECT tramo_edad(age) AS tramo, COUNT(*) AS usuarios
FROM `bigquery-public-data.thelook_ecommerce.users`
GROUP BY tramo
ORDER BY tramo;
