-- =====================================================================
-- EJERCICIOS · BLOQUE 4 · CTEs Y WINDOW FUNCTIONS
-- =====================================================================
-- Temas nuevos: WITH, ROW_NUMBER, RANK, QUALIFY, LAG/LEAD, acumulados y medias móviles.
-- Los ejercicios usan los bloques 1 a 4: cada bloque repasa lo anterior.
--
-- Dificultad: ⭐ básico | ⭐⭐ medio | ⭐⭐⭐ reto
--
-- Las soluciones están en ../soluciones/04_soluciones.sql.
-- Inténtalo primero sin mirarlas: equivocarse es parte del proceso.
-- =====================================================================


-- ---------------------------------------------------------------------
-- 4.1 · Nuevos clientes por mes   ⭐⭐
-- Repasa: bloques 1 + 2 + 4
-- ---------------------------------------------------------------------
-- Encuentra el primer pedido de cada cliente usando QUALIFY y, a partir
-- de ahí, cuenta cuántos clientes nuevos hubo cada mes de 2024.
--
-- Pista: Una CTE con ROW_NUMBER() ... QUALIFY = 1 y después un GROUP BY por mes.

-- Tu solución:




-- ---------------------------------------------------------------------
-- 4.2 · Top 3 productos de cada categoría   ⭐⭐
-- Repasa: bloques 2 + 3 + 4
-- ---------------------------------------------------------------------
-- Para cada categoría, muestra los 3 productos con más ingresos
-- (sin cancelados ni devueltos) y su puesto en el ranking.
--
-- Pista: Primero ingresos por producto en una CTE; luego DENSE_RANK con PARTITION BY category y QUALIFY.

-- Tu solución:




-- ---------------------------------------------------------------------
-- 4.3 · ¿Cada cuánto vuelven a comprar?   ⭐⭐⭐
-- Repasa: bloques 1 + 2 + 3 + 4
-- ---------------------------------------------------------------------
-- Calcula la media de días entre pedidos consecutivos de un mismo cliente,
-- por país. Muestra solo países con al menos 100 recompras, ordenados de
-- los que vuelven antes a los que tardan más.
--
-- Pista: LAG(fecha) OVER (PARTITION BY user_id ORDER BY created_at). El primer pedido de cada cliente tiene LAG = NULL.

-- Tu solución:




-- ---------------------------------------------------------------------
-- 4.4 · Crecimiento mensual y acumulado   ⭐⭐
-- Repasa: bloques 1 + 2 + 4
-- ---------------------------------------------------------------------
-- Para cada mes de 2024 muestra los ingresos (sin cancelados ni devueltos),
-- los ingresos del mes anterior, el crecimiento en % y el acumulado del año.
--
-- Pista: LAG para el mes anterior y SUM(...) OVER (ORDER BY mes) para el acumulado.

-- Tu solución:




-- ---------------------------------------------------------------------
-- 4.5 · Media móvil de pedidos   ⭐⭐
-- Repasa: bloques 1 + 2 + 4
-- ---------------------------------------------------------------------
-- Calcula los pedidos diarios de 2024 y su media móvil de 7 días.
-- Añade una columna que marque con 'Pico' los días en los que hubo más
-- de un 30% de pedidos por encima de la media móvil.
--
-- Pista: AVG(...) OVER (ORDER BY dia ROWS BETWEEN 6 PRECEDING AND CURRENT ROW). Calcula la media en una CTE y compara en la siguiente.

-- Tu solución:




-- ---------------------------------------------------------------------
-- 4.6 · Peso de cada categoría en su departamento   ⭐⭐
-- Repasa: bloques 2 + 3 + 4
-- ---------------------------------------------------------------------
-- Calcula los ingresos de cada categoría y qué % representan dentro de su
-- departamento (Men / Women). Ordena por departamento y peso.
--
-- Pista: SUM(SUM(x)) OVER (PARTITION BY department).

-- Tu solución:




-- ---------------------------------------------------------------------
-- 4.7 · Clientes que repiten rápido   ⭐⭐⭐
-- Repasa: bloques 1 + 2 + 4
-- ---------------------------------------------------------------------
-- Para los clientes cuyo primer pedido (no cancelado) fue en 2024, calcula
-- por mes del primer pedido: clientes nuevos, cuántos hicieron un segundo
-- pedido en 30 días o menos y qué % representan.
--
-- Pista: ROW_NUMBER para saber cuál es el primer pedido y LEAD para traer la fecha del siguiente.

-- Tu solución:


