# Practica-Profesionalizante-2
# Análisis de Telco Customer Churn con Python y MySQL
Trabajo práctico de Bases de Datos. Tomé el dataset de Telco Customer Churn (7043 clientes), lo limpié con Python (pandas), lo dividí en 4 tablas relacionadas (3FN) y lo cargué en el Workbench para hacer consultas SQL.

## Estructura del repositorio
```
/Notebook
    limpieza.py   -> pipeline ETL en Python: exploración, limpieza, imputación
/data_and_sql
    DER_TELCOCHURN2.png  -> diagrama entidad-relación
    basededatos.sql      -> creación de la base churn_db y las 4 tablas
    consultas_churn.sql  -> consultas de la actividad (SELECT, WHERE, AND/OR, LIKE, ORDER BY, LIMIT)
    clase4_dml_transacciones.sql  -> INSERT, UPDATE con ROLLBACK y DELETE seguro dentro de transacciones    
    
```

## Qué contiene la carpeta de base de datos (`/data_and_sql`)
- **`basededatos.sql`**: crea la base `churn_db` con 4 tablas: `clientes` (tabla principal), `facturacion` (contrato, método de pago y cargos), `servicios` (servicios contratados) y `registro_churn` (si el cliente abandonó). Las tres últimas se relacionan 1 a 1 con `clientes` mediante `id_cliente`.
  
- **`consultas_churn.sql`**: todas las consultas de la actividad, con alias, indentación.


## Cómo reproducirlo
1. Ejecutar `basededatos.sql` en MySQL Workbench.
2. Correr el notebook en un entorno que pueda conectarse a MySQL.
3. Ejecutar `consultas_churn.sql`.

## Consulta clave: los 5 clientes que más facturaron
Esta consulta me parece la más útil para el análisis comercial, porque identifica a los clientes de mayor valor para la empresa (los que más dinero acumulado pagaron) y muestra qué tipo de contrato tienen:

```SQL
SELECT
    f.id_cliente    AS cliente_id,
    f.tipo_contrato AS tipo_contrato,
    f.cargo_total   AS cargo_total_acumulado
FROM facturacion AS f
ORDER BY f.cargo_total DESC,
         f.id_cliente ASC
LIMIT 5;
```
## Arquitectura de Datos

### El rol de las transacciones (COMMIT / ROLLBACK)
Una transacción agrupa varias sentencias SQL para que se traten como una sola unidad: o se aplican todas, o no se aplica ninguna. Se abre con `START TRANSACTION;` y se cierra con:
- **`COMMIT;`**, que confirma los cambios y los guarda de forma permanente.
- **`ROLLBACK;`**, que los deshace y deja la base como estaba al empezar.

En `clase4_dml_transacciones.sql` lo usé para simular un aumento del 10% al `cargo_mensual` de los contratos *Month-to-month*: dentro de la transacción comprobé los nuevos montos con un `SELECT` y, al "cancelar" el aumento, el `ROLLBACK` devolvió todos los valores a su estado original. Con el `DELETE` hice algo parecido: primero valido con un `SELECT` qué filas se van a borrar y recién después borro dentro de una transacción, para poder volver atrás si me equivoco. Esto evita perder datos por un error en el `WHERE`, algo que sin transacción sería irreversible.

### La importancia de la FOREIGN KEY (integridad referencial)
Mi base tiene a `clientes` como tabla principal y a `facturacion`, `servicios` y `registro_churn` como tablas hijas, relacionadas por `id_cliente` mediante claves foráneas. La `FOREIGN KEY` garantiza la **integridad referencial**:
- No se puede insertar un registro de facturación, servicios o churn de un cliente que no existe en `clientes`.
- No se puede borrar un cliente que todavía tiene registros en las tablas hijas (MySQL devuelve el error 1451), así que no quedan registros "huérfanos".

Gracias a esto, todos los datos del dataset siguen siendo coherentes entre sí. Por eso, al dar de alta el cliente nuevo, inserto primero en `clientes` y después en `servicios` y `facturacion`, buscando su `id_cliente` con una subconsulta.

