import pandas as pd
# Link directo al dataset Telco Churn en GitHub
url ="https://raw.githubusercontent.com/IBM/telco-customer-churn-on-icp4d/master/data/Telco-Customer-Churn.csv"
# Carga directa al dataframe
df_raw = pd.read_csv(url)
# Guardar el DataFrame como archivo CSV en tu computadora o Google
df_raw.to_csv('Telco_Customer_Churn.csv', index=False)
# Verificación inicial de la estructura (Clase 1)
print(df_raw.shape)
print(df_raw.head())

# =====================================================
# Limpieza del dataset Telco Customer Churn
# Actividad 1 - Bases de datos
# Me guié por la guía rápida de 10 pasos y por el
# Manual de Limpieza de Datos con Python.
# =====================================================

# %% PASO 1 - Importar librerías
import pandas as pd
import numpy as np


# %% PASO 2 - Explorar los datos
# Link directo al dataset Telco Churn en GitHub
url = "https://raw.githubusercontent.com/IBM/telco-customer-churn-on-icp4d/master/data/Telco-Customer-Churn.csv"

# Carga directa al dataframe
df_raw = pd.read_csv(url)

# Guardo el DataFrame como CSV en Google Colab
df_raw.to_csv('Telco_Customer_Churn.csv', index=False)

# Trabajo sobre una copia para no perder el original por si me equivoco
df = df_raw.copy()

# Verificación inicial de la estructura
print(df.shape)
print(df.head())

# Tipos de datos y cantidad de valores no nulos
df.info()

# Cantidad de filas y columnas
print("Filas:", df.shape[0])
print("Columnas:", df.shape[1])

# Resumen estadístico de las columnas numéricas
print(df.describe())

# Valores nulos que detecta pandas
print(df.isnull().sum())
print("Total de nulos:", df.isnull().sum().sum())

# Noto que pandas dice que no hay nulos, pero TotalCharges aparece como
# 'object' (texto) cuando debería ser numérica. Sospecho que hay valores raros.
# Intento convertirla a número; lo que no se pueda queda como NaN
total_num = pd.to_numeric(df['TotalCharges'], errors='coerce')

# Me quedo con las filas donde no se pudo convertir
raras = df[total_num.isnull()]
print("Filas con TotalCharges raro:", len(raras))
print(raras[['customerID', 'tenure', 'MonthlyCharges', 'TotalCharges']])

# Qué tienen en común estas filas?
print("Valores de tenure en esas filas:", raras['tenure'].unique())
print("Contenido de TotalCharges:", raras['TotalCharges'].apply(repr).unique())
# Son 11 clientes con tenure = 0 (recién dados de alta) y su TotalCharges
# es un espacio en blanco " ". Por eso isnull() no los detectaba.

# Reviso las categorías de cada columna de texto para ver inconsistencias
for col in df.select_dtypes(include='object').columns:
    if col not in ['customerID', 'TotalCharges']:
        print(col, '->', df[col].unique().tolist())
# Veo que MultipleLines tiene "No phone service" y varias columnas tienen
# "No internet service". Es información repetida (ya está en PhoneService
# e InternetService), así que lo voy a unificar a "No".


# %% PASO 3 - Estandarizar textos
# Saco espacios extra al principio y al final de las columnas de texto
for col in df.select_dtypes(include='object').columns:
    df[col] = df[col].str.strip()


# %% PASO 4 - Eliminar duplicados
print("Filas completamente duplicadas:", df.duplicated().sum())
print("customerID repetidos:", df['customerID'].duplicated().sum())

# Elimino duplicados usando el ID del cliente (como en el manual)
df = df.drop_duplicates(subset=['customerID'], keep='first')
print("Filas después:", len(df))   # no había duplicados, quedan 7043


# %% PASO 5 - Manejar valores faltantes
# Convierto TotalCharges a número (los " " pasan a NaN)
df['TotalCharges'] = pd.to_numeric(df['TotalCharges'], errors='coerce')
print("NaN en TotalCharges:", df['TotalCharges'].isnull().sum())

# Al principio pensé en rellenar con la media como dice la guía, pero todos
# los NaN son clientes con tenure = 0 (todavía no pagaron nada). Con la media
# (~2283) les estaría inventando un gasto que no existe, así que relleno
# con 0. Tampoco los elimino porque son clientes reales.
nulos = df['TotalCharges'].isnull()
print("Todos tienen tenure = 0:", (df.loc[nulos, 'tenure'] == 0).all())

df['TotalCharges'] = df['TotalCharges'].fillna(0)
print("NaN restantes:", df['TotalCharges'].isnull().sum())


# %% PASO 6 - Estandarizar valores numéricos y categóricos
# Verifico los tipos numéricos
print(df[['tenure', 'MonthlyCharges', 'TotalCharges']].dtypes)

# Unifico "No phone service" y "No internet service" a "No"
df['MultipleLines'] = df['MultipleLines'].replace('No phone service', 'No')

cols_internet = ['OnlineSecurity', 'OnlineBackup', 'DeviceProtection',
                 'TechSupport', 'StreamingTV', 'StreamingMovies']
for col in cols_internet:
    df[col] = df[col].replace('No internet service', 'No')

print(df['MultipleLines'].unique())
print(df['OnlineSecurity'].unique())

# Paso los Yes/No a 1/0 (más fácil de usar después en SQL como TINYINT)
cols_yes_no = ['Partner', 'Dependents', 'PhoneService', 'MultipleLines',
               'PaperlessBilling', 'Churn'] + cols_internet

for col in cols_yes_no:
    df[col] = df[col].map({'Yes': 1, 'No': 0})

# Reviso que no haya quedado ningún NaN por el mapeo
print("NaN después de mapear:", df[cols_yes_no].isnull().sum().sum())


# %% PASO 7 - Filtrar datos incorrectos
# La guía elimina edades negativas. Acá no hay edad, pero antigüedad y cargos
# tampoco pueden ser negativos, así que hago el mismo chequeo.
print("tenure negativos:", (df['tenure'] < 0).sum())
print("MonthlyCharges negativos:", (df['MonthlyCharges'] < 0).sum())
print("TotalCharges negativos:", (df['TotalCharges'] < 0).sum())

# Me quedo solo con filas válidas
df = df[(df['tenure'] >= 0) & (df['MonthlyCharges'] >= 0) & (df['TotalCharges'] >= 0)]
print("Filas:", len(df))


# %% PASO 8 - Detectar outliers (rango intercuartílico, IQR)
# Primero solo cuento los outliers para decidir qué hacer
for col in ['tenure', 'MonthlyCharges', 'TotalCharges']:
    Q1 = df[col].quantile(0.25)
    Q3 = df[col].quantile(0.75)
    IQR = Q3 - Q1
    inferior = Q1 - 1.5 * IQR
    superior = Q3 + 1.5 * IQR
    n = ((df[col] < inferior) | (df[col] > superior)).sum()
    print(f"{col}: {n} outliers (límites {inferior:.1f} a {superior:.1f})")
# Salen 0 outliers en las tres columnas, así que no hay nada para eliminar.
# Igual, aunque hubieran salido, creo que no los habría borrado porque serían
# cargos reales de clientes y no errores.


# %% PASO 9 - Renombrar columnas
# Nombres más claros, en español y en minúsculas con guion bajo,
# para usarlos directo como columnas de MySQL
df = df.rename(columns={
    'customerID': 'customer_id',
    'gender': 'genero',
    'SeniorCitizen': 'adulto_mayor',
    'Partner': 'tiene_pareja',
    'Dependents': 'tiene_dependientes',
    'tenure': 'antiguedad_meses',
    'PhoneService': 'servicio_telefonico',
    'MultipleLines': 'lineas_multiples',
    'InternetService': 'tipo_internet',
    'OnlineSecurity': 'seguridad_online',
    'OnlineBackup': 'respaldo_online',
    'DeviceProtection': 'proteccion_dispositivo',
    'TechSupport': 'soporte_tecnico',
    'StreamingTV': 'streaming_tv',
    'StreamingMovies': 'streaming_peliculas',
    'Contract': 'tipo_contrato',
    'PaperlessBilling': 'facturacion_sin_papel',
    'PaymentMethod': 'metodo_pago',
    'MonthlyCharges': 'cargo_mensual',
    'TotalCharges': 'cargo_total',
    'Churn': 'churn'
})
print(df.head())

# Chequeo final antes de guardar
print("Shape final:", df.shape)
print("Nulos totales:", df.isnull().sum().sum())
df.info()


# %% PASO 10 - Guardar datos limpios
df.to_csv('telco_churn_limpio.csv', index=False)
print("Listo, archivo guardado")
