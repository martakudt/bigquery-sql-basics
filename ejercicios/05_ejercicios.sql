-- =====================================================================
-- EJERCICIOS · BLOQUE 5 · LO PROPIO DE BIGQUERY
-- =====================================================================
-- Temas nuevos: ARRAY, STRUCT, UNNEST, tablas comodín, GENERATE_DATE_ARRAY, PIVOT y UDFs.
-- Los ejercicios usan los bloques 1 a 5: cada bloque repasa lo anterior.
--
-- Dificultad: ⭐ básico | ⭐⭐ medio | ⭐⭐⭐ reto
--
-- Las soluciones están en ../soluciones/05_soluciones.sql.
-- Inténtalo primero sin mirarlas: equivocarse es parte del proceso.
-- =====================================================================


-- ---------------------------------------------------------------------
-- 5.1 · Categorías que compra cada cliente   ⭐⭐
-- Repasa: bloques 2 + 3 + 5
-- ---------------------------------------------------------------------
-- Para cada cliente, construye un ARRAY con las categorías distintas que
-- ha comprado (ordenadas alfabéticamente) y cuántas son. Muestra los 20
-- clientes con más categorías distintas (mínimo 3).
--
-- Pista: ARRAY_AGG(DISTINCT ... ORDER BY ...). ARRAY_AGG falla si encuentra NULLs: fíltralos antes.

-- Tu solución:




-- ---------------------------------------------------------------------
-- 5.2 · Páginas más vistas en móvil   ⭐⭐
-- Repasa: bloques 1 + 2 + 5
-- ---------------------------------------------------------------------
-- Usando la tabla ga_sessions_20170801, muestra las 10 páginas más vistas
-- desde dispositivos móviles.
--
-- Pista: device.deviceCategory = 'mobile'. Despliega hits con UNNEST y quédate con type = 'PAGE'.

-- Tu solución:




-- ---------------------------------------------------------------------
-- 5.3 · Conversión por dispositivo en julio de 2017   ⭐⭐
-- Repasa: bloques 1 + 2 + 5
-- ---------------------------------------------------------------------
-- Con la tabla comodín ga_sessions_*, calcula para julio de 2017 y por tipo
-- de dispositivo: sesiones, sesiones con compra, tasa de conversión en %
-- y páginas vistas medias por sesión.
--
-- Pista: Filtra con _TABLE_SUFFIX. Una sesión ha comprado si totals.transactions > 0 (ojo: puede ser NULL).

-- Tu solución:




-- ---------------------------------------------------------------------
-- 5.4 · ¿Los que ven el carrito compran más?   ⭐⭐⭐
-- Repasa: bloques 2 + 4 + 5
-- ---------------------------------------------------------------------
-- Para la primera semana de julio de 2017, compara la tasa de conversión
-- de las sesiones que visitaron alguna página con 'basket' en la URL
-- frente a las que no. Mantén una fila por sesión (sin desplegar los hits).
--
-- Pista: EXISTS(SELECT 1 FROM UNNEST(hits) AS h WHERE ...) dentro de una CTE.

-- Tu solución:




-- ---------------------------------------------------------------------
-- 5.5 · Serie diaria sin huecos   ⭐⭐⭐
-- Repasa: bloques 1 + 2 + 3 + 4 + 5
-- ---------------------------------------------------------------------
-- Calcula las unidades vendidas cada día de la categoría 'Clothing Sets'
-- en el primer trimestre de 2024, incluyendo los días sin ventas (con 0),
-- y añade la media móvil de 7 días.
--
-- Pista: GENERATE_DATE_ARRAY para el calendario, LEFT JOIN con las ventas, COALESCE y la media móvil del bloque 4.

-- Tu solución:




-- ---------------------------------------------------------------------
-- 5.6 · Ingresos por año y departamento con PIVOT   ⭐⭐
-- Repasa: bloques 2 + 3 + 5
-- ---------------------------------------------------------------------
-- Muestra una tabla con una fila por año y dos columnas, ingresos de
-- hombre y de mujer (sin cancelados ni devueltos), redondeadas sin decimales.
--
-- Pista: PIVOT(SUM(sale_price) FOR department IN ('Men', 'Women')) y renombra las columnas en el SELECT exterior.

-- Tu solución:




-- ---------------------------------------------------------------------
-- 5.7 · Reutiliza lógica con una función   ⭐⭐
-- Repasa: bloques 1 + 2 + 5
-- ---------------------------------------------------------------------
-- Crea una función temporal gama_precio(precio) con las gamas del
-- ejercicio 1.5 y úsala para mostrar, por gama: productos, precio medio
-- y margen medio en %.
--
-- Pista: CREATE TEMP FUNCTION nombre(param TIPO) AS (expresión); y después tu SELECT.

-- Tu solución:


