-- =====================================================================
-- EJERCICIOS · BLOQUE 3 · JOINS
-- =====================================================================
-- Temas nuevos: tipos de JOIN, filtros en ON vs WHERE, anti-joins y fan-out.
-- Los ejercicios usan los bloques 1 a 3: cada bloque repasa lo anterior.
--
-- Dificultad: ⭐ básico | ⭐⭐ medio | ⭐⭐⭐ reto
--
-- Las soluciones están en ../soluciones/03_soluciones.sql.
-- Inténtalo primero sin mirarlas: equivocarse es parte del proceso.
-- =====================================================================


-- ---------------------------------------------------------------------
-- 3.1 · Ingresos por categoría   ⭐
-- Repasa: bloques 2 + 3
-- ---------------------------------------------------------------------
-- Calcula, para cada categoría de producto, el número de pedidos distintos
-- y los ingresos totales, sin contar las líneas canceladas ni devueltas.
-- Ordena de más a menos ingresos.
--
-- Pista: order_items tiene product_id; products tiene id y category.

-- Tu solución:




-- ---------------------------------------------------------------------
-- 3.2 · Usuarios que nunca han comprado   ⭐⭐
-- Repasa: bloques 2 + 3
-- ---------------------------------------------------------------------
-- ¿Cuántos usuarios no han hecho ningún pedido? Desglósalo por
-- canal de adquisición (traffic_source).
--
-- Pista: Es un anti-join. NOT EXISTS es la opción más segura.

-- Tu solución:




-- ---------------------------------------------------------------------
-- 3.3 · Todos los usuarios españoles, compren o no   ⭐⭐
-- Repasa: bloques 1 + 2 + 3
-- ---------------------------------------------------------------------
-- Lista TODOS los usuarios de España con el número de pedidos
-- completados que tiene cada uno (0 si no tiene ninguno).
-- Ordena de más a menos pedidos.
--
-- Pista: LEFT JOIN. ¿Dónde va el filtro de status = 'Complete': en ON o en WHERE? ¿Y el de country?

-- Tu solución:




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
--
-- Pista: num_of_item está a nivel de pedido; tras el JOIN hay una fila por línea. Mira la imagen del fan-out.

-- Tu solución:




-- ---------------------------------------------------------------------
-- 3.5 · Marcas top de 2024   ⭐⭐
-- Repasa: bloques 1 + 2 + 3
-- ---------------------------------------------------------------------
-- Muestra las 10 marcas con más ingresos en 2024 (sin cancelados ni
-- devueltos), con su número de pedidos distintos y el ticket medio
-- (ingresos / pedidos) redondeado a 2 decimales.
--
-- Pista: El ticket medio es una división: protégela con SAFE_DIVIDE.

-- Tu solución:




-- ---------------------------------------------------------------------
-- 3.6 · Catálogo que no se vende   ⭐⭐⭐
-- Repasa: bloques 2 + 3
-- ---------------------------------------------------------------------
-- Para cada categoría muestra: productos en catálogo, productos que nunca
-- se han vendido y qué % del catálogo representan.
--
-- Pista: LEFT JOIN contra una subconsulta con los product_id vendidos (DISTINCT) y luego COUNTIF(... IS NULL).

-- Tu solución:


