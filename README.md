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
    consultas_churn.sql          -> consultas de la actividad (SELECT, WHERE, AND/OR, LIKE, ORDER BY, LIMIT)
    
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

