-- =====================================================================
-- SOLUCIONES · BLOQUE 3 · JOINS
-- =====================================================================
-- Temas nuevos: tipos de JOIN, filtros en ON vs WHERE, anti-joins y fan-out.
-- Los ejercicios usan los bloques 1 a 3: cada bloque repasa lo anterior.
--
-- Dificultad: ⭐ básico | ⭐⭐ medio | ⭐⭐⭐ reto
--
-- Hay muchas formas correctas de resolver cada ejercicio. Si tu
-- consulta devuelve lo mismo, está bien aunque sea distinta.
-- =====================================================================


-- ---------------------------------------------------------------------
-- 3.1 · Ingresos por categoría   ⭐
-- Repasa: bloques 2 + 3
-- ---------------------------------------------------------------------
-- Calcula, para cada categoría de producto, el número de pedidos distintos
-- y los ingresos totales, sin contar las líneas canceladas ni devueltas.
-- Ordena de más a menos ingresos.

SELECT
  p.category                    AS categoria,
  COUNT(DISTINCT oi.order_id)   AS pedidos,
  ROUND(SUM(oi.sale_price), 2)  AS ingresos
FROM `bigquery-public-data.thelook_ecommerce.order_items` AS oi
JOIN `bigquery-public-data.thelook_ecommerce.products` AS p
  ON oi.product_id = p.id
WHERE oi.status NOT IN ('Cancelled', 'Returned')
GROUP BY categoria
ORDER BY ingresos DESC;


-- ---------------------------------------------------------------------
-- 3.2 · Usuarios que nunca han comprado   ⭐⭐
-- Repasa: bloques 2 + 3
-- ---------------------------------------------------------------------
-- ¿Cuántos usuarios no han hecho ningún pedido? Desglósalo por
-- canal de adquisición (traffic_source).

SELECT
  u.traffic_source,
  COUNT(*) AS usuarios_sin_pedidos
FROM `bigquery-public-data.thelook_ecommerce.users` AS u
WHERE NOT EXISTS (
  SELECT 1
  FROM `bigquery-public-data.thelook_ecommerce.orders` AS o
  WHERE o.user_id = u.id
)
GROUP BY u.traffic_source
ORDER BY usuarios_sin_pedidos DESC;

-- 💡 Con NOT IN (SELECT user_id ...) funcionaría aquí, pero si user_id tuviera algún NULL la consulta devolvería 0 filas sin avisar.


-- ---------------------------------------------------------------------
-- 3.3 · Todos los usuarios españoles, compren o no   ⭐⭐
-- Repasa: bloques 1 + 2 + 3
-- ---------------------------------------------------------------------
-- Lista TODOS los usuarios de España con el número de pedidos
-- completados que tiene cada uno (0 si no tiene ninguno).
-- Ordena de más a menos pedidos.

SELECT
  u.id                 AS user_id,
  u.first_name,
  u.last_name,
  COUNT(o.order_id)    AS pedidos_completados
FROM `bigquery-public-data.thelook_ecommerce.users` AS u
LEFT JOIN `bigquery-public-data.thelook_ecommerce.orders` AS o
  ON u.id = o.user_id
 AND o.status = 'Complete'          -- filtro de la tabla derecha: en el ON
WHERE u.country = 'Spain'           -- filtro de la tabla izquierda: en el WHERE
GROUP BY user_id, u.first_name, u.last_name
ORDER BY pedidos_completados DESC;

-- 💡 Si pones o.status en el WHERE, desaparecen los usuarios sin pedidos completados. Y usa COUNT(o.order_id), no COUNT(*), para que salga 0.


-- ---------------------------------------------------------------------
-- 3.4 · Arregla este informe inflado   ⭐⭐⭐
-- Repasa: bloques 1 + 2 + 3
-- ---------------------------------------------------------------------
-- Este informe de unidades e ingresos por mes da cifras de unidades
-- demasiado altas. Encuentra el problema y corrígelo.
--
--     SELECT
--       DATE_TRUNC(DATE(o.created_at), MONTH) AS mes,
--       SUM(o.num_of_item)                    AS unidades,
--       SUM(oi.sale_price)                    AS ingresos
--     FROM `bigquery-public-data.thelook_ecommerce.orders` AS o
--     JOIN `bigquery-public-data.thelook_ecommerce.order_items` AS oi
--       ON o.order_id = oi.order_id
--     GROUP BY mes
--     ORDER BY mes;

SELECT
  DATE_TRUNC(DATE(o.created_at), MONTH) AS mes,
  SUM(o.num_of_item)                    AS unidades,
  ROUND(SUM(i.ingresos), 2)             AS ingresos
FROM `bigquery-public-data.thelook_ecommerce.orders` AS o
JOIN (
  -- Agregamos las líneas a nivel de pedido ANTES de unir
  SELECT order_id, SUM(sale_price) AS ingresos
  FROM `bigquery-public-data.thelook_ecommerce.order_items`
  GROUP BY order_id
) AS i
  ON o.order_id = i.order_id
GROUP BY mes
ORDER BY mes;

-- 💡 Otra solución válida: no usar orders y contar las unidades directamente como COUNT(*) sobre order_items.


-- ---------------------------------------------------------------------
-- 3.5 · Marcas top de 2024   ⭐⭐
-- Repasa: bloques 1 + 2 + 3
-- ---------------------------------------------------------------------
-- Muestra las 10 marcas con más ingresos en 2024 (sin cancelados ni
-- devueltos), con su número de pedidos distintos y el ticket medio
-- (ingresos / pedidos) redondeado a 2 decimales.

SELECT
  p.brand                                                        AS marca,
  COUNT(DISTINCT oi.order_id)                                    AS pedidos,
  ROUND(SUM(oi.sale_price), 2)                                   AS ingresos,
  ROUND(SAFE_DIVIDE(SUM(oi.sale_price), COUNT(DISTINCT oi.order_id)), 2) AS ticket_medio
FROM `bigquery-public-data.thelook_ecommerce.order_items` AS oi
JOIN `bigquery-public-data.thelook_ecommerce.products` AS p
  ON oi.product_id = p.id
WHERE oi.status NOT IN ('Cancelled', 'Returned')
  AND EXTRACT(YEAR FROM oi.created_at) = 2024
GROUP BY marca
ORDER BY ingresos DESC
LIMIT 10;


-- ---------------------------------------------------------------------
-- 3.6 · Catálogo que no se vende   ⭐⭐⭐
-- Repasa: bloques 2 + 3
-- ---------------------------------------------------------------------
-- Para cada categoría muestra: productos en catálogo, productos que nunca
-- se han vendido y qué % del catálogo representan.

SELECT
  p.category                                                    AS categoria,
  COUNT(*)                                                      AS productos,
  COUNTIF(v.product_id IS NULL)                                 AS nunca_vendidos,
  ROUND(SAFE_DIVIDE(COUNTIF(v.product_id IS NULL), COUNT(*)) * 100, 1) AS pct_sin_ventas
FROM `bigquery-public-data.thelook_ecommerce.products` AS p
LEFT JOIN (
  SELECT DISTINCT product_id
  FROM `bigquery-public-data.thelook_ecommerce.order_items`
) AS v
  ON p.id = v.product_id
GROUP BY categoria
ORDER BY pct_sin_ventas DESC;

-- 💡 El DISTINCT en la subconsulta es clave: sin él, cada producto se repetiría una vez por venta (fan-out) y COUNT(*) dejaría de contar productos.
