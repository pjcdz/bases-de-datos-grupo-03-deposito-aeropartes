# Análisis de Normalización

Sistema de gestión de material - depósito de aeropartes. Se documentan las
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
| `Usuarios` | IdUsuario | IdUsuario → NombreUsuario, ApellidoUsuario, RolUsuario | 3FN |
| `TiposElemento` | IdTipoElemento | IdTipoElemento → NombreTipoElemento | 3FN |
| `SistemasArmas` | IdSistemaArmas | IdSistemaArmas → CodigoSistemaArmas, ModeloSistemaArmas | 3FN |
| `EstadosElemento` | IdEstadoElemento | IdEstadoElemento → CodigoEstadoElemento, DescripcionEstadoElemento | 3FN |
| `Ubicaciones` | IdUbicacion | IdUbicacion → DepositoUbicacion, SectorUbicacion, MapaHighlightUbicacion | 3FN |
| `MotivosSalida` | IdMotivoSalida | IdMotivoSalida → CodigoMotivoSalida, DescripcionMotivoSalida | 3FN |
| `CatalogoMateriales` | NNE | NNE → NumeroReferenciaMaterial, DesignacionMaterial, ATAMaterial, IdTipoElemento, IdUsuario | 3FN |
| `MaterialesSistemasArmas` | (IdSistemaArmas, NNE) | *(relación todo-clave: sin atributos no clave)* | 3FN / BCNF |
| `InventarioFisico` | IdItem | IdItem → NNE, NumeroSerieItem, FechaVencimientoItem, ObservacionesItem, TamanoItem, IdUbicacion | 3FN |
| `Tarjetas` | IdTarjeta | IdTarjeta → IdItem, IdEstadoElemento, CodigoTrazabilidadTarjeta, NumeroTarjeta, OrdenTrabajoTarjeta, FechaEmisionTarjeta, CausasTarjeta, InspectorTarjeta, ActivaTarjeta | 3FN |
| `MovimientosInventario` | IdMovimiento | IdMovimiento → IdItem, IdUbicacion, FechaRegistroMovimiento, AccionMovimiento, IdUsuarioRegistra, DetalleMovimiento | 3FN |
| `Salidas` | IdSalida | IdSalida → IdItem, IdMotivoSalida, DestinoSalida, FechaSalida, FechaPrevistaRetornoSalida, FechaRetornoSalida, RetiradoPorSalida, ObservacionesSalida | 3FN |

---

## 2. Justificación por forma normal

### 1FN - atomicidad y sin grupos repetidos
- Todos los atributos son atómicos (no hay listas ni valores separados por comas).
- **Caso clave:** un mismo material puede servir a varios sistemas de armas. En vez de
  columnas repetidas (`sistema1`, `sistema2`, …) -que violarían 1FN- se resuelve con la tabla
  intermedia `MaterialesSistemasArmas`. Cada par (sistema, material) es una fila.
- Cada tabla tiene clave primaria, por lo tanto no hay filas duplicadas.

### 2FN - sin dependencias parciales
- La única tabla con **clave compuesta** es `MaterialesSistemasArmas`, cuya PK es
  `(IdSistemaArmas, NNE)`. Es una **relación todo-clave**: no tiene atributos no clave, así que
  no puede existir dependencia parcial. Cumple 2FN de forma trivial.
- El resto de las tablas tiene **clave primaria de un solo atributo**, y según el material *"una
  tabla con clave primaria de un solo atributo no puede exhibir dependencias parciales"*. Cumplen 2FN.

### 3FN - sin dependencias transitivas
El riesgo de dependencia transitiva aparece cuando se copia en una tabla un dato que en
realidad pertenece a otra entidad. Se evitó deliberadamente en tres puntos:

1. **`InventarioFisico` no guarda la `DesignacionMaterial`.** Si la guardara, habría una
   dependencia transitiva `IdItem → NNE → DesignacionMaterial`. En su lugar guarda solo `NNE` (FK) y la
   designación se obtiene con un JOIN al catálogo.
2. **`Tarjetas` no guarda el código ni la descripción del estado.** Guarda `IdEstadoElemento` (FK); el
   texto del estado vive solo en `EstadosElemento`. Se evita `IdTarjeta → IdEstadoElemento → CodigoEstadoElemento`.
3. **`Tarjetas` no duplica Nº de parte ni Nº de serie** (decisión P3). El Nº de serie pertenece al
   elemento (`InventarioFisico.NumeroSerieItem`) y el Nº de parte al catálogo (`NumeroReferenciaMaterial`).
   Duplicarlos en la tarjeta crearía redundancia y riesgo de inconsistencia; se derivan por JOIN.

Como ningún atributo no clave depende de otro atributo no clave, todas las tablas están en 3FN.

---

## 3. Nota sobre desnormalización deliberada (ubicación)

`Ubicaciones` mantiene juntos `DepositoUbicacion` y `SectorUbicacion`. Podría separarse el depósito en su
propia tabla (`Deposito 1 ── N Ubicaciones`), pero el material advierte que **el nivel máximo de
normalización no siempre conviene**: agregaría una tabla y joins sin beneficio real para este
dominio (la cantidad de depósitos es mínima y estable). Se documenta la decisión y se mantiene en
3FN, que el material señala como el mínimo recomendado para la mayoría de las bases.

---

## 4. Resumen

Todas las tablas cumplen **3FN**. Las decisiones de diseño que lo garantizan son:
- N:N resuelto con tabla intermedia (`MaterialesSistemasArmas`) → 1FN.
- Datos derivables (designación, estado, Nº de parte/serie) **no se duplican** → 3FN.
- Cada entidad real (usuario, ubicación, estado, motivo, catálogo, ejemplar, tarjeta, salida)
  tiene su propia tabla, con su clave y sus atributos dependiendo solo de esa clave.
