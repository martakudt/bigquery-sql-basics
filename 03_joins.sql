-- =====================================================================
-- 03 · JOINS: COMBINAR TABLAS SIN DUPLICAR NI PERDER DATOS
-- =====================================================================
-- Dataset: bigquery-public-data.thelook_ecommerce
--
-- Modelo de datos simplificado:
--   users (id) ──< orders (order_id, user_id) ──< order_items (order_id, product_id) >── products (id)
--
-- Un usuario tiene muchos pedidos; un pedido tiene muchas líneas;
-- cada línea apunta a un producto.
-- =====================================================================


-- ---------------------------------------------------------------------
-- 1. INNER JOIN: SOLO LO QUE COINCIDE EN AMBAS TABLAS
-- ---------------------------------------------------------------------
SELECT
  o.order_id,
  o.status,
  u.first_name,
  u.country
FROM `bigquery-public-data.thelook_ecommerce.orders` AS o
INNER JOIN `bigquery-public-data.thelook_ecommerce.users` AS u
  ON o.user_id = u.id
LIMIT 20;

-- 💡 Usa siempre alias cortos (o, u, oi, p) y prefija TODAS las columnas.
--    Cuando la consulta crece, agradecerás saber de qué tabla viene cada una.


-- ---------------------------------------------------------------------
-- 2. LEFT JOIN: TODO LO DE LA IZQUIERDA, AUNQUE NO TENGA PAREJA
-- ---------------------------------------------------------------------
-- Todos los usuarios, tengan o no pedidos:
SELECT
  u.id                       AS user_id,
  u.first_name,
  COUNT(o.order_id)          AS num_pedidos     -- COUNT(o.order_id), NO COUNT(*)
FROM `bigquery-public-data.thelook_ecommerce.users` AS u
LEFT JOIN `bigquery-public-data.thelook_ecommerce.orders` AS o
  ON u.id = o.user_id
GROUP BY user_id, u.first_name
ORDER BY num_pedidos ASC
LIMIT 20;

-- 💡 Con LEFT JOIN, COUNT(*) contaría 1 para los usuarios sin pedidos
--    (la fila existe, con columnas de orders a NULL). COUNT(o.order_id)
--    cuenta 0, que es lo correcto.


-- ---------------------------------------------------------------------
-- 3. LA TRAMPA DEL LEFT JOIN: FILTRAR EN ON vs EN WHERE
-- ---------------------------------------------------------------------
-- Quiero TODOS los usuarios y sus pedidos COMPLETADOS (si los tienen).

-- ❌ Filtro en WHERE: convierte el LEFT JOIN en un INNER JOIN encubierto.
--    Los usuarios sin pedidos completados tienen o.status = NULL,
--    y "NULL = 'Complete'" no es TRUE, así que desaparecen.
SELECT COUNT(DISTINCT u.id) AS usuarios
FROM `bigquery-public-data.thelook_ecommerce.users` AS u
LEFT JOIN `bigquery-public-data.thelook_ecommerce.orders` AS o
  ON u.id = o.user_id
WHERE o.status = 'Complete';

-- ✅ Filtro en ON: se aplica a la tabla de la derecha ANTES de unir,
--    y se conservan todos los usuarios.
SELECT COUNT(DISTINCT u.id) AS usuarios
FROM `bigquery-public-data.thelook_ecommerce.users` AS u
LEFT JOIN `bigquery-public-data.thelook_ecommerce.orders` AS o
  ON u.id = o.user_id
 AND o.status = 'Complete';

-- Compara ambos resultados: la diferencia son los usuarios que "perdías".


-- ---------------------------------------------------------------------
-- 4. EL FAN-OUT: CUANDO UN JOIN MULTIPLICA TUS NÚMEROS
-- ---------------------------------------------------------------------
-- Es probablemente el error más peligroso que he visto en reporting.
-- Si unes una tabla "1" con una tabla "muchos" y luego sumas una métrica
-- de la tabla "1", esa métrica se repite tantas veces como filas haya
-- en la tabla "muchos".

-- ❌ Mal: num_of_item está a nivel de pedido, pero tras el join hay
--    una fila por LÍNEA de pedido, así que se suma varias veces.
SELECT
  SUM(o.num_of_item)  AS items_inflados,
  SUM(oi.sale_price)  AS ingresos
FROM `bigquery-public-data.thelook_ecommerce.orders` AS o
JOIN `bigquery-public-data.thelook_ecommerce.order_items` AS oi
  ON o.order_id = oi.order_id;

-- ✅ Bien: agrega la tabla "muchos" al nivel de la tabla "1" ANTES de unir.
WITH ingresos_por_pedido AS (
  SELECT
    order_id,
    SUM(sale_price) AS ingresos
  FROM `bigquery-public-data.thelook_ecommerce.order_items`
  GROUP BY order_id
)
SELECT
  SUM(o.num_of_item) AS items_correctos,
  SUM(i.ingresos)    AS ingresos
FROM `bigquery-public-data.thelook_ecommerce.orders` AS o
JOIN ingresos_por_pedido AS i
  ON o.order_id = i.order_id;

-- 💡 Antes de cualquier JOIN, pregúntate: ¿la clave es ÚNICA en al menos
--    una de las dos tablas? Compruébalo así:
SELECT
  COUNT(*)          AS filas,
  COUNT(DISTINCT id) AS ids_unicos      -- si coinciden, id es único
FROM `bigquery-public-data.thelook_ecommerce.users`;


-- ---------------------------------------------------------------------
-- 5. JOIN DE VARIAS TABLAS
-- ---------------------------------------------------------------------
-- Ingresos por categoría de producto y país del cliente:
SELECT
  p.category,
  u.country,
  COUNT(DISTINCT oi.order_id)  AS pedidos,
  ROUND(SUM(oi.sale_price), 2) AS ingresos
FROM `bigquery-public-data.thelook_ecommerce.order_items` AS oi
JOIN `bigquery-public-data.thelook_ecommerce.products` AS p
  ON oi.product_id = p.id
JOIN `bigquery-public-data.thelook_ecommerce.users` AS u
  ON oi.user_id = u.id
WHERE oi.status NOT IN ('Cancelled', 'Returned')
GROUP BY p.category, u.country
ORDER BY ingresos DESC
LIMIT 20;

-- Empieza por la tabla con el nivel de detalle que quieres en el
-- resultado (aquí, líneas de pedido) y "cuelga" de ella las dimensiones.


-- ---------------------------------------------------------------------
-- 6. ANTI-JOIN: ENCONTRAR LO QUE NO EXISTE
-- ---------------------------------------------------------------------
-- Productos que nunca se han vendido.

-- Opción A: LEFT JOIN + IS NULL
SELECT p.id, p.name
FROM `bigquery-public-data.thelook_ecommerce.products` AS p
LEFT JOIN `bigquery-public-data.thelook_ecommerce.order_items` AS oi
  ON p.id = oi.product_id
WHERE oi.product_id IS NULL;

-- Opción B: NOT EXISTS (mi favorita, se lee casi como lenguaje natural)
SELECT p.id, p.name
FROM `bigquery-public-data.thelook_ecommerce.products` AS p
WHERE NOT EXISTS (
  SELECT 1
  FROM `bigquery-public-data.thelook_ecommerce.order_items` AS oi
  WHERE oi.product_id = p.id
);

-- ⚠️ Evita NOT IN con subconsultas: si la subconsulta devuelve un solo
--    NULL, NOT IN devuelve CERO filas sin dar ningún error.
--    WHERE id NOT IN (SELECT product_id FROM ...)  ← peligroso


-- ---------------------------------------------------------------------
-- 7. FULL OUTER JOIN: COMPARAR DOS FUENTES
-- ---------------------------------------------------------------------
-- Útil para conciliar datos: ¿qué está en A, qué en B, qué en ambas?
WITH pedidos_2023 AS (
  SELECT DISTINCT user_id
  FROM `bigquery-public-data.thelook_ecommerce.orders`
  WHERE EXTRACT(YEAR FROM created_at) = 2023
),
pedidos_2024 AS (
  SELECT DISTINCT user_id
  FROM `bigquery-public-data.thelook_ecommerce.orders`
  WHERE EXTRACT(YEAR FROM created_at) = 2024
)
SELECT
  CASE
    WHEN a.user_id IS NOT NULL AND b.user_id IS NOT NULL THEN 'Compró ambos años'
    WHEN a.user_id IS NOT NULL THEN 'Solo 2023 (perdido)'
    ELSE 'Solo 2024 (nuevo o recuperado)'
  END AS segmento,
  COUNT(*) AS usuarios
FROM pedidos_2023 AS a
FULL OUTER JOIN pedidos_2024 AS b
  ON a.user_id = b.user_id
GROUP BY segmento;


-- ---------------------------------------------------------------------
-- 8. CROSS JOIN: TODAS LAS COMBINACIONES
-- ---------------------------------------------------------------------
-- Combina cada fila de A con cada fila de B. Se usa poco, pero es clave
-- para generar "esqueletos" (p. ej. todas las categorías × todos los meses)
-- y no perder los meses con cero ventas. Lo vemos a fondo en el archivo 05.

-- ⚠️ Un CROSS JOIN accidental (olvidar el ON) entre dos tablas grandes
--    puede generar billones de filas. Si una consulta tarda muchísimo,
--    revisa que todos los JOIN tengan su condición.


-- ---------------------------------------------------------------------
-- 9. USING: ATAJO CUANDO LA COLUMNA SE LLAMA IGUAL
-- ---------------------------------------------------------------------
SELECT order_id, o.status AS estado_pedido, oi.sale_price
FROM `bigquery-public-data.thelook_ecommerce.orders` AS o
JOIN `bigquery-public-data.thelook_ecommerce.order_items` AS oi
  USING (order_id)
LIMIT 10;
