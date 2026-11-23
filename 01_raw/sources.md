# Fuentes de datos — Proyecto 3 (Productividad y cuellos de botella)

## Dataset

**Productivity Prediction of Garment Employees**

| Campo | Valor |
|---|---|
| Origen | UCI Machine Learning Repository — <https://archive.ics.uci.edu/dataset/597/productivity+prediction+of+garment+employees> |
| Descarga directa | <https://archive.ics.uci.edu/static/public/597/productivity+prediction+of+garment+employees.zip> |
| Licencia | CC BY 4.0 |
| DOI | 10.24432/C51S6D |
| Donado | 2020-08-02 |
| Registros | 1.197 filas · 15 columnas |
| Uso | Cualquiera, con atribución |

**Estado de la descarga:** **PENDIENTE.** El intento del 2026-11-10 falló por error de
conexión (`Error inesperado de recepción`). Al arrancar el Proyecto 3:

1. Descargar el `.zip` (92,9 KB) al navegador o con `Invoke-WebRequest`.
2. Descomprimir en `01_raw/entrada/` → debe quedar `garments_worker_productivity.csv`.
3. Calcular el SHA-256 y **agregarlo a este archivo** antes de cargar.

## Columnas y trampas

| Columna | Tipo | Qué es | Trampa |
|---|---|---|---|
| `date` | fecha | Fecha del registro | Viene en formato `MM-DD-YYYY` (mes primero). Peligro de confundir con `DD-MM-YYYY` |
| `quarter` | categoría | El mes dividido en 4 cuartos | **No es el trimestre del año.** Es una cuarta parte del mes. No confundir con Q1–Q4 |
| `department` | categoría | Departamento (`sewing`, `finishing`) | `finishing` tiene ~1/4 de los registros de `sewing`: el tablero debe mostrar el volumen, no solo el promedio |
| `day` | categoría | Día de la semana | — |
| `team` | entero | Número de equipo | Hay equipos que desaparecen del dataset a mitad de periodo: no asumir panel balanceado |
| `no_of_workers` | entero | Operarios del equipo | Cambia entre registros del mismo equipo; no es constante |
| `no_of_style_change` | entero | Cambios de estilo del día | — |
| `targeted_productivity` | decimal | Objetivo fijado por la autoridad | Varía por equipo y día; la brecha se calcula contra **este** valor, no contra un objetivo único |
| `smv` | decimal | Standard Minute Value: tiempo asignado a la tarea | Es el tiempo estándar; sin él no se puede convertir productividad a unidades |
| `wip` | entero | Work in progress: unidades sin terminar | **Tiene nulos** (~500 registros). Un nulo no es cero: si se imputa con 0 se inventa un cuello de botella |
| `over_time` | entero | Minutos de horas extra del equipo | — |
| `incentive` | entero | Incentivo financiero en BDT (taka bangladesí) | Moneda local; no convertir a dólares sin tipo de cambio de la fecha |
| `idle_time` | entero | Minutos de interrupción de la producción | Es la variable central del análisis de cuello de botella |
| `idle_men` | entero | Operarios parados por la interrupción | `idle_time` sin `idle_men` no dice cuánta capacidad se perdió: ambos importan |
| `actual_productivity` | decimal | Productividad real, escala 0–1 | Hay valores **por encima de 1** (se superó el objetivo): no recortar a 1 |

## Trampas adicionales

1. **`actual_productivity` no es un porcentaje de 0 a 100.** Es una razón 0–1. En el
   tablero se muestra como porcentaje, pero la columna se guarda como `numeric(5,4)`.
2. **Dos decimales en la presentación, cuatro en el dato.** La productividad se guarda con
   precisión completa y se muestra con 1 decimal (ej. `73,4 %`). Redondear a entero
   esconde diferencias de 0,4 puntos que sí importan en la brecha contra objetivo.
3. **La fecha no tiene hora.** No hay turnos: un registro es un equipo-día.
4. **`department` vacío o con espacios.** Verificar en staging (`TRIM`, `LOWER`).

## Atribución

> Productivity Prediction of Garment Employees [Dataset]. (2020). UCI Machine Learning
> Repository. <https://doi.org/10.24432/C51S6D>. CC BY 4.0.
>
> Al Imran, A., Rahim, M. S., & Ahmed, T. (2021). Mining the productivity data of the
> garment industry. *International Journal of Business Intelligence and Data Mining*.
