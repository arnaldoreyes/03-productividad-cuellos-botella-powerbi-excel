# Fase 5: Validación de Resultados (Excel vs. Power BI)

Cruce de control entre el archivo limpio base (`02_staging/staging_productividad`) y las métricas calculadas en Power BI Desktop (`04_presentation/tablero_productividad_cuellos_botella.pbix`) con todos los segmentadores en **Todas** (trimestre completo).

## 1. Cruce de Métricas Globales

| Métrica | Fórmula en Excel (`staging_productividad`) | Resultado Excel | Resultado Power BI | Estado |
|---|---|---|---|---|
| **Productividad Real** | `=PROMEDIO(actual_productivity)` | `73.5%` | `73.5%` | OK |
| **Productividad Meta** | `=PROMEDIO(targeted_productivity)` | `73.0%` | `73.0%` | OK |
| **Brecha de Productividad** | `Real - Meta` | `+0.5%` | `+0.5%` | OK |
| **Horas Extra** | `=SUMA(over_time)/60` *(conversión min a hrs)* | `91,121` | `91,121` | OK |
| **Tiempo Inactivo (min)** | `=SUMA(idle_time)` | `874` | `874` | OK |
| **Cambios de Estilo** | `=SUMA(no_of_style_change)` | `180` | `180` | OK |
| **WIP Promedio** | `=PROMEDIO(wip)` | `1,190` | `1,190` | OK |

## 2. Conclusión de Auditoría
* **Discrepancias encontradas:** `0`.
* **Nota técnica:** Se verificó la conversión de `over_time` de minutos (`5,467,250 min`) a horas (`91,121 hrs`) aplicada en la medida DAX `Horas Extra`.
* **Integridad del modelo:** Relaciones activas (`1:*`, dirección única) validadas en `dim_tiempo`, `dim_departamento` y `dim_equipo`.
