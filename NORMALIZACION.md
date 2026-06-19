# Análisis de Normalización

Sistema de gestión de material — depósito de aeropartes. Se documentan las
**dependencias funcionales (DF)** de cada tabla y se justifica que el modelo
está en **Tercera Forma Normal (3FN)**.

> **Recordatorio de las reglas (material de la materia):**
> - **1FN:** valores atómicos, sin grupos repetidos, filas únicas con clave primaria.
> - **2FN:** está en 1FN y **ningún atributo no clave depende de parte** de una clave compuesta (sin dependencias parciales).
> - **3FN:** está en 2FN y **ningún atributo no clave depende de otro no clave** (sin dependencias transitivas).

---

## 1. Dependencias funcionales por tabla

| Tabla | Clave primaria | Dependencias funcionales | Forma normal |
|---|---|---|---|
| `usuario` | id_usuario | id_usuario → nombre, apellido, rol | 3FN |
| `tipo_elemento` | id_tipo | id_tipo → nombre | 3FN |
| `sistema_armas` | id_sist_armas | id_sist_armas → codigo, modelo | 3FN |
| `estado_elemento` | id_estado | id_estado → codigo, descripcion | 3FN |
| `ubicacion` | id_ubicacion | id_ubicacion → deposito, sector, mapa_highlight | 3FN |
| `motivo_salida` | id_motivo | id_motivo → codigo, descripcion | 3FN |
| `catalogo_material` | NNE | NNE → NREF, designacion, ATA, id_tipo_elemento, id_usuario | 3FN |
| `material_sist_armas` | (id_sist_armas, NNE) | *(relación todo-clave: sin atributos no clave)* | 3FN / BCNF |
| `inventario_fisico` | id_item | id_item → NNE, n_serie, vencimiento, observaciones, tamaño, id_ubicacion | 3FN |
| `tarjeta` | id_tarjeta | id_tarjeta → id_item, id_estado, codigo_trazabilidad, nro_tarjeta, ot, fecha_emision, causas, inspector, activa | 3FN |
| `movimiento_inventario` | id_movimiento | id_movimiento → id_item, id_ubicacion, fecha_registro, accion, id_usuario_registra, detalle | 3FN |
| `salida` | id_salida | id_salida → id_item, id_motivo, destino, fecha_salida, fecha_prevista_retorno, fecha_retorno, retirado_por, observaciones | 3FN |

---

## 2. Justificación por forma normal

### 1FN — atomicidad y sin grupos repetidos
- Todos los atributos son atómicos (no hay listas ni valores separados por comas).
- **Caso clave:** un mismo material puede servir a varios sistemas de armas. En vez de
  columnas repetidas (`sistema1`, `sistema2`, …) —que violarían 1FN— se resuelve con la tabla
  intermedia `material_sist_armas`. Cada par (sistema, material) es una fila.
- Cada tabla tiene clave primaria, por lo tanto no hay filas duplicadas.

### 2FN — sin dependencias parciales
- La única tabla con **clave compuesta** es `material_sist_armas`, cuya PK es
  `(id_sist_armas, NNE)`. Es una **relación todo-clave**: no tiene atributos no clave, así que
  no puede existir dependencia parcial. Cumple 2FN de forma trivial.
- El resto de las tablas tiene **clave primaria de un solo atributo**, y según el material *"una
  tabla con clave primaria de un solo atributo no puede exhibir dependencias parciales"*. Cumplen 2FN.

### 3FN — sin dependencias transitivas
El riesgo de dependencia transitiva aparece cuando se copia en una tabla un dato que en
realidad pertenece a otra entidad. Se evitó deliberadamente en tres puntos:

1. **`inventario_fisico` no guarda la `designacion` del material.** Si la guardara, habría una
   dependencia transitiva `id_item → NNE → designacion`. En su lugar guarda solo `NNE` (FK) y la
   designación se obtiene con un JOIN al catálogo.
2. **`tarjeta` no guarda el código ni la descripción del estado.** Guarda `id_estado` (FK); el
   texto del estado vive solo en `estado_elemento`. Se evita `id_tarjeta → id_estado → codigo`.
3. **`tarjeta` no duplica Nº de parte ni Nº de serie** (decisión P3). El Nº de serie pertenece al
   elemento (`inventario_fisico.n_serie`) y el Nº de parte al catálogo (`NREF`). Duplicarlos en la
   tarjeta crearía redundancia y riesgo de inconsistencia; se derivan por JOIN.

Como ningún atributo no clave depende de otro atributo no clave, todas las tablas están en 3FN.

---

## 3. Nota sobre desnormalización deliberada (ubicación)

`ubicacion` mantiene juntos `deposito` y `sector`. Podría separarse `deposito` en su propia
tabla (`deposito 1 ── N ubicacion`), pero el material advierte que **el nivel máximo de
normalización no siempre conviene**: agregaría una tabla y joins sin beneficio real para este
dominio (la cantidad de depósitos es mínima y estable). Se documenta la decisión y se mantiene en
3FN, que el material señala como el mínimo recomendado para la mayoría de las bases.

---

## 4. Resumen

Todas las tablas cumplen **3FN**. Las decisiones de diseño que lo garantizan son:
- N:N resuelto con tabla intermedia (`material_sist_armas`) → 1FN.
- Datos derivables (designación, estado, Nº de parte/serie) **no se duplican** → 3FN.
- Cada entidad real (usuario, ubicación, estado, motivo, catálogo, ejemplar, tarjeta, salida)
  tiene su propia tabla, con su clave y sus atributos dependiendo solo de esa clave.
