-- =====================================================================
-- SOLUCIONES · BLOQUE 1 · FUNDAMENTOS
-- =====================================================================
-- Temas nuevos: SELECT, WHERE, NULLs, tipos de datos, fechas y CASE.
-- Los ejercicios usan solo el bloque 1: cada bloque repasa lo anterior.
--
-- Dificultad: ⭐ básico | ⭐⭐ medio | ⭐⭐⭐ reto
--
-- Hay muchas formas correctas de resolver cada ejercicio. Si tu
-- consulta devuelve lo mismo, está bien aunque sea distinta.
-- =====================================================================


-- ---------------------------------------------------------------------
-- 1.1 · Usuarios de España   ⭐
-- Repasa: bloque 1
-- ---------------------------------------------------------------------
-- Muestra nombre, apellido, edad y ciudad de los usuarios de España.
-- Ordénalos de mayor a menor edad y, a igualdad de edad, por apellido.
-- Devuelve solo 20 filas.

SELECT
  first_name,
  last_name,
  age,
  city
FROM `bigquery-public-data.thelook_ecommerce.users`
WHERE country = 'Spain'
ORDER BY age DESC, last_name ASC
LIMIT 20;


-- ---------------------------------------------------------------------
-- 1.2 · Margen de los productos caros   ⭐
-- Repasa: bloque 1
-- ---------------------------------------------------------------------
-- De los productos de las categorías 'Jeans' y 'Pants' con precio de venta
-- mayor que 100, muestra: nombre, marca, categoría, precio de venta,
-- margen (precio - coste) y margen en % redondeado a 1 decimal.
-- Ordena por margen % de mayor a menor.

SELECT
  name                                                AS producto,
  brand                                               AS marca,
  category                                            AS categoria,
  ROUND(retail_price, 2)                              AS precio_venta,
  ROUND(retail_price - cost, 2)                       AS margen,
  ROUND((retail_price - cost) / retail_price * 100, 1) AS margen_pct
FROM `bigquery-public-data.thelook_ecommerce.products`
WHERE category IN ('Jeans', 'Pants')
  AND retail_price > 100
ORDER BY margen_pct DESC;

-- 💡 No hace falta proteger la división: el filtro garantiza que retail_price > 100.


-- ---------------------------------------------------------------------
-- 1.3 · Pedidos enviados que no han llegado   ⭐⭐
-- Repasa: bloque 1
-- ---------------------------------------------------------------------
-- Lista los pedidos que ya se han enviado (shipped_at tiene valor)
-- pero que todavía no se han entregado ni devuelto.
-- Muestra order_id, status, la fecha de envío y cuántos días han pasado
-- desde el envío hasta hoy. Ordena por días de mayor a menor (20 filas).

SELECT
  order_id,
  status,
  DATE(shipped_at)                                  AS fecha_envio,
  DATE_DIFF(CURRENT_DATE(), DATE(shipped_at), DAY)  AS dias_desde_envio
FROM `bigquery-public-data.thelook_ecommerce.orders`
WHERE shipped_at IS NOT NULL
  AND delivered_at IS NULL
  AND returned_at IS NULL
ORDER BY dias_desde_envio DESC
LIMIT 20;

-- 💡 Al ser un dataset sintético, puede haber fechas futuras y días negativos. En datos reales sería una buena alerta de calidad (archivo 06).


-- ---------------------------------------------------------------------
-- 1.4 · Pedidos de marzo de 2024 en hora española   ⭐⭐
-- Repasa: bloque 1
-- ---------------------------------------------------------------------
-- Muestra los pedidos creados en marzo de 2024 según la hora de Madrid.
-- Columnas: order_id, fecha en Madrid, nombre del día de la semana,
-- lunes de esa semana y horas que pasaron entre la creación y el envío.

SELECT
  order_id,
  DATE(created_at, 'Europe/Madrid')                          AS fecha_madrid,
  FORMAT_DATE('%A', DATE(created_at, 'Europe/Madrid'))       AS dia_semana,
  DATE_TRUNC(DATE(created_at, 'Europe/Madrid'), WEEK(MONDAY)) AS lunes_de_la_semana,
  TIMESTAMP_DIFF(shipped_at, created_at, HOUR)               AS horas_hasta_envio
FROM `bigquery-public-data.thelook_ecommerce.orders`
WHERE DATE(created_at, 'Europe/Madrid') BETWEEN '2024-03-01' AND '2024-03-31'
ORDER BY fecha_madrid
LIMIT 50;

-- 💡 horas_hasta_envio sale NULL en los pedidos no enviados: cualquier operación con NULL da NULL.


-- ---------------------------------------------------------------------
-- 1.5 · Gamas de precio   ⭐
-- Repasa: bloque 1
-- ---------------------------------------------------------------------
-- Clasifica los productos en gamas según su precio de venta:
--   menos de 25 → 'Económico' | menos de 75 → 'Medio'
--   menos de 150 → 'Alto'     | el resto → 'Premium'
-- Añade otra columna que diga 'Mujer' si el departamento es 'Women'
-- y 'Hombre' en caso contrario. Muestra los 50 productos más caros.

SELECT
  name          AS producto,
  retail_price  AS precio,
  CASE
    WHEN retail_price < 25  THEN 'Económico'
    WHEN retail_price < 75  THEN 'Medio'
    WHEN retail_price < 150 THEN 'Alto'
    ELSE 'Premium'
  END AS gama,
  IF(department = 'Women', 'Mujer', 'Hombre') AS departamento
FROM `bigquery-public-data.thelook_ecommerce.products`
ORDER BY retail_price DESC
LIMIT 50;


-- ---------------------------------------------------------------------
-- 1.6 · La trampa del !=   ⭐⭐
-- Repasa: bloque 1
-- ---------------------------------------------------------------------
-- Un compañero quiere los pedidos que NO están completados y que no se
-- han devuelto, y escribe:
--
--     WHERE status != 'Complete' AND returned_at = NULL
--
-- La consulta no devuelve nada. Encuentra los dos problemas y corrígelos
-- para que, además, se incluyan los pedidos con status NULL si los hubiera.

SELECT
  order_id,
  status,
  returned_at
FROM `bigquery-public-data.thelook_ecommerce.orders`
WHERE status IS DISTINCT FROM 'Complete'   -- 1) incluye también los status NULL
  AND returned_at IS NULL                  -- 2) "= NULL" nunca es TRUE
LIMIT 50;

-- 💡 returned_at = NULL siempre da NULL, así que WHERE descarta todas las filas. Y != 'Complete' descarta en silencio los status NULL.


-- ---------------------------------------------------------------------
-- 1.7 · Fechas que llegan como texto   ⭐⭐
-- Repasa: bloque 1
-- ---------------------------------------------------------------------
-- Sin usar ninguna tabla, convierte el texto '26/10/2026' en una fecha y calcula:
-- el día de la semana, cuántos días faltan para el 31/12/2026 y el último
-- día de ese mes. Además, convierte a número los textos '1234' y '1.234'
-- sin que la consulta falle.

SELECT
  PARSE_DATE('%d/%m/%Y', '26/10/2026')                                     AS fecha,
  FORMAT_DATE('%A', PARSE_DATE('%d/%m/%Y', '26/10/2026'))                  AS dia_semana,
  DATE_DIFF(DATE '2026-12-31', PARSE_DATE('%d/%m/%Y', '26/10/2026'), DAY) AS dias_hasta_fin_de_anio,
  LAST_DAY(PARSE_DATE('%d/%m/%Y', '26/10/2026'))                           AS ultimo_dia_del_mes,
  SAFE_CAST('1234' AS INT64)                                               AS numero_ok,
  SAFE_CAST('1.234' AS INT64)                                              AS numero_mal;  -- NULL, no error

-- 💡 Repetir PARSE_DATE tantas veces es feo. En el bloque 5 verás cómo evitarlo con variables (DECLARE).
