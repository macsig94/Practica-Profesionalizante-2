USE churn_db;

-- EJERCICIO 1: proyección (1.1 y 1.2 con alias)

SELECT
    c.id_cliente   AS cliente_id,
    c.genero       AS genero_cliente,
    c.adulto_mayor AS es_adulto_mayor
FROM clientes AS c;

-- EJERCICIO 2: cargo mensual mayor a 70.00

SELECT
    f.id_cliente    AS cliente_id,
    f.tipo_contrato AS tipo_contrato,
    f.cargo_mensual AS cargo_mensual
FROM facturacion AS f
WHERE f.cargo_mensual > 70.00;

-- EJERCICIO 3.1: Month-to-month Y cargo mensual mayor a 50.00

SELECT
    f.id_cliente    AS cliente_id,
    f.tipo_contrato AS tipo_contrato,
    f.metodo_pago   AS metodo_pago,
    f.cargo_mensual AS cargo_mensual
FROM facturacion AS f
WHERE f.tipo_contrato = 'Month-to-month'
  AND f.cargo_mensual > 50.00;

-- EJERCICIO 3.2: lo anterior O pago con 'Electronic check' (con paréntesis)

SELECT
    f.id_cliente    AS cliente_id,
    f.tipo_contrato AS tipo_contrato,
    f.metodo_pago   AS metodo_pago,
    f.cargo_mensual AS cargo_mensual
FROM facturacion AS f
WHERE (f.tipo_contrato = 'Month-to-month' AND f.cargo_mensual > 50.00)
   OR f.metodo_pago = 'Electronic check';

-- EJERCICIO 4.1: métodos de pago que contienen 'Electronic'

SELECT DISTINCT
    f.metodo_pago AS metodo_pago
FROM facturacion AS f
WHERE f.metodo_pago LIKE '%Electronic%';

-- EJERCICIO 4.2: lo mismo, ordenado por cargo mensual de mayor a menor

SELECT
    f.id_cliente    AS cliente_id,
    f.metodo_pago   AS metodo_pago,
    f.cargo_mensual AS cargo_mensual
FROM facturacion AS f
WHERE f.metodo_pago LIKE '%Electronic%'
ORDER BY f.cargo_mensual DESC;

-- EJERCICIO 5: top 5 clientes por cargo total acumulado

SELECT
    f.id_cliente    AS cliente_id,
    f.tipo_contrato AS tipo_contrato,
    f.cargo_total   AS cargo_total_acumulado
FROM facturacion AS f
ORDER BY f.cargo_total DESC,
         f.id_cliente ASC
LIMIT 5;
