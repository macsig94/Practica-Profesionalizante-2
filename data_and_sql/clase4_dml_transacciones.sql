USE churn_db;


-- =====================================================
-- PARTE 1: ALTA DE NUEVOS REGISTROS (INSERT)
-- =====================================================

-- 1.1 Nuevo cliente
-- pareja = 'Yes' -> tiene_pareja = 1 | dependientes = 'No' -> tiene_dependientes = 0
INSERT INTO clientes (customer_id, genero, adulto_mayor, tiene_pareja, tiene_dependientes)
VALUES ('9999-NEWCL', 'Female', 0, 1, 0);

-- Compruebo que se insertó y miro qué id_cliente le asignó.
SELECT
    c.id_cliente         AS cliente_id,
    c.customer_id        AS codigo_cliente,
    c.genero             AS genero_cliente,
    c.adulto_mayor       AS es_adulto_mayor,
    c.tiene_pareja       AS tiene_pareja,
    c.tiene_dependientes AS tiene_dependientes
FROM clientes AS c
WHERE c.customer_id = '9999-NEWCL';

-- 1.2 Registro de servicios
-- No escribo id_servicio: lo genera AUTO_INCREMENT.
-- El id_cliente lo busco con una subconsulta por el código '9999-NEWCL'.
-- La consigna no indica qué servicios tiene, así que elegí estos valores
-- (teléfono + fibra óptica, sin extras); se pueden cambiar.
INSERT INTO servicios (id_cliente, servicio_telefonico, lineas_multiples, tipo_internet,
                       seguridad_online, respaldo_online, proteccion_dispositivo,
                       soporte_tecnico, streaming_tv, streaming_peliculas)
VALUES (
    (SELECT c.id_cliente FROM clientes AS c WHERE c.customer_id = '9999-NEWCL'),
    1, 0, 'Fiber optic',
    0, 0, 0,
    0, 0, 0
);

-- 1.3 Datos financieros
-- Datos: cargo_mensual 85.50, 'Month-to-month', cargo_total 85.50.
-- Como las columnas son NOT NULL, completé el resto con valores lógicos para un
-- cliente nuevo: antiguedad_meses = 1 (cargo_total = 1 mes de cargo),
-- facturacion_sin_papel = 0 y metodo_pago = 'Mailed check'.
INSERT INTO facturacion (id_cliente, tipo_contrato, antiguedad_meses, facturacion_sin_papel,
                         metodo_pago, cargo_mensual, cargo_total)
VALUES (
    (SELECT c.id_cliente FROM clientes AS c WHERE c.customer_id = '9999-NEWCL'),
    'Month-to-month', 1, 0,
    'Mailed check', 85.50, 85.50
);

-- Verifico que el cliente quedó bien relacionado en las 3 tablas
SELECT
    c.id_cliente    AS cliente_id,
    c.customer_id   AS codigo_cliente,
    s.id_servicio   AS servicio_id,
    s.tipo_internet AS tipo_internet,
    f.tipo_contrato AS tipo_contrato,
    f.cargo_mensual AS cargo_mensual,
    f.cargo_total   AS cargo_total
FROM clientes AS c
INNER JOIN servicios   AS s ON s.id_cliente = c.id_cliente
INNER JOIN facturacion AS f ON f.id_cliente = c.id_cliente
WHERE c.customer_id = '9999-NEWCL';


-- =====================================================
-- PARTE 2: REAJUSTE TARIFARIO CON ROLLBACK
-- =====================================================

-- 2.1 Inicio la transacción
START TRANSACTION;

-- 2.2 Aumento 10% el cargo mensual de los contratos mes a mes
UPDATE facturacion
SET cargo_mensual = cargo_mensual * 1.10
WHERE tipo_contrato = 'Month-to-month';

-- 2.3 Compruebo los nuevos montos (dentro de la transacción)
SELECT
    COUNT(*)                         AS clientes_mes_a_mes,
    ROUND(SUM(f.cargo_mensual), 2)   AS suma_cargo_mensual
FROM facturacion AS f
WHERE f.tipo_contrato = 'Month-to-month';

SELECT
    c.customer_id   AS codigo_cliente,
    f.cargo_mensual AS cargo_mensual_con_aumento
FROM facturacion AS f
INNER JOIN clientes AS c ON c.id_cliente = f.id_cliente
WHERE c.customer_id IN ('7590-VHVEG', '3668-QPYBK', '9237-HQITU')
ORDER BY c.id_cliente;

-- 2.4 El área comercial cancela el aumento: deshago todo
ROLLBACK;

-- Verifico que los valores volvieron al estado original
SELECT
    COUNT(*)                         AS clientes_mes_a_mes,
    ROUND(SUM(f.cargo_mensual), 2)   AS suma_cargo_mensual
FROM facturacion AS f
WHERE f.tipo_contrato = 'Month-to-month';

SELECT
    c.customer_id   AS codigo_cliente,
    f.cargo_mensual AS cargo_mensual_restaurado
FROM facturacion AS f
INNER JOIN clientes AS c ON c.id_cliente = f.id_cliente
WHERE c.customer_id IN ('7590-VHVEG', '3668-QPYBK', '9237-HQITU')
ORDER BY c.id_cliente;


-- =====================================================
-- PARTE 3: ELIMINACIÓN SEGURA (DELETE)
-- =====================================================
-- "Clientes inactivos" = clientes que abandonaron (churn = 1).
-- Elegí 3 clientes específicos: 3668-QPYBK, 9237-HQITU y 8779-QRDMV.

-- 3.1 Inicio la transacción
START TRANSACTION;

-- 3.2 PRIMERO valido con un SELECT qué filas voy a borrar
-- (tienen que ser 3 filas y las 3 con churn = 1)
SELECT
    rc.id_churn   AS churn_id,
    rc.id_cliente AS cliente_id,
    c.customer_id AS codigo_cliente,
    rc.churn      AS churn
FROM registro_churn AS rc
INNER JOIN clientes AS c ON c.id_cliente = rc.id_cliente
WHERE c.customer_id IN ('3668-QPYBK', '9237-HQITU', '8779-QRDMV');

-- 3.3 Recién ahora borro, con el mismo filtro de arriba
DELETE FROM registro_churn
WHERE id_cliente IN (
    SELECT c.id_cliente
    FROM clientes AS c
    WHERE c.customer_id IN ('3668-QPYBK', '9237-HQITU', '8779-QRDMV')
);

-- 3.4 Compruebo el resultado.
SELECT
    rc.id_churn   AS churn_id,
    c.customer_id AS codigo_cliente
FROM registro_churn AS rc
INNER JOIN clientes AS c ON c.id_cliente = rc.id_cliente
WHERE c.customer_id IN ('3668-QPYBK', '9237-HQITU', '8779-QRDMV');

-- 3.5 Cierro la transacción.
-- Uso ROLLBACK para no perder datos reales: así los registros vuelven a existir
-- y las demás consultas del proyecto siguen dando los mismos resultados.
-- Si de verdad quisiera purgar esos registros, usaría COMMIT; en lugar de ROLLBACK;
ROLLBACK;
-- COMMIT;

-- Verifico que los 3 registros siguen en la tabla (debe dar 3 filas)
SELECT
    rc.id_churn   AS churn_id,
    c.customer_id AS codigo_cliente,
    rc.churn      AS churn
FROM registro_churn AS rc
INNER JOIN clientes AS c ON c.id_cliente = rc.id_cliente
WHERE c.customer_id IN ('3668-QPYBK', '9237-HQITU', '8779-QRDMV');
