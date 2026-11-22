
import os
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns


# ---------- GRÁFICO 1: Tasa de churn por tipo de contrato ----------
# Como churn es 1/0, la media es la proporción de bajas
churn_contrato = (df.groupby('tipo_contrato')['churn']
                    .mean().mul(100).reset_index())
churn_contrato.columns = ['tipo_contrato', 'tasa_churn']
print(churn_contrato.round(1))

colores = {'Month-to-month': '#e74c3c', 'One year': '#e67e22', 'Two year': '#27ae60'}

plt.figure(figsize=(8, 5))
ax = sns.barplot(data=churn_contrato, x='tipo_contrato', y='tasa_churn',
                 order=['Month-to-month', 'One year', 'Two year'],
                 hue='tipo_contrato', palette=colores, legend=False)
plt.title('Tasa de Abandono (Churn) según Tipo de Contrato', fontsize=14, fontweight='bold')
plt.xlabel('Tipo de Contrato', fontsize=12)
plt.ylabel('Tasa de Churn (%)', fontsize=12)
plt.ylim(0, 50)

# Etiqueta con el porcentaje (1 decimal) sobre cada barra
for p in ax.patches:
    ax.annotate(f"{p.get_height():.1f}%",
                (p.get_x() + p.get_width() / 2., p.get_height()),
                ha='center', va='center', xytext=(0, 8),
                textcoords='offset points', fontsize=11, fontweight='bold')

plt.tight_layout()
plt.savefig(f'{CARPETA_SALIDA}/churn_por_contrato.png', dpi=300)
plt.show()


# ---------- GRÁFICO 2: Distribución de antigüedad (KDE) ----------
plt.figure(figsize=(9, 5))
ax = sns.kdeplot(data=df, x='antiguedad_meses', hue='churn',
                 fill=True, common_norm=False, cut=0,
                 palette={0: '#2ecc71', 1: '#e74c3c'}, alpha=0.4)

# Línea de referencia: fin del periodo crítico (12 meses)
plt.axvline(x=12, color='black', linestyle='--', linewidth=1.5)
plt.text(13, ax.get_ylim()[1] * 0.92, 'Periodo crítico:\n0 a 12 meses',
         fontsize=10, fontweight='bold')

plt.title('Densidad de Antigüedad: Clientes Activos vs. Churn', fontsize=14, fontweight='bold')
plt.xlabel('Antigüedad en Meses (Tenure)', fontsize=12)
plt.ylabel('Densidad de Probabilidad', fontsize=12)

# Cambio los textos de la leyenda (0 y 1) leyendo la que armó seaborn
nombres = {'0': 'No Churn (Activos)', '1': 'Churn (Bajas)'}
leyenda = ax.get_legend()
leyenda.set_title('Estado')
for texto in leyenda.get_texts():
    texto.set_text(nombres[texto.get_text()])

plt.tight_layout()
plt.savefig(f'{CARPETA_SALIDA}/densidad_antiguedad.png', dpi=300)
plt.show()


# ---------- GRÁFICO 3: Matriz de impacto financiero (heatmap) ----------
# Filas: acción (Intervenir / No intervenir) | Columnas: realidad (Se iba / No se iba)
matriz_datos = np.array([
    [280, -50],    # Verdadero Positivo | Falso Positivo
    [-600, 0]      # Falso Negativo     | Verdadero Negativo
])

plt.figure(figsize=(8, 5))
ax = sns.heatmap(matriz_datos, annot=True, fmt='d', cmap='RdYlGn', cbar=False,
                 linewidths=1, annot_kws={'fontsize': 16, 'fontweight': 'bold'},
                 xticklabels=['Se iba a ir (Churn)', 'No se iba (Estable)'],
                 yticklabels=['Se le ofrece descuento', 'Sin intervención'])

# Nombre de cada cuadrante (texto blanco en los oscuros para que se lea)
nombres_cuadrantes = [['Verdadero Positivo', 'Falso Positivo'],
                      ['Falso Negativo', 'Verdadero Negativo']]
for fila in range(2):
    for col in range(2):
        color_texto = 'white' if abs(matriz_datos[fila][col]) >= 280 else '#222222'
        ax.text(col + 0.5, fila + 0.25, nombres_cuadrantes[fila][col],
                ha='center', va='center', fontsize=10, color=color_texto)

plt.yticks(rotation=0)
plt.title('Matriz de Impacto Financiero ($ Neto)', fontsize=14, fontweight='bold')
plt.xlabel('Comportamiento Real del Cliente', fontsize=12)
plt.ylabel('Acción Comercial Tomada', fontsize=12)
plt.tight_layout()
plt.savefig(f'{CARPETA_SALIDA}/matriz_decision_financiera.png', dpi=300)
plt.show()

