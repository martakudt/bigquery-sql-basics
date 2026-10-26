-- =====================================================================
-- EJERCICIOS · BLOQUE 2 · AGREGACIONES
-- =====================================================================
-- Temas nuevos: GROUP BY, HAVING, COUNTIF, SAFE_DIVIDE, percentiles y STRING_AGG.
-- Los ejercicios usan los bloques 1 a 2: cada bloque repasa lo anterior.
--
-- Dificultad: ⭐ básico | ⭐⭐ medio | ⭐⭐⭐ reto
--
-- Las soluciones están en ../soluciones/02_soluciones.sql.
-- Inténtalo primero sin mirarlas: equivocarse es parte del proceso.
-- =====================================================================


-- ---------------------------------------------------------------------
-- 2.1 · Países con más usuarios   ⭐
-- Repasa: bloque 2
-- ---------------------------------------------------------------------
-- Muestra los 10 países con más usuarios, junto con la edad media
-- (redondeada a 1 decimal) y la edad mínima y máxima.
--
-- Pista: COUNT(*), AVG, MIN, MAX y GROUP BY country.

-- Tu solución:




-- ---------------------------------------------------------------------
-- 2.2 · Tasa de cancelación mensual   ⭐⭐
-- Repasa: bloques 1 + 2
-- ---------------------------------------------------------------------
-- Para cada mes de 2024 (hora de Madrid) calcula: pedidos totales,
-- completados, cancelados y % de cancelación con 2 decimales.
--
-- Pista: DATE_TRUNC(DATE(created_at, 'Europe/Madrid'), MONTH), COUNTIF y SAFE_DIVIDE.

-- Tu solución:




-- ---------------------------------------------------------------------
-- 2.3 · Categorías con mejor margen   ⭐⭐
-- Repasa: bloques 1 + 2
-- ---------------------------------------------------------------------
-- Calcula el margen medio en % de cada categoría de producto.
-- Muestra solo las categorías con al menos 200 productos, ordenadas
-- de mayor a menor margen.
--
-- Pista: El margen % de cada producto es una expresión; promédiala con AVG. El filtro de 'al menos 200' va en HAVING.

-- Tu solución:




-- ---------------------------------------------------------------------
-- 2.4 · Perfil por tramo de edad   ⭐⭐
-- Repasa: bloques 1 + 2
-- ---------------------------------------------------------------------
-- Agrupa a los usuarios en los tramos '18-24', '25-34', '35-49' y '50+'.
-- Para cada tramo muestra: usuarios, mujeres, % de mujeres y cuántos
-- llegaron por 'Search'.
--
-- Pista: Puedes agrupar por el alias de un CASE. gender vale 'F' o 'M'.

-- Tu solución:




-- ---------------------------------------------------------------------
-- 2.5 · Media vs mediana   ⭐⭐
-- Repasa: bloque 2
-- ---------------------------------------------------------------------
-- Para cada estado de las líneas de pedido (order_items.status) calcula:
-- número de líneas, precio medio, precio mediano, percentil 90 y precio máximo.
-- ¿Se parecen la media y la mediana?
--
-- Pista: APPROX_QUANTILES(columna, 100)[OFFSET(50)] es la mediana.

-- Tu solución:




-- ---------------------------------------------------------------------
-- 2.6 · Tiempo de entrega por mes   ⭐⭐⭐
-- Repasa: bloques 1 + 2
-- ---------------------------------------------------------------------
-- Para cada mes de 2024 calcula: pedidos creados, pedidos entregados,
-- pedidos sin entregar, media de días hasta la entrega y máximo de días.
-- Pregunta extra: ¿sobre qué pedidos se calcula exactamente la media?
--
-- Pista: DATE_DIFF da NULL si delivered_at es NULL. Recuerda cómo trata AVG los NULL.

-- Tu solución:




-- ---------------------------------------------------------------------
-- 2.7 · Ciudades por país   ⭐⭐
-- Repasa: bloque 2
-- ---------------------------------------------------------------------
-- Muestra los 10 países con más ciudades distintas, el número de
-- ciudades y una lista con las 5 primeras en orden alfabético.
--
-- Pista: COUNT(DISTINCT ...) y STRING_AGG(DISTINCT ... ORDER BY ... LIMIT 5).

-- Tu solución:


