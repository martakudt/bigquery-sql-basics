-- =====================================================================
-- 02 · AGREGACIONES: RESUMIR MILLONES DE FILAS EN UNAS POCAS
-- =====================================================================
-- Dataset: bigquery-public-data.thelook_ecommerce
--
-- Objetivo: GROUP BY, HAVING, funciones de agregación, agregaciones
-- condicionales y cómo evitar divisiones por cero.
-- =====================================================================


-- ---------------------------------------------------------------------
-- 1. FUNCIONES DE AGREGACIÓN BÁSICAS
-- ---------------------------------------------------------------------
SELECT
  COUNT(*)                     AS total_lineas,
  COUNT(returned_at)           AS lineas_devueltas,     -- cuenta solo NO NULL
  COUNT(DISTINCT order_id)     AS pedidos_unicos,
  COUNT(DISTINCT user_id)      AS clientes_unicos,
  ROUND(SUM(sale_price), 2)    AS ingresos_totales,
  ROUND(AVG(sale_price), 2)    AS precio_medio,
  MIN(sale_price)              AS precio_min,
  MAX(sale_price)              AS precio_max
FROM `bigquery-public-data.thelook_ecommerce.order_items`;

-- 💡 COUNT(*) cuenta filas. COUNT(columna) cuenta valores NO NULL.
--    Confundirlos es un clásico: COUNT(returned_at) te da devoluciones,
--    COUNT(*) te da todas las líneas.


-- ---------------------------------------------------------------------
-- 2. GROUP BY
-- ---------------------------------------------------------------------
-- Regla: toda columna del SELECT que no esté agregada debe ir en GROUP BY.

SELECT
  status,
  COUNT(*) AS num_pedidos
FROM `bigquery-public-data.thelook_ecommerce.orders`
GROUP BY status
ORDER BY num_pedidos DESC;

-- Agrupar por varias columnas y por expresiones:
SELECT
  DATE_TRUNC(DATE(created_at), MONTH) AS mes,
  status,
  COUNT(*) AS num_pedidos
FROM `bigquery-public-data.thelook_ecommerce.orders`
GROUP BY mes, status          -- BigQuery permite agrupar por el alias
ORDER BY mes, status;

-- También puedes usar posiciones (GROUP BY 1, 2). Es cómodo para explorar,
-- pero en código que vaya a producción prefiero nombres: es más legible
-- y no se rompe si reordenas columnas.


-- ---------------------------------------------------------------------
-- 3. HAVING: FILTRAR DESPUÉS DE AGRUPAR
-- ---------------------------------------------------------------------
-- WHERE filtra filas ANTES de agrupar.
-- HAVING filtra grupos DESPUÉS de agrupar.

-- Marcas con más de 500 productos y precio medio por encima de 50:
SELECT
  brand,
  COUNT(*)                   AS num_productos,
  ROUND(AVG(retail_price), 2) AS precio_medio
FROM `bigquery-public-data.thelook_ecommerce.products`
WHERE brand IS NOT NULL                 -- filtro de filas
GROUP BY brand
HAVING COUNT(*) > 50                    -- filtro de grupos
   AND AVG(retail_price) > 50
ORDER BY num_productos DESC;

-- 💡 Si un filtro se puede poner en WHERE, ponlo en WHERE: se aplica
--    antes y BigQuery agrupa menos datos.


-- ---------------------------------------------------------------------
-- 4. AGREGACIONES CONDICIONALES (de lo más útil del día a día)
-- ---------------------------------------------------------------------
-- En vez de hacer una consulta por cada estado, lo calculas todo de golpe.

SELECT
  DATE_TRUNC(DATE(created_at), MONTH)        AS mes,
  COUNT(*)                                   AS total_pedidos,
  COUNTIF(status = 'Complete')               AS completados,
  COUNTIF(status = 'Cancelled')              AS cancelados,
  COUNTIF(status = 'Returned')               AS devueltos,
  SUM(IF(status = 'Complete', num_of_item, 0)) AS items_completados
FROM `bigquery-public-data.thelook_ecommerce.orders`
GROUP BY mes
ORDER BY mes;

-- COUNTIF(condicion) es exclusivo de BigQuery y equivale a
-- SUM(CASE WHEN condicion THEN 1 ELSE 0 END).


-- ---------------------------------------------------------------------
-- 5. PORCENTAJES Y SAFE_DIVIDE
-- ---------------------------------------------------------------------
SELECT
  traffic_source,
  COUNT(*)                                          AS usuarios,
  COUNTIF(country = 'Spain')                        AS usuarios_espana,
  ROUND(SAFE_DIVIDE(COUNTIF(country = 'Spain'), COUNT(*)) * 100, 2) AS pct_espana
FROM `bigquery-public-data.thelook_ecommerce.users`
GROUP BY traffic_source
ORDER BY usuarios DESC;

-- 💡 SAFE_DIVIDE(a, b) devuelve NULL si b = 0 en lugar de romper la
--    consulta con "division by zero". Úsalo siempre que el denominador
--    pueda ser 0 (tasas de conversión, ratios, etc.).

-- 💡 Cuidado con divisiones de enteros en otros motores: en BigQuery el
--    operador / siempre devuelve FLOAT64, así que 1/2 = 0.5 (bien).


-- ---------------------------------------------------------------------
-- 6. AVG Y LOS NULLs
-- ---------------------------------------------------------------------
-- AVG ignora los NULL. 

SELECT
  AVG(DATE_DIFF(DATE(delivered_at), DATE(created_at), DAY))    AS media_dias_entregados,
  -- ↑ media solo de pedidos entregados (los no entregados son NULL y se ignoran)
  COUNT(*)                                                     AS total_pedidos,
  COUNT(delivered_at)                                          AS pedidos_entregados
FROM `bigquery-public-data.thelook_ecommerce.orders`;

-- Si quisieras tratar los NULL como 0, tendrías que hacerlo explícito:
--   AVG(COALESCE(columna, 0))
-- Pregúntate siempre: ¿qué significa NULL en esta columna?


-- ---------------------------------------------------------------------
-- 7. CONTEOS APROXIMADOS PARA TABLAS ENORMES
-- ---------------------------------------------------------------------
-- COUNT(DISTINCT) exacto puede ser lento en tablas de miles de millones de filas.
-- APPROX_COUNT_DISTINCT tiene un error típico de ~1% y es mucho más rápido.

SELECT
  COUNT(DISTINCT session_id)        AS sesiones_exactas,
  APPROX_COUNT_DISTINCT(session_id) AS sesiones_aproximadas
FROM `bigquery-public-data.thelook_ecommerce.events`;

-- Perfecto para dashboards y exploración. Para cifras "oficiales"
-- (reporting a negocio, cierres de mes) usa siempre el exacto.

-- Percentiles aproximados (la mediana suele contar mejor la historia que la media):
SELECT
  APPROX_QUANTILES(sale_price, 100)[OFFSET(50)] AS mediana,
  APPROX_QUANTILES(sale_price, 100)[OFFSET(90)] AS percentil_90,
  ROUND(AVG(sale_price), 2)                     AS media
FROM `bigquery-public-data.thelook_ecommerce.order_items`;


-- ---------------------------------------------------------------------
-- 8. AGREGAR EN LISTAS: STRING_AGG y ARRAY_AGG
-- ---------------------------------------------------------------------
-- Juntar valores de varias filas en una sola celda:
SELECT
  category,
  COUNT(DISTINCT brand) AS num_marcas,
  STRING_AGG(DISTINCT brand, ', ' ORDER BY brand LIMIT 5) AS ejemplo_marcas
FROM `bigquery-public-data.thelook_ecommerce.products`
GROUP BY category
ORDER BY num_marcas DESC;

-- ARRAY_AGG hace lo mismo pero devuelve un ARRAY (lo vemos en el archivo 05).
-- Truco muy usado: quedarte con "la fila más reciente" de cada grupo.
SELECT
  user_id,
  ARRAY_AGG(STRUCT(order_id, status, created_at) ORDER BY created_at DESC LIMIT 1)[OFFSET(0)] AS ultimo_pedido
FROM `bigquery-public-data.thelook_ecommerce.orders`
GROUP BY user_id
LIMIT 20;


-- ---------------------------------------------------------------------
-- 9. SUBTOTALES CON ROLLUP
-- ---------------------------------------------------------------------
-- Genera subtotales por niveles y un total general, en una sola consulta.
SELECT
  department,
  category,
  COUNT(*) AS num_productos
FROM `bigquery-public-data.thelook_ecommerce.products`
GROUP BY ROLLUP (department, category)
ORDER BY department, category;

-- Las filas con category NULL son el subtotal de cada departamento;
-- la fila con ambos NULL es el total general.
