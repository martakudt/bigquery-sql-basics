-- =====================================================================
-- 04 · CTEs Y WINDOW FUNCTIONS: EL SALTO DE NIVEL
-- =====================================================================
-- Dataset: bigquery-public-data.thelook_ecommerce
--
-- Objetivo: escribir consultas legibles con WITH y calcular rankings,
-- acumulados, comparaciones con la fila anterior, etc. sin perder detalle.
-- =====================================================================


-- ---------------------------------------------------------------------
-- 1. CTEs (WITH)
-- ---------------------------------------------------------------------
-- Una CTE es una "tabla temporal con nombre" que solo existe durante la
-- consulta. Permite leer el SQL de arriba abajo, paso a paso.

WITH
pedidos_validos AS (
  SELECT order_id, user_id, created_at
  FROM `bigquery-public-data.thelook_ecommerce.orders`
  WHERE status NOT IN ('Cancelled', 'Returned')
),
ingresos_por_pedido AS (
  SELECT order_id, SUM(sale_price) AS ingresos
  FROM `bigquery-public-data.thelook_ecommerce.order_items`
  GROUP BY order_id
),
resumen_cliente AS (
  SELECT
    p.user_id,
    COUNT(*)            AS num_pedidos,
    SUM(i.ingresos)     AS ingresos_totales,
    MIN(p.created_at)   AS primer_pedido
  FROM pedidos_validos AS p
  JOIN ingresos_por_pedido AS i USING (order_id)
  GROUP BY p.user_id
)
SELECT *
FROM resumen_cliente
ORDER BY ingresos_totales DESC
LIMIT 20;

-- 💡 Ventajas frente a subconsultas anidadas:
--    · Se lee en orden lógico, como una receta.
--    · Puedes depurar paso a paso: cambia el SELECT final por
--      "SELECT * FROM pedidos_validos LIMIT 10" para ver un paso concreto.
--    · Pon nombres que expliquen QUÉ contiene cada paso.


-- ---------------------------------------------------------------------
-- 2. ¿QUÉ ES UNA WINDOW FUNCTION?
-- ---------------------------------------------------------------------
-- GROUP BY colapsa filas: 1.000 pedidos → 1 fila por cliente.
-- Una window function calcula sobre un grupo de filas PERO mantiene
-- todas las filas. Sintaxis:
--
--   FUNCION() OVER (
--     PARTITION BY ...   -- en qué grupos calcular (opcional)
--     ORDER BY ...       -- en qué orden (opcional según la función)
--     ROWS BETWEEN ...   -- qué filas del grupo mirar (opcional)
--   )

-- Ejemplo: cada pedido junto al total de pedidos de ese cliente
SELECT
  order_id,
  user_id,
  created_at,
  COUNT(*) OVER (PARTITION BY user_id) AS pedidos_del_cliente
FROM `bigquery-public-data.thelook_ecommerce.orders`
WHERE user_id < 100
ORDER BY user_id, created_at;


-- ---------------------------------------------------------------------
-- 3. ROW_NUMBER: NUMERAR Y DEDUPLICAR
-- ---------------------------------------------------------------------
-- Numerar los pedidos de cada cliente por orden cronológico:
SELECT
  user_id,
  order_id,
  created_at,
  ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY created_at) AS n_pedido
FROM `bigquery-public-data.thelook_ecommerce.orders`
WHERE user_id < 100
ORDER BY user_id, n_pedido;

-- 💡 Uso estrella: DEDUPLICAR. Quedarse con el registro más reciente
--    por clave. Esto lo uso prácticamente cada semana.


-- ---------------------------------------------------------------------
-- 4. QUALIFY: FILTRAR POR UNA WINDOW FUNCTION (joya de BigQuery)
-- ---------------------------------------------------------------------
-- Igual que HAVING filtra agregaciones, QUALIFY filtra window functions.
-- Sin QUALIFY necesitarías una subconsulta o CTE extra.

-- Primer pedido de cada cliente:
SELECT
  user_id,
  order_id,
  created_at
FROM `bigquery-public-data.thelook_ecommerce.orders`
WHERE status != 'Cancelled'
QUALIFY ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY created_at) = 1;

-- El patrón de deduplicación que más uso (última versión de cada registro):
--   SELECT *
--   FROM mi_tabla
--   WHERE TRUE
--   QUALIFY ROW_NUMBER() OVER (PARTITION BY id ORDER BY updated_at DESC) = 1


-- ---------------------------------------------------------------------
-- 5. RANK vs DENSE_RANK vs ROW_NUMBER
-- ---------------------------------------------------------------------
-- Con empates en el valor de ordenación:
--   ROW_NUMBER → 1, 2, 3, 4   (siempre distinto, desempata al azar)
--   RANK       → 1, 2, 2, 4   (empates comparten puesto y se salta)
--   DENSE_RANK → 1, 2, 2, 3   (empates comparten puesto, sin saltos)

-- Top 3 productos más caros de cada categoría:
SELECT
  category,
  name,
  retail_price,
  DENSE_RANK() OVER (PARTITION BY category ORDER BY retail_price DESC) AS ranking
FROM `bigquery-public-data.thelook_ecommerce.products`
WHERE category IS NOT NULL
QUALIFY ranking <= 3
ORDER BY category, ranking;

-- 💡 Si usas ROW_NUMBER con empates, añade una columna extra al ORDER BY
--    (por ejemplo el id) para que el resultado sea determinista. Si no,
--    dos ejecuciones pueden darte filas distintas.


-- ---------------------------------------------------------------------
-- 6. LAG Y LEAD: COMPARAR CON LA FILA ANTERIOR / SIGUIENTE
-- ---------------------------------------------------------------------
-- Días entre pedidos consecutivos de un mismo cliente:
SELECT
  user_id,
  order_id,
  DATE(created_at) AS fecha,
  LAG(DATE(created_at)) OVER (PARTITION BY user_id ORDER BY created_at) AS fecha_pedido_anterior,
  DATE_DIFF(
    DATE(created_at),
    LAG(DATE(created_at)) OVER (PARTITION BY user_id ORDER BY created_at),
    DAY
  ) AS dias_desde_anterior
FROM `bigquery-public-data.thelook_ecommerce.orders`
WHERE user_id < 200
ORDER BY user_id, fecha;

-- Crecimiento mes contra mes (MoM):
WITH ventas_mes AS (
  SELECT
    DATE_TRUNC(DATE(created_at), MONTH) AS mes,
    SUM(sale_price)                     AS ingresos
  FROM `bigquery-public-data.thelook_ecommerce.order_items`
  WHERE status NOT IN ('Cancelled', 'Returned')
  GROUP BY mes
)
SELECT
  mes,
  ROUND(ingresos, 0)                                 AS ingresos,
  ROUND(LAG(ingresos) OVER (ORDER BY mes), 0)        AS ingresos_mes_anterior,
  ROUND(SAFE_DIVIDE(ingresos - LAG(ingresos) OVER (ORDER BY mes),
                    LAG(ingresos) OVER (ORDER BY mes)) * 100, 1) AS crecimiento_pct
FROM ventas_mes
ORDER BY mes;


-- ---------------------------------------------------------------------
-- 7. ACUMULADOS (RUNNING TOTALS)
-- ---------------------------------------------------------------------
WITH ventas_dia AS (
  SELECT
    DATE(created_at)  AS dia,
    SUM(sale_price)   AS ingresos
  FROM `bigquery-public-data.thelook_ecommerce.order_items`
  WHERE EXTRACT(YEAR FROM created_at) = 2024
  GROUP BY dia
)
SELECT
  dia,
  ROUND(ingresos, 0) AS ingresos,
  ROUND(SUM(ingresos) OVER (ORDER BY dia), 0) AS acumulado_anual,
  ROUND(SUM(ingresos) OVER (
    PARTITION BY DATE_TRUNC(dia, MONTH) ORDER BY dia
  ), 0) AS acumulado_mes                        -- se reinicia cada mes
FROM ventas_dia
ORDER BY dia;


-- ---------------------------------------------------------------------
-- 8. MEDIAS MÓVILES CON MARCOS DE VENTANA (ROWS BETWEEN)
-- ---------------------------------------------------------------------
-- Media móvil de 7 días para suavizar el ruido diario:
WITH ventas_dia AS (
  SELECT DATE(created_at) AS dia, SUM(sale_price) AS ingresos
  FROM `bigquery-public-data.thelook_ecommerce.order_items`
  WHERE EXTRACT(YEAR FROM created_at) = 2024
  GROUP BY dia
)
SELECT
  dia,
  ROUND(ingresos, 0) AS ingresos,
  ROUND(AVG(ingresos) OVER (
    ORDER BY dia
    ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
  ), 0) AS media_movil_7d
FROM ventas_dia
ORDER BY dia;

-- 💡 ROWS cuenta filas, no días. Si faltan días sin ventas, "6 filas
--    atrás" no son 6 días. Para días reales, rellena los huecos primero
--    (ver GENERATE_DATE_ARRAY en el archivo 05) o usa RANGE con fechas
--    convertidas a número: RANGE BETWEEN 6 PRECEDING AND CURRENT ROW
--    sobre UNIX_DATE(dia).


-- ---------------------------------------------------------------------
-- 9. PORCENTAJE SOBRE EL TOTAL
-- ---------------------------------------------------------------------
SELECT
  category,
  ROUND(SUM(sale_price), 0) AS ingresos,
  ROUND(SUM(sale_price) / SUM(SUM(sale_price)) OVER () * 100, 2) AS pct_del_total
FROM `bigquery-public-data.thelook_ecommerce.order_items` AS oi
JOIN `bigquery-public-data.thelook_ecommerce.products` AS p
  ON oi.product_id = p.id
GROUP BY category
ORDER BY ingresos DESC;

-- SUM(SUM(x)) OVER () parece raro pero es lógico: la SUM interior es la
-- agregación del GROUP BY, y la exterior suma todos los grupos.
-- OVER () vacío = la ventana es el resultado entero.


-- ---------------------------------------------------------------------
-- 10. FIRST_VALUE / LAST_VALUE
-- ---------------------------------------------------------------------
-- Canal de adquisición del primer evento de cada sesión:
SELECT DISTINCT
  session_id,
  FIRST_VALUE(traffic_source) OVER (
    PARTITION BY session_id ORDER BY sequence_number
  ) AS canal_entrada,
  FIRST_VALUE(uri) OVER (
    PARTITION BY session_id ORDER BY sequence_number
  ) AS pagina_entrada
FROM `bigquery-public-data.thelook_ecommerce.events`
WHERE user_id < 100;

-- ⚠️ LAST_VALUE tiene trampa: por defecto la ventana llega solo hasta la
--    fila actual, así que devuelve... la fila actual. Necesitas:
--    ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
--    Más fácil: usa FIRST_VALUE con ORDER BY ... DESC.
