-- =====================================================================
-- 01 · FUNDAMENTOS DE SQL EN BIGQUERY
-- =====================================================================
-- Dataset: bigquery-public-data.thelook_ecommerce
-- Tablas que usaremos: users, orders, products
--
-- Objetivo: dominar SELECT, WHERE, tipos de datos, NULLs, fechas y CASE.
-- =====================================================================


-- ---------------------------------------------------------------------
-- 1. SELECT BÁSICO Y NOMBRES DE TABLA
-- ---------------------------------------------------------------------
-- En BigQuery las tablas se referencian como `proyecto.dataset.tabla`
-- y van entre comillas invertidas cuando hay guiones.

SELECT
  id,
  first_name,
  last_name,
  country
FROM `bigquery-public-data.thelook_ecommerce.users`
LIMIT 10;

-- 💡 Para echar un primer vistazo a una tabla, las pestañas "Esquema"
--    (columnas y tipos) y "Vista previa" (algunas filas) del panel de
--    BigQuery son más rápidas que escribir una consulta.


-- ---------------------------------------------------------------------
-- 2. ALIAS Y COLUMNAS CALCULADAS
-- ---------------------------------------------------------------------
SELECT
  name                              AS producto,
  retail_price                      AS precio_venta,
  cost                              AS coste,
  retail_price - cost               AS margen,
  ROUND((retail_price - cost) / retail_price * 100, 1) AS margen_pct
FROM `bigquery-public-data.thelook_ecommerce.products`
LIMIT 20;


-- ---------------------------------------------------------------------
-- 3. SELECT * EXCEPT y SELECT * REPLACE
-- ---------------------------------------------------------------------
-- Todas las columnas menos algunas:
SELECT * EXCEPT (email, street_address, latitude, longitude)
FROM `bigquery-public-data.thelook_ecommerce.users`
LIMIT 10;

-- Todas las columnas pero transformando una:
SELECT * REPLACE (UPPER(country) AS country)
FROM `bigquery-public-data.thelook_ecommerce.users`
LIMIT 10;


-- ---------------------------------------------------------------------
-- 4. FILTRAR CON WHERE
-- ---------------------------------------------------------------------
SELECT id, first_name, age, country, traffic_source
FROM `bigquery-public-data.thelook_ecommerce.users`
WHERE country = 'Spain'
  AND age BETWEEN 25 AND 35               -- incluye 25 y 35
  AND traffic_source IN ('Search', 'Email')
  AND first_name LIKE 'A%'                -- empieza por A
LIMIT 50;

-- Operadores útiles:
--   =, !=, <>, <, >, <=, >=
--   IN (...), NOT IN (...)
--   BETWEEN a AND b
--   LIKE 'patrón%'   (% = cualquier cadena, _ = un carácter)
--   IS NULL, IS NOT NULL

-- Para patrones más complejos, expresiones regulares:
SELECT email
FROM `bigquery-public-data.thelook_ecommerce.users`
WHERE REGEXP_CONTAINS(email, r'@example\.(com|net)$')
LIMIT 20;


-- ---------------------------------------------------------------------
-- 5. NULLs: LA FUENTE Nº1 DE BUGS SILENCIOSOS
-- ---------------------------------------------------------------------
-- NULL significa "desconocido". Cualquier comparación con NULL da NULL,
-- y WHERE solo deja pasar filas donde la condición es TRUE.

-- ❌ Esto NO devuelve nada, aunque haya pedidos sin devolver:
SELECT COUNT(*) AS pedidos
FROM `bigquery-public-data.thelook_ecommerce.orders`
WHERE returned_at = NULL;

-- ✅ Así sí:
SELECT COUNT(*) AS pedidos_no_devueltos
FROM `bigquery-public-data.thelook_ecommerce.orders`
WHERE returned_at IS NULL;

-- 💡 Cuidado con != : también descarta los NULL.
--    "WHERE status != 'Cancelled'" excluye filas con status NULL.
--    Si quieres conservarlas:  WHERE status != 'Cancelled' OR status IS NULL
--    o más corto:              WHERE status IS DISTINCT FROM 'Cancelled'

-- Sustituir NULLs por un valor por defecto:
SELECT
  order_id,
  COALESCE(CAST(returned_at AS STRING), 'No devuelto') AS devolucion,
  IFNULL(num_of_item, 0) AS num_items      -- IFNULL = COALESCE con 2 argumentos
FROM `bigquery-public-data.thelook_ecommerce.orders`
LIMIT 20;


-- ---------------------------------------------------------------------
-- 6. TIPOS DE DATOS Y CONVERSIONES
-- ---------------------------------------------------------------------
-- Tipos principales en BigQuery:
--   INT64, FLOAT64, NUMERIC (decimales exactos, útil para dinero),
--   STRING, BOOL, DATE, DATETIME, TIMESTAMP, ARRAY, STRUCT, JSON

SELECT
  CAST('42' AS INT64)            AS texto_a_entero,
  CAST(3.99 AS STRING)           AS numero_a_texto,
  SAFE_CAST('hola' AS INT64)     AS conversion_segura,   -- devuelve NULL, no error
  PARSE_DATE('%d/%m/%Y', '23/10/2026') AS fecha_desde_texto;

-- 💡 SAFE_CAST es útil con datos "sucios": en vez de romper
--    toda la consulta por una fila mala, devuelve NULL en esa fila.
--    Muchas funciones tienen versión SAFE.: SAFE.PARSE_DATE, SAFE_DIVIDE...


-- ---------------------------------------------------------------------
-- 7. FECHAS Y HORAS
-- ---------------------------------------------------------------------
-- DATE      → 2026-10-23
-- DATETIME  → 2026-10-23 14:30:00            (sin zona horaria)
-- TIMESTAMP → 2026-10-23 14:30:00 UTC        (un instante absoluto)

SELECT
  created_at,                                             -- TIMESTAMP en UTC
  DATE(created_at)                        AS fecha_utc,
  DATE(created_at, 'Europe/Madrid')       AS fecha_madrid,
  DATETIME(created_at, 'Europe/Madrid')   AS hora_madrid,
  EXTRACT(YEAR FROM created_at)           AS anio,
  EXTRACT(DAYOFWEEK FROM created_at)      AS dia_semana,  -- 1 = domingo
  DATE_TRUNC(DATE(created_at), MONTH)     AS mes,
  DATE_TRUNC(DATE(created_at), WEEK(MONDAY)) AS semana,   -- semana empezando en lunes
  FORMAT_DATE('%Y-%m', DATE(created_at))  AS mes_texto
FROM `bigquery-public-data.thelook_ecommerce.orders`
LIMIT 10;

-- 💡 Los TIMESTAMP se guardan en UTC. Si reportas por día en España y
--    haces DATE(created_at) sin zona horaria, los pedidos de las 00:30
--    hora española caen en el día anterior. Pásale siempre la zona.

-- Diferencias y sumas de fechas:
SELECT
  order_id,
  DATE(created_at)                                         AS fecha_pedido,
  DATE(delivered_at)                                       AS fecha_entrega,
  DATE_DIFF(DATE(delivered_at), DATE(created_at), DAY)     AS dias_hasta_entrega,
  TIMESTAMP_DIFF(delivered_at, created_at, HOUR)           AS horas_hasta_entrega,
  DATE_ADD(DATE(created_at), INTERVAL 30 DAY)              AS fin_periodo_devolucion
FROM `bigquery-public-data.thelook_ecommerce.orders`
WHERE delivered_at IS NOT NULL
LIMIT 20;

-- Filtrar por rangos de fechas relativos a hoy:
SELECT COUNT(*) AS pedidos_ultimos_90_dias
FROM `bigquery-public-data.thelook_ecommerce.orders`
WHERE DATE(created_at) >= DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY);


-- ---------------------------------------------------------------------
-- 8. CASE WHEN: LÓGICA CONDICIONAL
-- ---------------------------------------------------------------------
SELECT
  id,
  age,
  CASE
    WHEN age < 25 THEN '18-24'
    WHEN age < 35 THEN '25-34'
    WHEN age < 50 THEN '35-49'
    ELSE '50+'
  END AS tramo_edad,
  IF(traffic_source = 'Organic', 'Orgánico', 'Pago u otro') AS tipo_trafico
FROM `bigquery-public-data.thelook_ecommerce.users`
LIMIT 20;

-- 💡 CASE evalúa en orden y se queda con la PRIMERA condición verdadera.
--    Por eso no hace falta poner "age >= 25 AND age < 35" en la segunda.
--    Y pon siempre un ELSE: sin él, lo que no encaje sale como NULL.


-- ---------------------------------------------------------------------
-- 9. ORDENAR RESULTADOS
-- ---------------------------------------------------------------------
SELECT name, brand, retail_price
FROM `bigquery-public-data.thelook_ecommerce.products`
WHERE category = 'Jeans'
ORDER BY retail_price DESC, name ASC
LIMIT 10;

-- Los NULL van primero en ASC y al final en DESC. Puedes forzarlo:
--   ORDER BY columna ASC NULLS LAST


-- ---------------------------------------------------------------------
-- 10. ORDEN LÓGICO DE EJECUCIÓN (clave para entender errores)
-- ---------------------------------------------------------------------
-- Escribes:   SELECT → FROM → WHERE → GROUP BY → HAVING → ORDER BY → LIMIT
-- Se ejecuta: FROM → WHERE → GROUP BY → HAVING → SELECT → QUALIFY → ORDER BY → LIMIT
--
-- Por eso no puedes usar en el WHERE un alias definido en el SELECT:
-- cuando se evalúa el WHERE, ese alias todavía no existe.
-- (BigQuery sí permite usar alias en GROUP BY y ORDER BY.)
