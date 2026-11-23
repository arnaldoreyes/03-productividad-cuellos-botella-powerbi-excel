# Perfilado de datos crudos y reglas de limpieza — Fase 02 (`02_staging`)

Documento de trazabilidad de la capa de *staging* del Proyecto 3 (`03-productividad-cuellos-botella-powerbi-excel`).
Resume los hallazgos verificados con [`02_staging/perfilado_raw.ps1`](perfilado_raw.ps1) sobre el archivo crudo y las reglas exactas aplicadas en Power Query dentro de [`02_staging/staging_productividad.xlsx`](staging_productividad.xlsx) (consulta `stg_productividad`).

---

## 1. Fuente auditada

| Campo | Valor verificado |
|---|---|
| Archivo crudo | `01_raw/entrada/garments_worker_productivity.csv` (excluido de Git vía `.gitignore`) |
| Tamaño | `94.933` bytes |
| SHA-256 | `763FFCDD39B7F7F360243C2AF8F89ED733E8B5F9E511EFEB0C886B83E1B76866` |
| Script de perfilado | [`02_staging/perfilado_raw.ps1`](perfilado_raw.ps1) |
| Salida de staging | [`02_staging/staging_productividad.xlsx`](staging_productividad.xlsx) — consulta `stg_productividad` (`1.197` filas cargadas, `0` errores) |

---

## 2. Hallazgos reales del perfilado

### 2.1 Dimensiones, duplicados y granularidad
- **Dimensiones:** `1.197` filas de datos × `15` columnas (`1.198` líneas totales incluyendo encabezado).
- **Duplicados exactos:** `0` filas duplicadas exactas.
- **Granularidad verificada:** la combinación **`date` + `department` (limpio) + `team`** genera **`1.197` combinaciones únicas y `0` colisiones** (tanto antes como después de corregir `sweing → sewing`).
- **Implicación de negocio:** un mismo equipo puede registrar hasta dos filas en el mismo día (una por `sewing` y otra por `finishing`). La unidad real de análisis es **fecha + departamento + equipo**.

### 2.2 Nulos y valores faltantes
- **Única columna con nulos:** `wip` con **`506` nulos (`42,27%`)** y `691` valores informados (`57,73%`). Las otras `14` columnas tienen **`0` nulos**.
- **Cruce estructural `wip` × `department`:**

| `department` (crudo) | `department` (limpio) | Total filas | `wip` nulo | `wip` con dato | % nulo |
|---|---|---:|---:|---:|---:|
| `[finishing]` | `finishing` | 249 | 249 | 0 | 100,00% |
| `[finishing ]` | `finishing` | 257 | 257 | 0 | 100,00% |
| `[sweing]` | `sewing` | 691 | 0 | 691 | 0,00% |
| **Total** | — | **1.197** | **506** | **691** | **42,27%** |

- **Lectura de negocio:** el nulo de `wip` no es un error de captura aleatorio; en el área de acabado (`finishing`) no se registra trabajo en proceso, mientras que en costura (`sewing`) está completo al 100%. Rellenar esos nulos con `0` distorsionaría los promedios y crearía falsos ceros de inventario en proceso.

### 2.3 Columnas categóricas y calendario
- **`department`:** trae **3 cadenas crudas** para solo **2 departamentos reales**:
  - `[sweing]`: `691` filas (`57,73%`) — error ortográfico en el 100% de costura.
  - `[finishing ]`: `257` filas (`21,47%`, longitud 10) — espacio en blanco al final.
  - `[finishing]`: `249` filas (`20,80%`, longitud 9).
  - Tras normalizar: **`sewing = 691` (`57,73%`)** y **`finishing = 506` (`42,27%`)**.
- **`quarter`:** no representa trimestres del año sino fracciones semanales del mes, y contiene **5 valores** (no 4): `Quarter1` (`360`), `Quarter2` (`335`), `Quarter4` (`248`), `Quarter3` (`210`) y `Quarter5` (`44`, `3,68%`, correspondiente al cierre de mes).
- **`day`:** `6` días laborables (`Wednesday`: 208, `Sunday`: 203, `Tuesday`: 201, `Monday`: 199, `Thursday`: 199, `Saturday`: 187). **No hay registros de `Friday`**, consistente con el calendario laboral de Bangladesh (viernes como día de descanso).
- **`team`:** `12` equipos (`1` al `12`), todos con actividad registrada desde `2015-01-01` hasta `2015-03-11` (entre `88` registros en el equipo `11` y `109` en los equipos `2` y `8`).
- **`date`:** `1.197 / 1.197` fechas válidas en formato estadounidense `M/d/yyyy`, rango exacto **`2015-01-01` a `2015-03-11`**, `59` fechas únicas y **`0` discrepancias** entre `day` y el día de la semana real de `date`.

### 2.4 Columnas numéricas y casos especiales
En las `10` columnas numéricas se verificaron **`0` valores no numéricos** y **`0` valores negativos**:

| Columna | No nulos | Mínimo | Máximo | Promedio | Ceros | > 0 | Con decimal |
|---|---:|---:|---:|---:|---:|---:|---:|
| `targeted_productivity` | 1.197 | 0,0700 | 0,8000 | 0,7296 | 0 | 1.197 | 1.197 |
| `smv` | 1.197 | 2,9000 | 54,5600 | 15,0622 | 0 | 1.197 | 1.197 |
| `wip` | 691 | 7 | 23.122 | 1.190,4660 | 0 | 691 | 0 |
| `over_time` | 1.197 | 0 | 25.920 | 4.567,4603 | 31 | 1.166 | 0 |
| `incentive` | 1.197 | 0 | 3.600 | 38,2105 | 604 | 593 | 0 |
| `idle_time` | 1.197 | 0 | 300 | 0,7302 | 1.179 | 18 | 6 |
| `idle_men` | 1.197 | 0 | 45 | 0,3693 | 1.179 | 18 | 0 |
| `no_of_style_change` | 1.197 | 0 | 2 | 0,1504 | 1.050 | 147 | 0 |
| `no_of_workers` | 1.197 | 2 | 89 | 34,6099 | 0 | 1.197 | 140 |
| `actual_productivity` | 1.197 | 0,2337 | 1,1204 | 0,7351 | 0 | 1.197 | 1.197 |

- **Productividad real superior a 1:** existen **`37` registros (`3,09%`)** con `actual_productivity > 1` (valor máximo verificado: **`1,120438`**). Representan jornadas donde el equipo superó el 100% de la producción estándar.
- **Eventos de tiempo muerto:** exactamente **`18` registros (`1,50%`)** presentan tiempo muerto, con consistencia del 100% entre variables (`18` con `idle_time > 0` y `idle_men > 0` simultáneamente; `0` casos huérfanos donde solo una sea mayor a cero).
- **Decimales reales en columnas aparentemente enteras:** `no_of_workers` tiene **`140` registros con decimales** (ej. `30.5`, correspondientes a dotación parcial / medios turnos) e `idle_time` tiene **`6` registros con decimales**.

---

## 3. Reglas de limpieza aplicadas en Power Query (`stg_productividad`)

Todas las transformaciones se ejecutaron en Power Query dentro de [`02_staging/staging_productividad.xlsx`](staging_productividad.xlsx) (consulta `stg_productividad`), siguiendo el principio *Power Query first*:

| # | Regla aplicada | Implementación en Power Query | Por qué (criterio de negocio y trazabilidad) |
|---|---|---|---|
| 1 | **Estandarización sin traducción en staging** | Se conservaron los nombres de las 15 columnas y los valores categóricos en inglés. | Mantiene trazabilidad 1 a 1 con el CSV crudo de UCI; la traducción de etiquetas para negocio se concentra en la capa de modelado/presentación (`03_modeling` / `04_presentation`). |
| 2 | **Normalización de `department`** | `Text.Lower` + `Text.Trim` + reemplazo exacto `sweing` → `sewing`. | Unifica las 3 variantes crudas (`[sweing]`, `[finishing ]`, `[finishing]`) en los 2 departamentos reales (`sewing` y `finishing`), evitando que un espacio invisible o un typo parta los KPIs en categorías duplicadas. |
| 3 | **Tipado de `date` con configuración regional** | Tipo `Fecha` usando configuración regional **`en-US`**. | El CSV viene en formato estadounidense `M/d/yyyy`. Tipar con `en-US` evita que Excel/Power BI en español invierta día y mes (ej. leer `3/11/2015` como 3 de noviembre en lugar de 11 de marzo). Rango verificado: `2015-01-01` a `2015-03-11`. |
| 4 | **Tipado de columnas decimales con configuración regional** | Tipo `Número decimal` con configuración regional **`en-US`** en: `targeted_productivity`, `smv`, `idle_time`, `no_of_workers`, `actual_productivity`. | Respeta el separador decimal de punto (`.`) del CSV en un entorno Office en español y conserva la precisión real de los `6` decimales de `idle_time` y los `140` decimales de `no_of_workers`. |
| 5 | **Tipado de columnas enteras y preservación de nulos de `wip`** | Tipo `Número entero` en: `team`, `wip`, `over_time`, `incentive`, `idle_men`, `no_of_style_change`. Sin reemplazo de nulos en `wip`. | Conserva intactos los `506` `null` estructurales de `wip` en `finishing` sin imputar ceros ficticios que contaminen el análisis de cuellos de botella en `sewing`. |
| 6 | **Preservación de integridad y extremos válidos** | Sin eliminación de filas ni recorte (*capping*) de `actual_productivity`. | Se conservan las **`1.197` filas** completas y los **`37` registros** con `actual_productivity > 1` (hasta `1,120438`), porque reflejan sobrecumplimiento real de planta. |

---

## 4. Resultado de verificación en staging

- **Consulta cargada:** `stg_productividad` en [`02_staging/staging_productividad.xlsx`](staging_productividad.xlsx).
- **Conteo final:** `1.197` filas cargadas (`100%` respecto a `01_raw`), **`0` errores** de conversión o carga.
- **Higiene de archivo:** libro guardado y cerrado (sin archivos temporales `~$*`).
