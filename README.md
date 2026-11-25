# Productividad y Cuellos de Botella en Planta Textil (Power BI + Excel)

Tablero ejecutivo y operativo para diagnosticar el cumplimiento de metas de producción, identificar los equipos que frenan la planta y cuantificar el impacto de horas extra, tiempo inactivo y cambios de estilo.

---

## 1. Pregunta de Negocio

> **¿Cumplimos la meta de producción y qué factores operativos están frenando a los equipos rezagados?**

El análisis está dividido en dos vistas conectadas mediante navegación interactiva y segmentadores sincronizados (**Mes**, **Departamento** y **Equipo**):

1. **Resumen Ejecutivo:** Visión gerencial del cumplimiento global, evolución diaria frente a la meta, comparativa entre departamentos (`Costura` vs. `Acabado`) y ranking de desempeño por equipo.
2. **Cuellos de Botella:** Diagnóstico operativo por equipo cruzando productividad real contra horas extra, tiempo inactivo, cambios de estilo y trabajo en proceso (WIP).

---

## 2. Vista Previa del Tablero

### Página 1 — Resumen Ejecutivo
![Resumen Ejecutivo](04_presentation/capturas/Resumen%20Ejecutivo.png)

### Página 2 — Cuellos de Botella
![Cuellos de Botella](04_presentation/capturas/Cuellos%20de%20Botella.png)

---

## 3. Hallazgos Principales (Trimestre Completo)

* **Cumplimiento global ajustado:** La planta cerró con una **Productividad Real de 73.5%** frente a una **Meta de 73.0%** (**+0.5%** de brecha y **100.7%** de cumplimiento), acumulando **91,121 horas extra**, **874 minutos inactivos**, **180 cambios de estilo** y un **WIP promedio de 1,190**.
* **6 de 12 equipos están bajo meta:** Aunque el promedio global es positivo, la mitad de los equipos presenta brecha negativa. Los casos críticos son **Equipo 07 (-4.6%)**, **Equipo 06 (-4.6%)** y **Equipo 08 (-3.4%)**.
* **El tiempo inactivo está altamente concentrado:** Solo dos equipos (**Equipo 08** con **313 min** y **Equipo 07** con **287 min**) concentran el **68.6%** de todo el tiempo inactivo de la planta (`600` de `874` min).
* **Más horas extra no garantizan mayor productividad:** En el gráfico de dispersión, **Equipo 07**, **Equipo 08**, **Equipo 09** y **Equipo 10** operan por encima del promedio de horas extra pero permanecen por debajo de la meta. En contraste, **Equipo 12** alcanza **77.9%** de productividad con apenas **5,475 horas extra**, **0 minutos inactivos** y **0 cambios de estilo**.
* **Los cambios de estilo golpean a los equipos rezagados:** **Equipo 08 (29 cambios)**, **Equipo 11 (25)** y **Equipo 07 (20)** encabezan la concentración de cambios de estilo y todos cierran en terreno negativo.

---

## 4. Recomendaciones Operativas

1. **Intervenir primero en Equipo 08 y Equipo 07:** Auditar las causas raíz de sus paros (`600 min` combinados) y reducir la frecuencia de cambios de estilo en sus líneas (`49` cambios combinados) antes de seguir asignando horas extra.
2. **Revisar la asignación de horas extra en Equipos 09 y 10:** Ambos consumen casi `7,900` horas extra cada uno sin cerrar la brecha (`-2.4%` y `-1.9%`), con tiempo inactivo mínimo (`0` y `16 min`). El foco debe estar en balanceo de línea y control de WIP (`1,528` en Equipo 10).
3. **Documentar las prácticas de Equipo 01 y Equipo 12:** Usar a **Equipo 01** (`82.1%` real, `+7.4%` brecha) y **Equipo 12** (alta eficiencia con baja dependencia de horas extra y cero paros) como referencia interna para estandarizar turnos.

---

## 5. Arquitectura y Herramientas

* **Herramientas:** Power BI Desktop, Microsoft Excel.
* **Modelo de Datos:** Esquema en estrella con tabla de hechos (`hecho_productividad`) relacionada (`1:*`, dirección única) con tres dimensiones: `dim_tiempo`, `dim_departamento` y `dim_equipo`.
* **Medidas DAX (`_Medidas`):** `Productividad Real`, `Productividad Meta`, `Brecha de Productividad`, `% Cumplimiento de Meta`, `% Turnos Bajo Meta`, `Horas Extra`, `Tiempo Inactivo (min)`, `Cambios de Estilo` y `WIP Promedio`.
* **Estructura del Proyecto:**
  * `01_raw/` — Dataset original.
  * `02_staging/` — Limpieza y preparación en Excel.
  * `03_model/` — Tablas dimensionales y de hechos.
  * `04_presentation/` — Archivo `.pbix` y carpeta `capturas/`.