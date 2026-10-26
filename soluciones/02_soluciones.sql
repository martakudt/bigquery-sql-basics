-- =====================================================================
-- SOLUCIONES · BLOQUE 2 · AGREGACIONES
-- =====================================================================
-- Temas nuevos: GROUP BY, HAVING, COUNTIF, SAFE_DIVIDE, percentiles y STRING_AGG.
-- Los ejercicios usan los bloques 1 a 2: cada bloque repasa lo anterior.
--
-- Dificultad: ⭐ básico | ⭐⭐ medio | ⭐⭐⭐ reto
--
-- Hay muchas formas correctas de resolver cada ejercicio. Si tu
-- consulta devuelve lo mismo, está bien aunque sea distinta.
-- =====================================================================


-- ---------------------------------------------------------------------
-- 2.1 · Países con más usuarios   ⭐
-- Repasa: bloque 2
-- ---------------------------------------------------------------------
-- Muestra los 10 países con más usuarios, junto con la edad media
-- (redondeada a 1 decimal) y la edad mínima y máxima.

SELECT
  country,
  COUNT(*)           AS usuarios,
  ROUND(AVG(age), 1) AS edad_media,
  MIN(age)           AS edad_min,
  MAX(age)           AS edad_max
FROM `bigquery-public-data.thelook_ecommerce.users`
GROUP BY country
ORDER BY usuarios DESC
LIMIT 10;


-- ---------------------------------------------------------------------
-- 2.2 · Tasa de cancelación mensual   ⭐⭐
-- Repasa: bloques 1 + 2
-- ---------------------------------------------------------------------
-- Para cada mes de 2024 (hora de Madrid) calcula: pedidos totales,
-- completados, cancelados y % de cancelación con 2 decimales.

SELECT
  DATE_TRUNC(DATE(created_at, 'Europe/Madrid'), MONTH) AS mes,
  COUNT(*)                                             AS pedidos,
  COUNTIF(status = 'Complete')                         AS completados,
  COUNTIF(status = 'Cancelled')                        AS cancelados,
  ROUND(SAFE_DIVIDE(COUNTIF(status = 'Cancelled'), COUNT(*)) * 100, 2) AS pct_cancelacion
FROM `bigquery-public-data.thelook_ecommerce.orders`
WHERE DATE(created_at, 'Europe/Madrid') BETWEEN '2024-01-01' AND '2024-12-31'
GROUP BY mes
ORDER BY mes;


-- ---------------------------------------------------------------------
-- 2.3 · Categorías con mejor margen   ⭐⭐
-- Repasa: bloques 1 + 2
-- ---------------------------------------------------------------------
-- Calcula el margen medio en % de cada categoría de producto.
-- Muestra solo las categorías con al menos 200 productos, ordenadas
-- de mayor a menor margen.

SELECT
  category                                                AS categoria,
  COUNT(*)                                                AS productos,
  ROUND(AVG((retail_price - cost) / retail_price) * 100, 1) AS margen_medio_pct
FROM `bigquery-public-data.thelook_ecommerce.products`
WHERE category IS NOT NULL
GROUP BY categoria
HAVING COUNT(*) >= 200
ORDER BY margen_medio_pct DESC;

-- 💡 WHERE quita filas antes de agrupar; HAVING quita grupos después.


-- ---------------------------------------------------------------------
-- 2.4 · Perfil por tramo de edad   ⭐⭐
-- Repasa: bloques 1 + 2
-- ---------------------------------------------------------------------
-- Agrupa a los usuarios en los tramos '18-24', '25-34', '35-49' y '50+'.
-- Para cada tramo muestra: usuarios, mujeres, % de mujeres y cuántos
-- llegaron por 'Search'.

SELECT
  CASE
    WHEN age < 25 THEN '18-24'
    WHEN age < 35 THEN '25-34'
    WHEN age < 50 THEN '35-49'
    ELSE '50+'
  END                                                         AS tramo_edad,
  COUNT(*)                                                    AS usuarios,
  COUNTIF(gender = 'F')                                       AS mujeres,
  ROUND(SAFE_DIVIDE(COUNTIF(gender = 'F'), COUNT(*)) * 100, 1) AS pct_mujeres,
  COUNTIF(traffic_source = 'Search')                          AS desde_search
FROM `bigquery-public-data.thelook_ecommerce.users`
GROUP BY tramo_edad
ORDER BY tramo_edad;


-- ---------------------------------------------------------------------
-- 2.5 · Media vs mediana   ⭐⭐
-- Repasa: bloque 2
-- ---------------------------------------------------------------------
-- Para cada estado de las líneas de pedido (order_items.status) calcula:
-- número de líneas, precio medio, precio mediano, percentil 90 y precio máximo.
-- ¿Se parecen la media y la mediana?

SELECT
  status,
  COUNT(*)                                       AS lineas,
  ROUND(AVG(sale_price), 2)                      AS precio_medio,
  APPROX_QUANTILES(sale_price, 100)[OFFSET(50)]  AS precio_mediano,
  APPROX_QUANTILES(sale_price, 100)[OFFSET(90)]  AS percentil_90,
  MAX(sale_price)                                AS precio_max
FROM `bigquery-public-data.thelook_ecommerce.order_items`
GROUP BY status
ORDER BY lineas DESC;

-- 💡 Si la media es bastante mayor que la mediana, hay unos pocos productos muy caros tirando de ella hacia arriba.


-- ---------------------------------------------------------------------
-- 2.6 · Tiempo de entrega por mes   ⭐⭐⭐
-- Repasa: bloques 1 + 2
-- ---------------------------------------------------------------------
-- Para cada mes de 2024 calcula: pedidos creados, pedidos entregados,
-- pedidos sin entregar, media de días hasta la entrega y máximo de días.
-- Pregunta extra: ¿sobre qué pedidos se calcula exactamente la media?

SELECT
  DATE_TRUNC(DATE(created_at), MONTH)                                AS mes,
  COUNT(*)                                                           AS pedidos,
  COUNT(delivered_at)                                                AS entregados,
  COUNTIF(delivered_at IS NULL)                                      AS sin_entregar,
  ROUND(AVG(DATE_DIFF(DATE(delivered_at), DATE(created_at), DAY)), 1) AS media_dias_entrega,
  MAX(DATE_DIFF(DATE(delivered_at), DATE(created_at), DAY))          AS max_dias_entrega
FROM `bigquery-public-data.thelook_ecommerce.orders`
WHERE EXTRACT(YEAR FROM created_at) = 2024
GROUP BY mes
ORDER BY mes;

-- 💡 Respuesta extra: AVG ignora los NULL, así que la media se calcula SOLO sobre los pedidos entregados. Por eso conviene mostrar también cuántos son.


-- ---------------------------------------------------------------------
-- 2.7 · Ciudades por país   ⭐⭐
-- Repasa: bloque 2
-- ---------------------------------------------------------------------
-- Muestra los 10 países con más ciudades distintas, el número de
-- ciudades y una lista con las 5 primeras en orden alfabético.

SELECT
  country,
  COUNT(DISTINCT city)                                    AS ciudades,
  STRING_AGG(DISTINCT city, ', ' ORDER BY city LIMIT 5)   AS primeras_ciudades
FROM `bigquery-public-data.thelook_ecommerce.users`
WHERE city IS NOT NULL
GROUP BY country
ORDER BY ciudades DESC
LIMIT 10;
