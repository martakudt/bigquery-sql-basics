-- =====================================================================
-- SOLUCIONES · BLOQUE 5 · LO PROPIO DE BIGQUERY
-- =====================================================================
-- Temas nuevos: ARRAY, STRUCT, UNNEST, tablas comodín, GENERATE_DATE_ARRAY, PIVOT y UDFs.
-- Los ejercicios usan los bloques 1 a 5: cada bloque repasa lo anterior.
--
-- Dificultad: ⭐ básico | ⭐⭐ medio | ⭐⭐⭐ reto
--
-- Hay muchas formas correctas de resolver cada ejercicio. Si tu
-- consulta devuelve lo mismo, está bien aunque sea distinta.
-- =====================================================================


-- ---------------------------------------------------------------------
-- 5.1 · Categorías que compra cada cliente   ⭐⭐
-- Repasa: bloques 2 + 3 + 5
-- ---------------------------------------------------------------------
-- Para cada cliente, construye un ARRAY con las categorías distintas que
-- ha comprado (ordenadas alfabéticamente) y cuántas son. Muestra los 20
-- clientes con más categorías distintas (mínimo 3).

SELECT
  oi.user_id,
  COUNT(DISTINCT p.category)                           AS num_categorias,
  ARRAY_AGG(DISTINCT p.category ORDER BY p.category)   AS categorias
FROM `bigquery-public-data.thelook_ecommerce.order_items` AS oi
JOIN `bigquery-public-data.thelook_ecommerce.products` AS p
  ON oi.product_id = p.id
WHERE p.category IS NOT NULL
GROUP BY oi.user_id
HAVING COUNT(DISTINCT p.category) >= 3
ORDER BY num_categorias DESC
LIMIT 20;


-- ---------------------------------------------------------------------
-- 5.2 · Páginas más vistas en móvil   ⭐⭐
-- Repasa: bloques 1 + 2 + 5
-- ---------------------------------------------------------------------
-- Usando la tabla ga_sessions_20170801, muestra las 10 páginas más vistas
-- desde dispositivos móviles.

SELECT
  h.page.pagePath  AS pagina,
  COUNT(*)         AS vistas
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170801` AS s,
  UNNEST(s.hits) AS h
WHERE s.device.deviceCategory = 'mobile'
  AND h.type = 'PAGE'
GROUP BY pagina
ORDER BY vistas DESC
LIMIT 10;


-- ---------------------------------------------------------------------
-- 5.3 · Conversión por dispositivo en julio de 2017   ⭐⭐
-- Repasa: bloques 1 + 2 + 5
-- ---------------------------------------------------------------------
-- Con la tabla comodín ga_sessions_*, calcula para julio de 2017 y por tipo
-- de dispositivo: sesiones, sesiones con compra, tasa de conversión en %
-- y páginas vistas medias por sesión.

SELECT
  device.deviceCategory                                        AS dispositivo,
  COUNT(*)                                                     AS sesiones,
  COUNTIF(totals.transactions > 0)                             AS sesiones_con_compra,
  ROUND(SAFE_DIVIDE(COUNTIF(totals.transactions > 0), COUNT(*)) * 100, 2) AS conversion_pct,
  ROUND(AVG(totals.pageviews), 1)                              AS paginas_por_sesion
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
WHERE _TABLE_SUFFIX BETWEEN '20170701' AND '20170731'
GROUP BY dispositivo
ORDER BY sesiones DESC;

-- 💡 Cuando totals.transactions es NULL, la condición > 0 da NULL y COUNTIF no la cuenta. Aquí es el comportamiento que queremos.


-- ---------------------------------------------------------------------
-- 5.4 · ¿Los que ven el carrito compran más?   ⭐⭐⭐
-- Repasa: bloques 2 + 4 + 5
-- ---------------------------------------------------------------------
-- Para la primera semana de julio de 2017, compara la tasa de conversión
-- de las sesiones que visitaron alguna página con 'basket' en la URL
-- frente a las que no. Mantén una fila por sesión (sin desplegar los hits).

WITH sesiones AS (
  SELECT
    EXISTS(
      SELECT 1 FROM UNNEST(hits) AS h
      WHERE h.page.pagePath LIKE '%basket%'
    )                                  AS vio_carrito,
    IFNULL(totals.transactions, 0) > 0 AS compro
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE _TABLE_SUFFIX BETWEEN '20170701' AND '20170707'
)
SELECT
  vio_carrito,
  COUNT(*)                                                   AS sesiones,
  COUNTIF(compro)                                            AS compras,
  ROUND(SAFE_DIVIDE(COUNTIF(compro), COUNT(*)) * 100, 2)     AS conversion_pct
FROM sesiones
GROUP BY vio_carrito;


-- ---------------------------------------------------------------------
-- 5.5 · Serie diaria sin huecos   ⭐⭐⭐
-- Repasa: bloques 1 + 2 + 3 + 4 + 5
-- ---------------------------------------------------------------------
-- Calcula las unidades vendidas cada día de la categoría 'Clothing Sets'
-- en el primer trimestre de 2024, incluyendo los días sin ventas (con 0),
-- y añade la media móvil de 7 días.

WITH calendario AS (
  SELECT dia
  FROM UNNEST(GENERATE_DATE_ARRAY('2024-01-01', '2024-03-31')) AS dia
),
ventas AS (
  SELECT
    DATE(oi.created_at) AS dia,
    COUNT(*)            AS unidades
  FROM `bigquery-public-data.thelook_ecommerce.order_items` AS oi
  JOIN `bigquery-public-data.thelook_ecommerce.products` AS p
    ON oi.product_id = p.id
  WHERE p.category = 'Clothing Sets'
    AND DATE(oi.created_at) BETWEEN '2024-01-01' AND '2024-03-31'
  GROUP BY dia
)
SELECT
  c.dia,
  COALESCE(v.unidades, 0) AS unidades,
  ROUND(AVG(COALESCE(v.unidades, 0)) OVER (
    ORDER BY c.dia ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
  ), 2)                   AS media_movil_7d
FROM calendario AS c
LEFT JOIN ventas AS v
  ON c.dia = v.dia
ORDER BY c.dia;

-- 💡 Ahora sí: como el calendario tiene todos los días, '6 filas atrás' son exactamente 6 días.


-- ---------------------------------------------------------------------
-- 5.6 · Ingresos por año y departamento con PIVOT   ⭐⭐
-- Repasa: bloques 2 + 3 + 5
-- ---------------------------------------------------------------------
-- Muestra una tabla con una fila por año y dos columnas, ingresos de
-- hombre y de mujer (sin cancelados ni devueltos), redondeadas sin decimales.

SELECT
  anio,
  ROUND(Men, 0)   AS ingresos_hombre,
  ROUND(Women, 0) AS ingresos_mujer
FROM (
  SELECT
    EXTRACT(YEAR FROM oi.created_at) AS anio,
    p.department,
    oi.sale_price
  FROM `bigquery-public-data.thelook_ecommerce.order_items` AS oi
  JOIN `bigquery-public-data.thelook_ecommerce.products` AS p
    ON oi.product_id = p.id
  WHERE oi.status NOT IN ('Cancelled', 'Returned')
)
PIVOT (SUM(sale_price) FOR department IN ('Men', 'Women'))
ORDER BY anio;


-- ---------------------------------------------------------------------
-- 5.7 · Reutiliza lógica con una función   ⭐⭐
-- Repasa: bloques 1 + 2 + 5
-- ---------------------------------------------------------------------
-- Crea una función temporal gama_precio(precio) con las gamas del
-- ejercicio 1.5 y úsala para mostrar, por gama: productos, precio medio
-- y margen medio en %.

CREATE TEMP FUNCTION gama_precio(precio FLOAT64) AS (
  CASE
    WHEN precio < 25  THEN 'Económico'
    WHEN precio < 75  THEN 'Medio'
    WHEN precio < 150 THEN 'Alto'
    ELSE 'Premium'
  END
);

SELECT
  gama_precio(retail_price)                                  AS gama,
  COUNT(*)                                                   AS productos,
  ROUND(AVG(retail_price), 2)                                AS precio_medio,
  ROUND(AVG((retail_price - cost) / retail_price) * 100, 1)  AS margen_medio_pct
FROM `bigquery-public-data.thelook_ecommerce.products`
GROUP BY gama
ORDER BY precio_medio;

-- 💡 Ventaja: si mañana cambian los cortes de las gamas, solo tocas la función.
