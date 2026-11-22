CREATE DATABASE churn_db CHARACTER SET utf8mb4;
USE churn_db;
-- Tabla 1: clientes (datos personales). Es la tabla principal.
-- -----------------------------------------------------
CREATE TABLE clientes (
    id_cliente          INT AUTO_INCREMENT PRIMARY KEY,
    customer_id         VARCHAR(10) NOT NULL UNIQUE,
    genero              VARCHAR(10) NOT NULL,
    adulto_mayor        TINYINT(1)  NOT NULL,
    tiene_pareja        TINYINT(1)  NOT NULL,
    tiene_dependientes  TINYINT(1)  NOT NULL
);

-- -----------------------------------------------------
-- Tabla 2: facturacion (contrato, método de pago y cargos)
-- Relación 1:1 con clientes (un registro de facturación por cliente)
-- -----------------------------------------------------
CREATE TABLE facturacion (
    id_facturacion        INT AUTO_INCREMENT PRIMARY KEY,
    id_cliente            INT           NOT NULL UNIQUE,
    tipo_contrato         VARCHAR(20)   NOT NULL,
    antiguedad_meses      SMALLINT      NOT NULL,
    facturacion_sin_papel TINYINT(1)    NOT NULL,
    metodo_pago           VARCHAR(30)   NOT NULL,
    cargo_mensual         DECIMAL(8,2)  NOT NULL,
    cargo_total           DECIMAL(10,2) NOT NULL,
    CONSTRAINT fk_facturacion_cliente
        FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente)
);

-- -----------------------------------------------------
-- Tabla 3: servicios (servicios contratados por cada cliente)
-- Relación 1:1 con clientes. 1 = tiene el servicio, 0 = no lo tiene
-- -----------------------------------------------------
CREATE TABLE servicios (
    id_servicio            INT AUTO_INCREMENT PRIMARY KEY,
    id_cliente             INT         NOT NULL UNIQUE,
    servicio_telefonico    TINYINT(1)  NOT NULL,
    lineas_multiples       TINYINT(1)  NOT NULL,
    tipo_internet          VARCHAR(20) NOT NULL,
    seguridad_online       TINYINT(1)  NOT NULL,
    respaldo_online        TINYINT(1)  NOT NULL,
    proteccion_dispositivo TINYINT(1)  NOT NULL,
    soporte_tecnico        TINYINT(1)  NOT NULL,
    streaming_tv           TINYINT(1)  NOT NULL,
    streaming_peliculas    TINYINT(1)  NOT NULL,
    CONSTRAINT fk_servicios_cliente
        FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente)
);

-- -----------------------------------------------------
-- Tabla 4: registro_churn (si el cliente abandonó o no)
-- Relación 1:1 con clientes. churn: 1 = se fue, 0 = sigue
-- -----------------------------------------------------
CREATE TABLE registro_churn (
    id_churn   INT AUTO_INCREMENT PRIMARY KEY,
    id_cliente INT        NOT NULL UNIQUE,
    churn      TINYINT(1) NOT NULL,
    CONSTRAINT fk_churn_cliente
        FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente)
);

USE churn_db;
SELECT COUNT(*) AS filas FROM telco_churn_limpio;   
-- 1) clientes (primero, porque las otras tablas dependen de ella)
INSERT INTO clientes (customer_id, genero, adulto_mayor, tiene_pareja, tiene_dependientes)
SELECT
    t.customer_id,
    t.genero,
    t.adulto_mayor,
    t.tiene_pareja,
    t.tiene_dependientes
FROM telco_churn_limpio AS t;

-- 2) facturacion
INSERT INTO facturacion (id_cliente, tipo_contrato, antiguedad_meses, facturacion_sin_papel,
                         metodo_pago, cargo_mensual, cargo_total)
SELECT
    c.id_cliente,
    t.tipo_contrato,
    t.antiguedad_meses,
    t.facturacion_sin_papel,
    t.metodo_pago,
    t.cargo_mensual,
    t.cargo_total
FROM telco_churn_limpio AS t
INNER JOIN clientes AS c ON c.customer_id = t.customer_id;

-- 3) servicios
INSERT INTO servicios (id_cliente, servicio_telefonico, lineas_multiples, tipo_internet,
                       seguridad_online, respaldo_online, proteccion_dispositivo,
                       soporte_tecnico, streaming_tv, streaming_peliculas)
SELECT
    c.id_cliente,
    t.servicio_telefonico,
    t.lineas_multiples,
    t.tipo_internet,
    t.seguridad_online,
    t.respaldo_online,
    t.proteccion_dispositivo,
    t.soporte_tecnico,
    t.streaming_tv,
    t.streaming_peliculas
FROM telco_churn_limpio AS t
INNER JOIN clientes AS c ON c.customer_id = t.customer_id;

-- 4) registro_churn
INSERT INTO registro_churn (id_cliente, churn)
SELECT
    c.id_cliente,
    t.churn
FROM telco_churn_limpio AS t
INNER JOIN clientes AS c ON c.customer_id = t.customer_id;

-- 5) Verificación: 
SELECT 'clientes'       AS tabla, COUNT(*) AS filas FROM clientes
UNION ALL
SELECT 'facturacion'    AS tabla, COUNT(*) AS filas FROM facturacion
UNION ALL
SELECT 'servicios'      AS tabla, COUNT(*) AS filas FROM servicios
UNION ALL
SELECT 'registro_churn' AS tabla, COUNT(*) AS filas FROM registro_churn;
