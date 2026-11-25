# Productividad y cuellos de botella — capacidad en una línea de producción

Análisis de la productividad diaria de equipos de una fábrica de confección: cuánto de la
capacidad se pierde, dónde se pierde y qué variable explica mejor la caída (tiempo muerto,
horas extra, cambios de estilo o trabajo en proceso).

**Stack:** Power BI Desktop (tablero) · Excel (escenario de capacidad)
**Perfil:** Analista de Datos de Operaciones / BI

> **Estado:** pendiente. Se abre al cerrar el Proyecto 2.
> El dataset está definido y verificado; **la descarga está pendiente** (ver
> [`01_raw/sources.md`](01_raw/sources.md)).

---

## El problema de negocio

Una fábrica de confección entrega pedidos contra un objetivo de productividad por equipo
y por día. Cuando el equipo no llega, la causa puede ser:

- **tiempo muerto** (la línea se paró y hubo operarios sin trabajo),
- **horas extra** (se trabajó de más para compensar, con costo adicional),
- **cambios de estilo** (reconfigurar la línea cuesta tiempo productivo),
- **trabajo en proceso acumulado** (cuello de botella aguas arriba).

Cada causa tiene una acción distinta y un costo distinto. El análisis tiene que separar
el efecto de cada una, no solo reportar "la productividad fue 73%".

## Preguntas de negocio

| # | Pregunta | Indicador | Estado |
|---|---|---|---|
| 01 | ¿Cuál es la brecha entre productividad objetivo y real, por departamento y equipo? | Objetivo − real (puntos porcentuales) | Pendiente |
| 02 | ¿Cuánto de la caída explica el tiempo muerto? | Horas de línea perdidas / horas disponibles | Pendiente |
| 03 | ¿Las horas extra compensan la caída o la agravan? | Productividad real vs. minutos extra | Pendiente |
| 04 | ¿Qué departamento es el cuello de botella real? | Menor productividad y mayor tiempo muerto relativo | Pendiente |
| 05 | ¿El trabajo en proceso acumulado anticipa una caída de productividad? | Correlación WIP vs. productividad | Pendiente |
| 06 | ¿Cuánta capacidad se recuperaría reduciendo el tiempo muerto a la mediana? | Escenario en Excel | Pendiente |

## Modelo de datos

```
hecho_produccion   (fecha, departamento, equipo, smv, wip, overtime_min,
                    idle_time_min, idle_men, incentivo, objetivo, real)
dim_equipo         (team → número de operarios)
dim_departamento   (department)
dim_tiempo         (fecha → día de semana, trimestre del mes, mes)
```

## Pipeline

```
01_raw/          Descarga UCI + DDL + carga
02_staging/      Tipado, nulos de WIP, normalización de fechas y categorías
03_modeling/     Hechos, dimensiones y vistas vw_*
04_presentation/ Tablero Power BI (2 páginas) + libro Excel de escenario de capacidad
05_validation/   Cuadre del tablero contra SQL + checklist
```

**Particularidad de este proyecto:** es el único donde Excel y Power BI se complementan
de verdad. Power BI cuenta la historia (dónde y cuándo se pierde la capacidad); Excel
responde la pregunta de decisión (cuánta capacidad se recupera si se ataca el tiempo
muerto). Eso es exactamente lo que se espera de un analista de operaciones.

## Limitaciones

- **1.197 registros de 3 meses.** Es un dataset pequeño: sirve para el método, no para
  generalizar. Se declara.
- **Productividad en escala 0–1**, no en unidades producidas. No se puede convertir a
  piezas sin el tiempo estándar (`smv`) de cada estilo, que no viene en el dataset.
- **Datos de una sola fábrica y un solo periodo.** No hay comparación entre plantas.
- **WIP tiene nulos.** No imputar sin documentarlo.

## Fuente

| Campo | Detalle |
|---|---|
| Dataset | Productivity Prediction of Garment Employees |
| Enlace | <https://archive.ics.uci.edu/dataset/597/productivity+prediction+of+garment+employees> |
| Institución | UCI Machine Learning Repository |
| Licencia | CC BY 4.0 |
| Registros | 1.197 filas, 15 columnas |
| Agradecimiento | Abdullah Al Imran, Md Shamsur Rahim, Tanvir Ahmed (2021) |

El detalle de columnas y la trampa de cada una está en
[`01_raw/sources.md`](01_raw/sources.md).
