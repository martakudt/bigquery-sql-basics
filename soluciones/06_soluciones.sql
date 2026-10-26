-- =====================================================================
-- SOLUCIONES · BLOQUE 6 · BUENAS PRÁCTICAS
-- =====================================================================
-- Temas nuevos: validación de datos, refactorización y un informe completo.
-- Los ejercicios usan los bloques 1 a 6: cada bloque repasa lo anterior.
--
-- Dificultad: ⭐ básico | ⭐⭐ medio | ⭐⭐⭐ reto
--
-- Hay muchas formas correctas de resolver cada ejercicio. Si tu
-- consulta devuelve lo mismo, está bien aunque sea distinta.
-- =====================================================================


-- ---------------------------------------------------------------------
-- 6.1 · ¿Son únicas las claves?   ⭐
-- Repasa: bloques 2 + 6
-- ---------------------------------------------------------------------
-- En una sola consulta, comprueba si son únicos users.id, products.id,
-- orders.order_id y order_items.id. Para cada uno muestra filas y valores
-- distintos.

SELECT
  (SELECT COUNT(*) FROM `bigquery-public-data.thelook_ecommerce.users`)                          AS filas_users,
  (SELECT COUNT(DISTINCT id) FROM `bigquery-public-data.thelook_ecommerce.users`)                AS ids_users,
  (SELECT COUNT(*) FROM `bigquery-public-data.thelook_ecommerce.products`)                       AS filas_products,
  (SELECT COUNT(DISTINCT id) FROM `bigquery-public-data.thelook_ecommerce.products`)             AS ids_products,
  (SELECT COUNT(*) FROM `bigquery-public-data.thelook_ecommerce.orders`)                         AS filas_orders,
  (SELECT COUNT(DISTINCT order_id) FROM `bigquery-public-data.thelook_ecommerce.orders`)         AS ids_orders,
  (SELECT COUNT(*) FROM `bigquery-public-data.thelook_ecommerce.order_items`)                    AS filas_order_items,
  (SELECT COUNT(DISTINCT id) FROM `bigquery-public-data.thelook_ecommerce.order_items`)          AS ids_order_items;

-- 💡 Si en cada pareja filas = ids, la clave es única y puedes unir por ella sin miedo al fan-out.


-- ---------------------------------------------------------------------
-- 6.2 · ¿Cuadran pedidos y líneas?   ⭐⭐
-- Repasa: bloques 2 + 3 + 4 + 6
-- ---------------------------------------------------------------------
-- orders.num_of_item debería coincidir con el número de líneas de ese
-- pedido en order_items. Calcula: total de pedidos, pedidos sin ninguna
-- línea y pedidos en los que no cuadra el número de líneas.

WITH lineas_por_pedido AS (
  SELECT
    order_id,
    COUNT(*) AS lineas
  FROM `bigquery-public-data.thelook_ecommerce.order_items`
  GROUP BY order_id
)
SELECT
  COUNT(*)                                                       AS pedidos,
  COUNTIF(l.order_id IS NULL)                                    AS pedidos_sin_lineas,
  COUNTIF(l.order_id IS NOT NULL AND o.num_of_item != l.lineas)  AS pedidos_que_no_cuadran
FROM `bigquery-public-data.thelook_ecommerce.orders` AS o
LEFT JOIN lineas_por_pedido AS l
  ON o.order_id = l.order_id;


-- ---------------------------------------------------------------------
-- 6.3 · Detecta datos imposibles   ⭐⭐
-- Repasa: bloques 1 + 2 + 6
-- ---------------------------------------------------------------------
-- Revisa order_items y cuenta cuántas líneas tienen: precio menor o igual
-- a 0, fecha de envío anterior a la de creación, fecha de entrega anterior a
-- la de envío y fecha de creación en el futuro.

SELECT
  COUNT(*)                                       AS lineas,
  COUNTIF(sale_price <= 0)                       AS precio_no_positivo,
  COUNTIF(shipped_at < created_at)               AS enviado_antes_de_crear,
  COUNTIF(delivered_at < shipped_at)             AS entregado_antes_de_enviar,
  COUNTIF(created_at > CURRENT_TIMESTAMP())      AS creado_en_el_futuro
FROM `bigquery-public-data.thelook_ecommerce.order_items`;

-- 💡 Si alguna columna sale distinta de 0, antes de seguir con el análisis toca averiguar por qué.


-- ---------------------------------------------------------------------
-- 6.4 · Refactoriza esta consulta   ⭐⭐
-- Repasa: bloques 1 + 2 + 3 + 4 + 6
-- ---------------------------------------------------------------------
-- Esta consulta funciona, pero es difícil de leer. Reescríbela aplicando
-- las buenas prácticas del archivo 06: formato, CTEs con buenos nombres,
-- alias claros y comentarios del porqué. El resultado debe ser el mismo.
--
--     select x.country, x.c, x.r from (select u.country, count(distinct o.order_id) c,
--     sum(oi.sale_price) r from `bigquery-public-data.thelook_ecommerce.users` u join `bigquery-public-data.thelook_ecommerce.orders` o
--     on u.id=o.user_id join `bigquery-public-data.thelook_ecommerce.order_items` oi on o.order_id=oi.order_id
--     where o.status='Complete' and extract(year from o.created_at)=2024 group by 1) x
--     where x.c>100 order by 3 desc

-- Países con más de 100 pedidos completados en 2024, ordenados por ingresos
WITH pedidos_completados_2024 AS (
  SELECT
    order_id,
    user_id
  FROM `bigquery-public-data.thelook_ecommerce.orders`
  WHERE status = 'Complete'                    -- solo cuentan las ventas cerradas
    AND EXTRACT(YEAR FROM created_at) = 2024
)
SELECT
  u.country                      AS pais,
  COUNT(DISTINCT p.order_id)     AS pedidos,
  ROUND(SUM(oi.sale_price), 2)   AS ingresos
FROM pedidos_completados_2024 AS p
JOIN `bigquery-public-data.thelook_ecommerce.users` AS u
  ON p.user_id = u.id
JOIN `bigquery-public-data.thelook_ecommerce.order_items` AS oi
  ON p.order_id = oi.order_id
GROUP BY pais
HAVING COUNT(DISTINCT p.order_id) > 100        -- descarta países con poco volumen
ORDER BY ingresos DESC;

-- 💡 La consulta original no tenía fan-out: contaba pedidos con DISTINCT y sumaba un importe de la tabla con más detalle. Comprobarlo forma parte de refactorizar.


-- ---------------------------------------------------------------------
-- 6.5 · Proyecto final: informe mensual de 2024   ⭐⭐⭐
-- Repasa: bloques 1 + 2 + 3 + 4 + 5 + 6
-- ---------------------------------------------------------------------
-- Construye un informe con una fila por mes de 2024 (hora de Madrid,
-- sin líneas canceladas ni devueltas) con estas columnas:
--   ingresos | pedidos | ticket medio | clientes activos | clientes nuevos
--   crecimiento de ingresos vs mes anterior (%) | categoría con más ingresos
-- Un cliente es "nuevo" en el mes de su primera compra válida (de toda la
-- historia, no solo de 2024).

WITH
ventas_validas AS (
  SELECT
    oi.order_id,
    oi.user_id,
    oi.sale_price,
    p.category,
    DATE_TRUNC(DATE(oi.created_at, 'Europe/Madrid'), MONTH) AS mes
  FROM `bigquery-public-data.thelook_ecommerce.order_items` AS oi
  JOIN `bigquery-public-data.thelook_ecommerce.products` AS p
    ON oi.product_id = p.id
  WHERE oi.status NOT IN ('Cancelled', 'Returned')
),
primer_mes_cliente AS (
  SELECT
    user_id,
    MIN(mes) AS primer_mes
  FROM ventas_validas
  GROUP BY user_id
),
resumen_mes AS (
  SELECT
    v.mes,
    SUM(v.sale_price)                                       AS ingresos,
    COUNT(DISTINCT v.order_id)                              AS pedidos,
    COUNT(DISTINCT v.user_id)                               AS clientes_activos,
    COUNT(DISTINCT IF(v.mes = c.primer_mes, v.user_id, NULL)) AS clientes_nuevos
  FROM ventas_validas AS v
  JOIN primer_mes_cliente AS c
    ON v.user_id = c.user_id
  GROUP BY v.mes
),
categoria_top AS (
  SELECT
    mes,
    category
  FROM ventas_validas
  GROUP BY mes, category
  QUALIFY ROW_NUMBER() OVER (PARTITION BY mes ORDER BY SUM(sale_price) DESC) = 1
),
informe AS (
  SELECT
    r.mes,
    ROUND(r.ingresos, 0)                                    AS ingresos,
    r.pedidos,
    ROUND(SAFE_DIVIDE(r.ingresos, r.pedidos), 2)            AS ticket_medio,
    r.clientes_activos,
    r.clientes_nuevos,
    ROUND(SAFE_DIVIDE(r.ingresos - LAG(r.ingresos) OVER (ORDER BY r.mes),
                      LAG(r.ingresos) OVER (ORDER BY r.mes)) * 100, 1) AS crecimiento_pct,
    t.category                                              AS categoria_top
  FROM resumen_mes AS r
  JOIN categoria_top AS t
    ON r.mes = t.mes
)
SELECT *
FROM informe
WHERE mes BETWEEN '2024-01-01' AND '2024-12-01'   -- filtramos al final para que enero tenga crecimiento
ORDER BY mes;

-- 💡 Si has llegado hasta aquí, has usado prácticamente todo lo del repo: fechas con zona horaria, agregaciones condicionales, JOINs sin fan-out, CTEs, window functions y QUALIFY. ¡Enhorabuena!
