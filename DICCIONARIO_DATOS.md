# Diccionario de Datos

Sistema de Gestión de Material - depósito de aeropartes. Motor: Microsoft SQL Server.
Una fila por atributo. **Clave:** PK = primaria, FK = foránea, AK = alternativa (UNIQUE).

---

## Usuarios
Operarios del sistema (cargan fichas, registran movimientos).

| Campo | Tipo | NULL | Clave | Descripción | Dominio / Referencia |
|---|---|---|---|---|---|
| IdUsuario | INT IDENTITY | NO | PK | Identificador del usuario | autoincremental ≥ 1 |
| NombreUsuario | VARCHAR(100) | NO | | Nombre | texto |
| ApellidoUsuario | VARCHAR(100) | NO | | Apellido | texto |
| RolUsuario | VARCHAR(50) | NO | | Rol/función | texto |

## TiposElemento
Clasificación del material (rotable, herramienta, consumible, etc.).

| Campo | Tipo | NULL | Clave | Descripción | Dominio / Referencia |
|---|---|---|---|---|---|
| IdTipoElemento | INT IDENTITY | NO | PK | Identificador del tipo | autoincremental ≥ 1 |
| NombreTipoElemento | VARCHAR(100) | NO | AK | Nombre del tipo (único) | texto, UNIQUE |

## SistemasArmas
Aeronaves / sistemas a los que sirve el material.

| Campo | Tipo | NULL | Clave | Descripción | Dominio / Referencia |
|---|---|---|---|---|---|
| IdSistemaArmas | INT IDENTITY | NO | PK | Identificador del sistema | autoincremental ≥ 1 |
| CodigoSistemaArmas | VARCHAR(50) | NO | AK | Código del sistema (único) | código, UNIQUE |
| ModeloSistemaArmas | VARCHAR(100) | NO | | Modelo / denominación | texto |

## EstadosElemento
Catálogo de estados de la tarjeta (semilla fija).

| Campo | Tipo | NULL | Clave | Descripción | Dominio / Referencia |
|---|---|---|---|---|---|
| IdEstadoElemento | INT IDENTITY | NO | PK | Identificador del estado | autoincremental ≥ 1 |
| CodigoEstadoElemento | VARCHAR(30) | NO | AK | Código del estado | {EN_SERVICIO, EN_SERVICIO_TRANSITORIO, BAJA}, UNIQUE |
| DescripcionEstadoElemento | VARCHAR(255) | SÍ | | Descripción del estado | texto |

## Ubicaciones
Lugares físicos de almacenamiento dentro del depósito.

| Campo | Tipo | NULL | Clave | Descripción | Dominio / Referencia |
|---|---|---|---|---|---|
| IdUbicacion | INT IDENTITY | NO | PK | Identificador de la ubicación | autoincremental ≥ 1 |
| DepositoUbicacion | VARCHAR(100) | NO | | Depósito | texto |
| SectorUbicacion | VARCHAR(100) | SÍ | | Sector / estantería | texto |
| MapaHighlightUbicacion | VARCHAR(255) | SÍ | | Referencia visual en el mapa | texto |

## MotivosSalida
Catálogo de motivos de retiro del depósito (semilla fija).

| Campo | Tipo | NULL | Clave | Descripción | Dominio / Referencia |
|---|---|---|---|---|---|
| IdMotivoSalida | INT IDENTITY | NO | PK | Identificador del motivo | autoincremental ≥ 1 |
| CodigoMotivoSalida | VARCHAR(30) | NO | AK | Código del motivo | {PRESTAMO, REPARACION, INSPECCION, BAJA}, UNIQUE |
| DescripcionMotivoSalida | VARCHAR(255) | SÍ | | Descripción del motivo | texto |

## CatalogoMateriales
Ficha/modelo del material (qué es), identificada por su NNE.

| Campo | Tipo | NULL | Clave | Descripción | Dominio / Referencia |
|---|---|---|---|---|---|
| NNE | VARCHAR(20) | NO | PK | Número Nacional de Efecto | clave natural |
| NumeroReferenciaMaterial | VARCHAR(50) | SÍ | | Número de referencia / parte | código |
| DesignacionMaterial | VARCHAR(255) | NO | | Denominación del material | texto |
| ATAMaterial | VARCHAR(10) | SÍ | | Capítulo ATA | código numérico 0-99 (CHK_CatalogoMateriales_ATA) |
| IdTipoElemento | INT | NO | FK | Tipo de elemento | → TiposElemento(IdTipoElemento) |
| IdUsuario | INT | SÍ | FK | Usuario que cargó la ficha | → Usuarios(IdUsuario), ON DELETE SET NULL |

## MaterialesSistemasArmas
Relación N:N entre material y sistemas de armas (compatibilidad).

| Campo | Tipo | NULL | Clave | Descripción | Dominio / Referencia |
|---|---|---|---|---|---|
| IdSistemaArmas | INT | NO | PK, FK | Sistema de armas | → SistemasArmas(IdSistemaArmas), ON DELETE CASCADE |
| NNE | VARCHAR(20) | NO | PK, FK | Material | → CatalogoMateriales(NNE), ON DELETE CASCADE |

## InventarioFisico
Cada ejemplar físico real de un material del catálogo.

| Campo | Tipo | NULL | Clave | Descripción | Dominio / Referencia |
|---|---|---|---|---|---|
| IdItem | INT IDENTITY | NO | PK | Identificador del ejemplar | autoincremental ≥ 1 |
| NNE | VARCHAR(20) | NO | FK | Material del catálogo | → CatalogoMateriales(NNE) |
| NumeroSerieItem | VARCHAR(100) | SÍ | | Número de serie del ejemplar | código |
| FechaVencimientoItem | DATE | SÍ | | Fecha de vencimiento | fecha |
| ObservacionesItem | VARCHAR(500) | SÍ | | Observaciones | texto |
| TamanoItem | VARCHAR(50) | SÍ | | Tamaño / medida | texto |
| IdUbicacion | INT | SÍ | FK | Ubicación; NULL = fuera del depósito | → Ubicaciones(IdUbicacion), ON DELETE SET NULL |

## Tarjetas
Tarjeta física atada al ejemplar; su estado activo es el estado del elemento.

| Campo | Tipo | NULL | Clave | Descripción | Dominio / Referencia |
|---|---|---|---|---|---|
| IdTarjeta | INT IDENTITY | NO | PK | Identificador de la tarjeta | autoincremental ≥ 1 |
| IdItem | INT | NO | FK | Ejemplar al que va atada | → InventarioFisico(IdItem), ON DELETE CASCADE |
| IdEstadoElemento | INT | NO | FK | Estado de la tarjeta | → EstadosElemento(IdEstadoElemento) |
| CodigoTrazabilidadTarjeta | VARCHAR(50) | SÍ | | Código de trazabilidad | código |
| NumeroTarjeta | VARCHAR(30) | SÍ | | Nº impreso en la tarjeta | código |
| OrdenTrabajoTarjeta | VARCHAR(30) | SÍ | | Orden de trabajo | código |
| FechaEmisionTarjeta | DATE | NO | | Fecha de emisión (default hoy) | fecha |
| CausasTarjeta | VARCHAR(500) | SÍ | | Causas de rechazo/remoción | texto |
| InspectorTarjeta | VARCHAR(100) | SÍ | | Firma/aclaración del inspector | texto |
| ActivaTarjeta | BIT | NO | | 1 = tarjeta vigente (única por ejemplar) | {0,1}, default 1 |

## MovimientosInventario
Bitácora de trazabilidad de cada elemento.

| Campo | Tipo | NULL | Clave | Descripción | Dominio / Referencia |
|---|---|---|---|---|---|
| IdMovimiento | INT IDENTITY | NO | PK | Identificador del movimiento | autoincremental ≥ 1 |
| IdItem | INT | NO | FK | Ejemplar afectado | → InventarioFisico(IdItem), ON DELETE CASCADE |
| IdUbicacion | INT | SÍ | FK | Ubicación; NULL = elemento afuera | → Ubicaciones(IdUbicacion), ON DELETE SET NULL |
| FechaRegistroMovimiento | DATETIME2(0) | NO | | Fecha y hora (default ahora) | fecha-hora |
| AccionMovimiento | VARCHAR(50) | NO | | Acción registrada | texto |
| IdUsuarioRegistra | INT | SÍ | FK | Usuario que registró | → Usuarios(IdUsuario), ON DELETE SET NULL |
| DetalleMovimiento | VARCHAR(500) | SÍ | | Detalle libre | texto |

## Salidas
Retiro del depósito (préstamo/reparación/inspección/baja) y su retorno.

| Campo | Tipo | NULL | Clave | Descripción | Dominio / Referencia |
|---|---|---|---|---|---|
| IdSalida | INT IDENTITY | NO | PK | Identificador de la salida | autoincremental ≥ 1 |
| IdItem | INT | NO | FK | Ejemplar que se retira | → InventarioFisico(IdItem), ON DELETE CASCADE |
| IdMotivoSalida | INT | NO | FK | Motivo de la salida | → MotivosSalida(IdMotivoSalida) |
| DestinoSalida | VARCHAR(255) | SÍ | | A dónde va | texto |
| FechaSalida | DATETIME2(0) | NO | | Fecha y hora de salida (default ahora) | fecha-hora |
| FechaPrevistaRetornoSalida | DATE | SÍ | | Retorno previsto | fecha, CHECK ≥ FechaSalida |
| FechaRetornoSalida | DATETIME2(0) | SÍ | | Retorno real; NULL = sigue afuera | fecha-hora, CHECK ≥ FechaSalida |
| RetiradoPorSalida | VARCHAR(100) | SÍ | | Persona que retiró | texto |
| ObservacionesSalida | VARCHAR(500) | SÍ | | Observaciones | texto |

---

### Restricciones destacadas
- **CHK_Salidas_RetornoPosterior / CHK_Salidas_PrevistaPosterior**: coherencia de fechas en `Salidas`.
- Las reglas "una sola tarjeta activa por elemento" y "una sola salida abierta por elemento" se garantizan desde los procedimientos almacenados (`sp_AltaElemento`, `sp_CambiarEstado`, `sp_RegistrarSalida`).
