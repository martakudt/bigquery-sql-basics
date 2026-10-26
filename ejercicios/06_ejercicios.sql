-- =====================================================================
-- EJERCICIOS · BLOQUE 6 · BUENAS PRÁCTICAS
-- =====================================================================
-- Temas nuevos: validación de datos, refactorización y un informe completo.
-- Los ejercicios usan los bloques 1 a 6: cada bloque repasa lo anterior.
--
-- Dificultad: ⭐ básico | ⭐⭐ medio | ⭐⭐⭐ reto
--
-- Las soluciones están en ../soluciones/06_soluciones.sql.
-- Inténtalo primero sin mirarlas: equivocarse es parte del proceso.
-- =====================================================================


-- ---------------------------------------------------------------------
-- 6.1 · ¿Son únicas las claves?   ⭐
-- Repasa: bloques 2 + 6
-- ---------------------------------------------------------------------
-- En una sola consulta, comprueba si son únicos users.id, products.id,
-- orders.order_id y order_items.id. Para cada uno muestra filas y valores
-- distintos.
--
-- Pista: Puedes usar subconsultas escalares en el SELECT, como en el archivo 06.

-- Tu solución:




-- ---------------------------------------------------------------------
-- 6.2 · ¿Cuadran pedidos y líneas?   ⭐⭐
-- Repasa: bloques 2 + 3 + 4 + 6
-- ---------------------------------------------------------------------
-- orders.num_of_item debería coincidir con el número de líneas de ese
-- pedido en order_items. Calcula: total de pedidos, pedidos sin ninguna
-- línea y pedidos en los que no cuadra el número de líneas.
--
-- Pista: Cuenta las líneas por pedido en una CTE y haz LEFT JOIN desde orders.

-- Tu solución:




-- ---------------------------------------------------------------------
-- 6.3 · Detecta datos imposibles   ⭐⭐
-- Repasa: bloques 1 + 2 + 6
-- ---------------------------------------------------------------------
-- Revisa order_items y cuenta cuántas líneas tienen: precio menor o igual
-- a 0, fecha de envío anterior a la de creación, fecha de entrega anterior a
-- la de envío y fecha de creación en el futuro.
--
-- Pista: Un COUNTIF por cada comprobación, todo en la misma consulta.

-- Tu solución:




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
--
-- Pista: La subconsulta exterior solo sirve para filtrar grupos... ¿qué cláusula hace eso directamente?

-- Tu solución:




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
--
-- Pista: Divide el problema en CTEs: ventas válidas, primer mes de cada cliente, resumen mensual, categoría top e informe. Calcula el crecimiento ANTES de filtrar 2024.

-- Tu solución:


