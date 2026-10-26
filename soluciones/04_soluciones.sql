-- =====================================================================
-- SOLUCIONES · BLOQUE 4 · CTEs Y WINDOW FUNCTIONS
-- =====================================================================
-- Temas nuevos: WITH, ROW_NUMBER, RANK, QUALIFY, LAG/LEAD, acumulados y medias móviles.
-- Los ejercicios usan los bloques 1 a 4: cada bloque repasa lo anterior.
--
-- Dificultad: ⭐ básico | ⭐⭐ medio | ⭐⭐⭐ reto
--
-- Hay muchas formas correctas de resolver cada ejercicio. Si tu
-- consulta devuelve lo mismo, está bien aunque sea distinta.
-- =====================================================================


-- ---------------------------------------------------------------------
-- 4.1 · Nuevos clientes por mes   ⭐⭐
-- Repasa: bloques 1 + 2 + 4
-- ---------------------------------------------------------------------
-- Encuentra el primer pedido de cada cliente usando QUALIFY y, a partir
-- de ahí, cuenta cuántos clientes nuevos hubo cada mes de 2024.

WITH primer_pedido AS (
  SELECT
    user_id,
    created_at
  FROM `bigquery-public-data.thelook_ecommerce.orders`
  WHERE TRUE
  QUALIFY ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY created_at, order_id) = 1
)
SELECT
  DATE_TRUNC(DATE(created_at, 'Europe/Madrid'), MONTH) AS mes,
  COUNT(*)                                             AS clientes_nuevos
FROM primer_pedido
WHERE DATE(created_at, 'Europe/Madrid') BETWEEN '2024-01-01' AND '2024-12-31'
GROUP BY mes
ORDER BY mes;

-- 💡 Fíjate en que el filtro de 2024 va DESPUÉS de encontrar el primer pedido. Si filtras antes, un cliente de 2023 que repite en 2024 contaría como nuevo.


-- ---------------------------------------------------------------------
-- 4.2 · Top 3 productos de cada categoría   ⭐⭐
-- Repasa: bloques 2 + 3 + 4
-- ---------------------------------------------------------------------
-- Para cada categoría, muestra los 3 productos con más ingresos
-- (sin cancelados ni devueltos) y su puesto en el ranking.

WITH ventas_producto AS (
  SELECT
    p.category,
    p.id    AS product_id,
    p.name,
    SUM(oi.sale_price) AS ingresos
  FROM `bigquery-public-data.thelook_ecommerce.order_items` AS oi
  JOIN `bigquery-public-data.thelook_ecommerce.products` AS p
    ON oi.product_id = p.id
  WHERE oi.status NOT IN ('Cancelled', 'Returned')
  GROUP BY p.category, product_id, p.name
)
SELECT
  category                                                    AS categoria,
  name                                                        AS producto,
  ROUND(ingresos, 2)                                          AS ingresos,
  DENSE_RANK() OVER (PARTITION BY category ORDER BY ingresos DESC) AS puesto
FROM ventas_producto
WHERE TRUE
QUALIFY puesto <= 3
ORDER BY categoria, puesto;

-- 💡 Agrupamos por product_id además de por name: dos productos distintos podrían llamarse igual.


-- ---------------------------------------------------------------------
-- 4.3 · ¿Cada cuánto vuelven a comprar?   ⭐⭐⭐
-- Repasa: bloques 1 + 2 + 3 + 4
-- ---------------------------------------------------------------------
-- Calcula la media de días entre pedidos consecutivos de un mismo cliente,
-- por país. Muestra solo países con al menos 100 recompras, ordenados de
-- los que vuelven antes a los que tardan más.

WITH pedidos AS (
  SELECT
    o.user_id,
    u.country,
    DATE(o.created_at) AS fecha,
    LAG(DATE(o.created_at)) OVER (PARTITION BY o.user_id ORDER BY o.created_at) AS fecha_anterior
  FROM `bigquery-public-data.thelook_ecommerce.orders` AS o
  JOIN `bigquery-public-data.thelook_ecommerce.users` AS u
    ON o.user_id = u.id
)
SELECT
  country,
  COUNT(*)                                              AS recompras,
  ROUND(AVG(DATE_DIFF(fecha, fecha_anterior, DAY)), 1)  AS media_dias_entre_pedidos
FROM pedidos
WHERE fecha_anterior IS NOT NULL
GROUP BY country
HAVING COUNT(*) >= 100
ORDER BY media_dias_entre_pedidos;


-- ---------------------------------------------------------------------
-- 4.4 · Crecimiento mensual y acumulado   ⭐⭐
-- Repasa: bloques 1 + 2 + 4
-- ---------------------------------------------------------------------
-- Para cada mes de 2024 muestra los ingresos (sin cancelados ni devueltos),
-- los ingresos del mes anterior, el crecimiento en % y el acumulado del año.

WITH ingresos_mes AS (
  SELECT
    DATE_TRUNC(DATE(created_at), MONTH) AS mes,
    SUM(sale_price)                     AS ingresos
  FROM `bigquery-public-data.thelook_ecommerce.order_items`
  WHERE status NOT IN ('Cancelled', 'Returned')
    AND EXTRACT(YEAR FROM created_at) = 2024
  GROUP BY mes
)
SELECT
  mes,
  ROUND(ingresos, 0)                                 AS ingresos,
  ROUND(LAG(ingresos) OVER (ORDER BY mes), 0)        AS ingresos_mes_anterior,
  ROUND(SAFE_DIVIDE(ingresos - LAG(ingresos) OVER (ORDER BY mes),
                    LAG(ingresos) OVER (ORDER BY mes)) * 100, 1) AS crecimiento_pct,
  ROUND(SUM(ingresos) OVER (ORDER BY mes), 0)        AS acumulado_anual
FROM ingresos_mes
ORDER BY mes;

-- 💡 Enero sale con crecimiento NULL porque filtramos 2024 antes del LAG. Si quieres comparar con diciembre de 2023, incluye 2023 en la CTE y filtra al final.


-- ---------------------------------------------------------------------
-- 4.5 · Media móvil de pedidos   ⭐⭐
-- Repasa: bloques 1 + 2 + 4
-- ---------------------------------------------------------------------
-- Calcula los pedidos diarios de 2024 y su media móvil de 7 días.
-- Añade una columna que marque con 'Pico' los días en los que hubo más
-- de un 30% de pedidos por encima de la media móvil.

WITH pedidos_dia AS (
  SELECT
    DATE(created_at) AS dia,
    COUNT(*)         AS pedidos
  FROM `bigquery-public-data.thelook_ecommerce.orders`
  WHERE EXTRACT(YEAR FROM created_at) = 2024
  GROUP BY dia
),
con_media AS (
  SELECT
    dia,
    pedidos,
    AVG(pedidos) OVER (ORDER BY dia ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS media_7d
  FROM pedidos_dia
)
SELECT
  dia,
  pedidos,
  ROUND(media_7d, 1)                                AS media_7d,
  IF(pedidos > media_7d * 1.3, 'Pico', NULL)        AS alerta
FROM con_media
ORDER BY dia;

-- 💡 Si algún día no hubiera pedidos, faltaría en pedidos_dia y la media de '7 filas' no serían 7 días. En el bloque 5 aprenderás a rellenar esos huecos.


-- ---------------------------------------------------------------------
-- 4.6 · Peso de cada categoría en su departamento   ⭐⭐
-- Repasa: bloques 2 + 3 + 4
-- ---------------------------------------------------------------------
-- Calcula los ingresos de cada categoría y qué % representan dentro de su
-- departamento (Men / Women). Ordena por departamento y peso.

SELECT
  p.department                                       AS departamento,
  p.category                                         AS categoria,
  ROUND(SUM(oi.sale_price), 0)                       AS ingresos,
  ROUND(SUM(oi.sale_price)
        / SUM(SUM(oi.sale_price)) OVER (PARTITION BY p.department) * 100, 2) AS pct_del_departamento
FROM `bigquery-public-data.thelook_ecommerce.order_items` AS oi
JOIN `bigquery-public-data.thelook_ecommerce.products` AS p
  ON oi.product_id = p.id
WHERE oi.status NOT IN ('Cancelled', 'Returned')
GROUP BY departamento, categoria
ORDER BY departamento, pct_del_departamento DESC;


-- ---------------------------------------------------------------------
-- 4.7 · Clientes que repiten rápido   ⭐⭐⭐
-- Repasa: bloques 1 + 2 + 4
-- ---------------------------------------------------------------------
-- Para los clientes cuyo primer pedido (no cancelado) fue en 2024, calcula
-- por mes del primer pedido: clientes nuevos, cuántos hicieron un segundo
-- pedido en 30 días o menos y qué % representan.

WITH pedidos_numerados AS (
  SELECT
    user_id,
    created_at,
    ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY created_at, order_id) AS n_pedido,
    LEAD(created_at) OVER (PARTITION BY user_id ORDER BY created_at, order_id) AS siguiente_pedido
  FROM `bigquery-public-data.thelook_ecommerce.orders`
  WHERE status != 'Cancelled'
)
SELECT
  DATE_TRUNC(DATE(created_at), MONTH)                                   AS mes_primer_pedido,
  COUNT(*)                                                              AS clientes_nuevos,
  COUNTIF(TIMESTAMP_DIFF(siguiente_pedido, created_at, DAY) <= 30)      AS repiten_en_30_dias,
  ROUND(SAFE_DIVIDE(COUNTIF(TIMESTAMP_DIFF(siguiente_pedido, created_at, DAY) <= 30),
                    COUNT(*)) * 100, 1)                                 AS pct_repiten
FROM pedidos_numerados
WHERE n_pedido = 1
  AND EXTRACT(YEAR FROM created_at) = 2024
GROUP BY mes_primer_pedido
ORDER BY mes_primer_pedido;

-- 💡 Los clientes sin segundo pedido tienen siguiente_pedido NULL; la condición da NULL y COUNTIF no los cuenta, que es justo lo que queremos.
