-- =====================================================================
-- EJERCICIOS · BLOQUE 1 · FUNDAMENTOS
-- =====================================================================
-- Temas nuevos: SELECT, WHERE, NULLs, tipos de datos, fechas y CASE.
-- Los ejercicios usan solo el bloque 1: cada bloque repasa lo anterior.
--
-- Dificultad: ⭐ básico | ⭐⭐ medio | ⭐⭐⭐ reto
--
-- Las soluciones están en ../soluciones/01_soluciones.sql.
-- Inténtalo primero sin mirarlas.
-- =====================================================================


-- ---------------------------------------------------------------------
-- 1.1 · Usuarios de España   ⭐
-- Repasa: bloque 1
-- ---------------------------------------------------------------------
-- Muestra nombre, apellido, edad y ciudad de los usuarios de España.
-- Ordénalos de mayor a menor edad y, a igualdad de edad, por apellido.
-- Devuelve solo 20 filas.
--
-- Pista: ORDER BY admite varias columnas, cada una con su ASC/DESC.

-- Tu solución:




-- ---------------------------------------------------------------------
-- 1.2 · Margen de los productos caros   ⭐
-- Repasa: bloque 1
-- ---------------------------------------------------------------------
-- De los productos de las categorías 'Jeans' y 'Pants' con precio de venta
-- mayor que 100, muestra: nombre, marca, categoría, precio de venta,
-- margen (precio - coste) y margen en % redondeado a 1 decimal.
-- Ordena por margen % de mayor a menor.
--
-- Pista: Usa IN para las categorías y ROUND(..., 1) para el porcentaje.

-- Tu solución:




-- ---------------------------------------------------------------------
-- 1.3 · Pedidos enviados que no han llegado   ⭐⭐
-- Repasa: bloque 1
-- ---------------------------------------------------------------------
-- Lista los pedidos que ya se han enviado (shipped_at tiene valor)
-- pero que todavía no se han entregado ni devuelto.
-- Muestra order_id, status, la fecha de envío y cuántos días han pasado
-- desde el envío hasta hoy. Ordena por días de mayor a menor (20 filas).
--
-- Pista: Para comprobar si una columna tiene valor o no: IS NULL / IS NOT NULL. Nunca = NULL.

-- Tu solución:




-- ---------------------------------------------------------------------
-- 1.4 · Pedidos de marzo de 2024 en hora española   ⭐⭐
-- Repasa: bloque 1
-- ---------------------------------------------------------------------
-- Muestra los pedidos creados en marzo de 2024 según la hora de Madrid.
-- Columnas: order_id, fecha en Madrid, nombre del día de la semana,
-- lunes de esa semana y horas que pasaron entre la creación y el envío.
--
-- Pista: DATE(timestamp, 'Europe/Madrid'), FORMAT_DATE('%A', ...), DATE_TRUNC(..., WEEK(MONDAY)), TIMESTAMP_DIFF.

-- Tu solución:




-- ---------------------------------------------------------------------
-- 1.5 · Gamas de precio   ⭐
-- Repasa: bloque 1
-- ---------------------------------------------------------------------
-- Clasifica los productos en gamas según su precio de venta:
--   menos de 25 → 'Económico' | menos de 75 → 'Medio'
--   menos de 150 → 'Alto'     | el resto → 'Premium'
-- Añade otra columna que diga 'Mujer' si el departamento es 'Women'
-- y 'Hombre' en caso contrario. Muestra los 50 productos más caros.
--
-- Pista: CASE WHEN se queda con la primera condición verdadera; IF(cond, a, b) para dos opciones.

-- Tu solución:




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
--
-- Pista: Repasa la sección de NULLs del archivo 01: IS NULL e IS DISTINCT FROM.

-- Tu solución:




-- ---------------------------------------------------------------------
-- 1.7 · Fechas que llegan como texto   ⭐⭐
-- Repasa: bloque 1
-- ---------------------------------------------------------------------
-- Sin usar ninguna tabla, convierte el texto '26/10/2026' en una fecha y calcula:
-- el día de la semana, cuántos días faltan para el 31/12/2026 y el último
-- día de ese mes. Además, convierte a número los textos '1234' y '1.234'
-- sin que la consulta falle.
--
-- Pista: PARSE_DATE('%d/%m/%Y', ...), LAST_DAY(fecha) y SAFE_CAST.

-- Tu solución:


