# Practica-Profesionalizante-2
# Análisis de Telco Customer Churn con Python y MySQL
Tomé el dataset de Telco Customer Churn (7043 clientes), lo limpié con Python (pandas), lo dividí en 4 tablas relacionadas (3FN) y lo cargué en el Workbench para hacer consultas SQL.

## Estructura del repositorio
```
/Notebook
    limpieza.py   -> pipeline ETL en Python: exploración, limpieza, imputación
    Script_de_visualización.py   -> script que genera los 3 gráficos del análisis
    notebook  -> imágenes generadas (churn_por_contrato.png, densidad_antiguedad.png, matriz_decision_financiera.png)
/data_and_sql
    DER_TELCOCHURN2.png  -> diagrama entidad-relación
    basededatos.sql      -> creación de la base churn_db y las 4 tablas
    consultas_churn.sql  -> consultas de la actividad (SELECT, WHERE, AND/OR, LIKE, ORDER BY, LIMIT)
    clase4_dml_transacciones.sql  -> INSERT, UPDATE con ROLLBACK y DELETE seguro dentro de transacciones    
    
```

## Qué contiene la carpeta de base de datos (`/data_and_sql`)
- **`basededatos.sql`**: crea la base `churn_db` con 4 tablas: `clientes` (tabla principal), `facturacion` (contrato, método de pago y cargos), `servicios` (servicios contratados) y `registro_churn` (si el cliente abandonó). Las tres últimas se relacionan 1 a 1 con `clientes` mediante `id_cliente`.
  
- **`consultas_churn.sql`**: todas las consultas de la actividad, con alias, indentación.


## Consulta clave: los 5 clientes que más facturaron
Esta consulta me parece la más útil para el análisis comercial, porque identifica a los clientes de mayor valor para la empresa (los que más dinero acumulado pagaron) y muestra qué tipo de contrato tienen:

```sql
SELECT
    f.id_cliente    AS cliente_id,
    f.tipo_contrato AS tipo_contrato,
    f.cargo_total   AS cargo_total_acumulado
FROM facturacion AS f
ORDER BY f.cargo_total DESC,
         f.id_cliente ASC
LIMIT 5;
```

## Hallazgos Visuales & Análisis Financiero
Los 3 gráficos los genera `notebook/Script_de_visualización.py` a partir de `telco_churn_limpio.csv` (7043 clientes, 1869 bajas, o sea una tasa de churn global del 26.5%).

### 1. Tasa de churn por tipo de contrato
![Tasa de churn por tipo de contrato](notebook/churn_por_contrato.png)

Los clientes con contrato **Month-to-month** abandonan un **42.7%**, contra un 11.3% de los de un año y un 2.8% de los de dos años: la tasa es unas 15 veces mayor que la del contrato de dos años. Además, estos clientes son 3875 de los 7043 y concentran **1655 de las 1869 bajas (88.6%)**. Entiendo que el contrato mes a mes casi no tiene costo de salida, así que el cliente se puede ir apenas algo no le convence. Para la empresa, la prioridad comercial sería llevar a estos clientes a planes de 1 o 2 años con algún beneficio (descuento o servicio extra), porque ahí está la mayor fuga. Este gráfico muestra una relación entre variables y no prueba que el tipo de contrato sea la causa.

### 2. Distribución de antigüedad (ventana crítica de 12 meses)
![Densidad de antigüedad según churn](notebook/densidad_antiguedad.png)

La curva roja (bajas) tiene su pico en los **primeros meses** y baja a medida que aumenta la antigüedad, mientras que la verde (activos) se mantiene más pareja y sube en los clientes de más de 5 años. De las 1869 bajas, **1037 (55.5%) ocurrieron en los primeros 12 meses**, y la mediana de antigüedad de quienes se fueron es de 10 meses contra 38 en los clientes activos. Los clientes con hasta 12 meses de antigüedad abandonan un 47.4%, contra un 17.1% de los que ya pasaron el primer año. Esto marca el primer año como la ventana crítica: conviene reforzar el acompañamiento y las ofertas de retención justo en esa etapa, antes de que el cliente decida irse.

### 3. Matriz de impacto financiero
![Matriz de impacto financiero](notebook/matriz_decision_financiera.png)

La matriz asigna un valor en dólares a cada decisión comercial: intervenir con un descuento a un cliente que se iba a ir deja **+$280** (verdadero positivo), intervenir a uno que no se iba cuesta **-$50** (falso positivo), no intervenir y perder al cliente cuesta **-$600** (falso negativo) y no hacer nada con un cliente estable no tiene costo (verdadero negativo, $0). El punto clave es el **falso negativo**: un cliente que se va sin que lo detectemos cuesta 12 veces más que un descuento innecesario, y la diferencia entre actuar a tiempo y no hacerlo es de $880 por cliente ($280 contra -$600). Con estos valores, calculé que conviene ofrecer el descuento siempre que la probabilidad de que el cliente se vaya supere aproximadamente el **5.4%**, es decir que es más barato equivocarse por exceso de intervención que por omisión. Como ejemplo extremo, si las 1869 bajas del dataset no se detectaran, la pérdida sería de unos **$1.121.400** (1869 × $600); si todas se retuvieran con éxito, el beneficio sería de unos $523.320 (1869 × $280). Estos números dependen de los valores supuestos en la matriz y son solo ilustrativos.

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


