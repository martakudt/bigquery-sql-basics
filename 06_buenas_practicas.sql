-- =====================================================================
-- 06 · BUENAS PRÁCTICAS: SQL LEGIBLE, FIABLE Y FÁCIL DE MANTENER
-- =====================================================================
-- Dataset: bigquery-public-data.thelook_ecommerce
--
-- Objetivo: escribir consultas que otra persona (o tú dentro de 6 meses)
-- pueda entender, y comprobar los datos antes de presentar un número.
-- =====================================================================


-- =====================================================================
-- PARTE A · ESTILO Y LEGIBILIDAD
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. UN FORMATO CONSISTENTE
-- ---------------------------------------------------------------------
-- ❌ Difícil de leer:
select o.order_id,u.country,sum(oi.sale_price) as ing from `bigquery-public-data.thelook_ecommerce.orders` o join `bigquery-public-data.thelook_ecommerce.users` u on o.user_id=u.id join `bigquery-public-data.thelook_ecommerce.order_items` oi on o.order_id=oi.order_id where o.status='Complete' group by 1,2;

-- ✅ La misma consulta, legible:
SELECT
  o.order_id,
  u.country,
  SUM(oi.sale_price) AS ingresos
FROM `bigquery-public-data.thelook_ecommerce.orders` AS o
JOIN `bigquery-public-data.thelook_ecommerce.users` AS u
  ON o.user_id = u.id
JOIN `bigquery-public-data.thelook_ecommerce.order_items` AS oi
  ON o.order_id = oi.order_id
WHERE o.status = 'Complete'
GROUP BY o.order_id, u.country;

-- Mis reglas:
--   · Palabras clave en MAYÚSCULAS, nombres en minusculas_con_guiones.
--   · Una columna por línea.
--   · Alias de tabla cortos pero claros (o, oi, u, p) y SIEMPRE prefijados.
--   · Nombres de columnas que se entiendan sin contexto: "ingresos",
--     no "ing" ni "x".
--   · Lo importante no es qué estilo elijas, sino que todo el equipo use
--     el mismo. Herramientas como sqlfluff lo automatizan.


-- ---------------------------------------------------------------------
-- 2. CTEs CON NOMBRES QUE CUENTAN UNA HISTORIA
-- ---------------------------------------------------------------------
-- Una consulta larga debería leerse como una receta: cada CTE, un paso.

WITH
pedidos_completados AS (
  SELECT order_id, user_id, created_at
  FROM `bigquery-public-data.thelook_ecommerce.orders`
  WHERE status = 'Complete'
),
primer_pedido_por_cliente AS (
  SELECT user_id, MIN(DATE(created_at)) AS fecha_primer_pedido
  FROM pedidos_completados
  GROUP BY user_id
),
nuevos_clientes_por_mes AS (
  SELECT
    DATE_TRUNC(fecha_primer_pedido, MONTH) AS mes,
    COUNT(*)                               AS nuevos_clientes
  FROM primer_pedido_por_cliente
  GROUP BY mes
)
SELECT *
FROM nuevos_clientes_por_mes
ORDER BY mes;

-- Con solo leer los nombres de las CTEs ya sabes qué hace la consulta.
-- Evita nombres como cte1, tmp, aux, t2...


-- ---------------------------------------------------------------------
-- 3. COMENTA EL "POR QUÉ", NO EL "QUÉ"
-- ---------------------------------------------------------------------
-- ❌ WHERE status != 'Cancelled'   -- quita los cancelados
--    (eso ya lo dice el código)
--
-- ✅ WHERE status != 'Cancelled'   -- Finanzas no cuenta los cancelados como venta
--    (esto explica una decisión de negocio que el código no puede contar)


-- ---------------------------------------------------------------------
-- 4. NADA DE "NÚMEROS MÁGICOS"
-- ---------------------------------------------------------------------
-- ❌ ¿Qué es 90? ¿Y 'Search'? ¿Por qué esos valores?
--    WHERE DATE(created_at) >= DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY)
--      AND traffic_source = 'Search'

-- ✅ Parámetros con nombre al principio del script:
DECLARE dias_analisis INT64  DEFAULT 90;        -- ventana estándar de reporting trimestral
DECLARE canal         STRING DEFAULT 'Search';

SELECT COUNT(*) AS nuevos_usuarios
FROM `bigquery-public-data.thelook_ecommerce.users`
WHERE DATE(created_at) >= DATE_SUB(CURRENT_DATE(), INTERVAL dias_analisis DAY)
  AND traffic_source = canal;


-- ---------------------------------------------------------------------
-- 5. NO REPITAS LÓGICA: CENTRALÍZALA
-- ---------------------------------------------------------------------
-- Si la definición de "venta válida" aparece copiada en 10 consultas,
-- el día que cambie la actualizarás en 9 y la décima dará otro número.
--
-- Opciones, de menos a más formal:
--   · Una CTE al principio de la consulta.
--   · Una función temporal (CREATE TEMP FUNCTION, ver archivo 05).
--   · Una VISTA compartida que todos usen:

CREATE OR REPLACE VIEW `mi_proyecto.mi_dataset.v_ventas_validas` AS
SELECT *
FROM `bigquery-public-data.thelook_ecommerce.order_items`
WHERE status NOT IN ('Cancelled', 'Returned');   -- definición acordada con Finanzas

--   · Y si ya trabajáis con dbt o Dataform, un modelo versionado.


-- =====================================================================
-- PARTE B · VALIDA LOS DATOS ANTES DE CONFIAR EN ELLOS
-- =====================================================================
-- Un número mal calculado con una consulta preciosa sigue siendo un
-- número mal calculado. Estas son las comprobaciones que hago antes de
-- presentar cualquier cifra.

-- ---------------------------------------------------------------------
-- 6. ¿LA CLAVE ES ÚNICA?
-- ---------------------------------------------------------------------
-- Si no lo es, tus JOINs duplicarán filas (el fan-out del archivo 03).
SELECT order_id, COUNT(*) AS veces
FROM `bigquery-public-data.thelook_ecommerce.orders`
GROUP BY order_id
HAVING COUNT(*) > 1;               -- debería devolver 0 filas


-- ---------------------------------------------------------------------
-- 7. ¿CUÁNTOS NULLs HAY EN LAS COLUMNAS IMPORTANTES?
-- ---------------------------------------------------------------------
SELECT
  COUNT(*)                     AS filas,
  COUNTIF(user_id IS NULL)     AS sin_usuario,
  COUNTIF(created_at IS NULL)  AS sin_fecha,
  COUNTIF(status IS NULL)      AS sin_estado
FROM `bigquery-public-data.thelook_ecommerce.orders`;


-- ---------------------------------------------------------------------
-- 8. ¿CUADRAN LOS TOTALES ENTRE TABLAS?
-- ---------------------------------------------------------------------
SELECT
  (SELECT COUNT(DISTINCT order_id) FROM `bigquery-public-data.thelook_ecommerce.orders`)      AS pedidos_en_orders,
  (SELECT COUNT(DISTINCT order_id) FROM `bigquery-public-data.thelook_ecommerce.order_items`) AS pedidos_en_items;


-- ---------------------------------------------------------------------
-- 9. ¿LOS VALORES TIENEN SENTIDO?
-- ---------------------------------------------------------------------
-- Rangos imposibles, fechas en el futuro, categorías inesperadas...
SELECT
  MIN(age)                                      AS edad_min,
  MAX(age)                                      AS edad_max,
  MAX(created_at)                               AS ultimo_alta,
  COUNTIF(created_at > CURRENT_TIMESTAMP())     AS altas_en_el_futuro,
  COUNT(DISTINCT country)                       AS num_paises
FROM `bigquery-public-data.thelook_ecommerce.users`;

-- Y para columnas de texto, mira siempre los valores distintos:
SELECT traffic_source, COUNT(*) AS usuarios
FROM `bigquery-public-data.thelook_ecommerce.users`
GROUP BY traffic_source
ORDER BY usuarios DESC;
-- Aquí es donde aparecen los 'Email', 'email' y 'E-mail' que
-- te parten un informe en tres.


-- ---------------------------------------------------------------------
-- 10. HAZ QUE LOS PROCESOS FALLEN SOLOS (ASSERT)
-- ---------------------------------------------------------------------
-- En scripts automáticos, mejor que falle a que publique datos malos:
ASSERT (
  SELECT COUNT(*) = COUNT(DISTINCT order_id)
  FROM `bigquery-public-data.thelook_ecommerce.orders`
) AS 'order_id no es único en orders: revisa duplicados';


-- =====================================================================
-- PARTE C · ERRORES TÍPICOS (RESUMEN DE TODO EL REPO)
-- =====================================================================
--   · Comparar con NULL usando = en lugar de IS NULL.             (01)
--   · Olvidar la zona horaria al pasar TIMESTAMP a DATE.          (01)
--   · Confundir COUNT(*) con COUNT(columna).                      (02)
--   · Dividir sin SAFE_DIVIDE cuando el denominador puede ser 0.  (02)
--   · Filtrar en WHERE la tabla derecha de un LEFT JOIN.          (03)
--   · Sumar métricas tras un JOIN 1-a-muchos (fan-out).           (03)
--   · Usar NOT IN con una subconsulta que puede tener NULLs.      (03)
--   · ROW_NUMBER con empates sin desempate determinista.          (04)
--   · Perder filas con arrays vacíos al hacer UNNEST con coma.    (05)
--   · Series temporales con huecos que "desaparecen".             (05)


-- ---------------------------------------------------------------------
-- 11. CHECKLIST ANTES DE COMPARTIR UN RESULTADO
-- ---------------------------------------------------------------------
--   [ ] ¿Las claves de mis JOINs son únicas donde deben serlo?
--   [ ] ¿He pensado qué pasa con los NULL en filtros y medias?
--   [ ] ¿Las fechas están en la zona horaria correcta?
--   [ ] ¿El total cuadra con alguna otra fuente o informe?
--   [ ] ¿Entendería esta consulta alguien que no soy yo?
