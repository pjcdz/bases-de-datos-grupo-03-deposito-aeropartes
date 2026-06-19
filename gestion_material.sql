/* ============================================================================
   Sistema de Gestion de Material — Microsoft SQL Server (T-SQL)
   ARCHIVO 01 de 06 — ESQUEMA (DDL): tablas, restricciones, indices y semilla.

   Convencion de escritura (estilo de catedra):
     - Tablas en PascalCase y plural (Usuarios, Salidas...).
     - PK surrogate INT IDENTITY(1,1) PRIMARY KEY en linea; PK natural (NNE) tambien.
     - Columnas con sufijo de entidad (NombreUsuario, FechaSalida...).
     - NVARCHAR para texto libre; VARCHAR/CHAR para codigos y documentos.
     - Restricciones nombradas: PK_/FK_/UQ_/CHK_.
     - Se comenta cada bloque indicando la consigna que cumple.

   Orden de ejecucion del proyecto:
     01) gestion_material.sql              <- ESTE archivo (esquema + semilla)
     02) 02_programabilidad.sql            funciones, triggers, procedimientos, cursor
     03) 03_crud.sql                       procedimientos CRUD por tabla
     04) 04_vistas.sql                     vistas
     05) 05_datos_ejemplo.sql              datos de prueba (usa los procedimientos)
     06) 06_consultas_demostracion.sql     consultas de demostracion (SQL avanzado)

   Decisiones de modelo aplicadas (ver DECISIONES_EQUIPO.md):
     - P1-C: el usuario que REGISTRA un movimiento es FK a Usuarios
             (MovimientosInventario.IdUsuarioRegistra). El inspector de la tarjeta
             y quien retira en una salida quedan como texto (firman en papel).
     - P2-A: la relacion Usuarios->CatalogoMateriales se interpreta como "registra/carga".
     - P3-A: Nro de parte y Nro de serie NO se duplican en la tarjeta: se derivan
             del elemento (NumeroSerieItem) y del catalogo (NumeroReferenciaMaterial/NNE).
     - P4-A: MovimientosInventario.IdUbicacion es NULL-able (NULL = fuera del deposito).
     - P13-A: se agregan CHECK (coherencia de fechas) y politicas ON DELETE.

   Modelo de fondo:
     - CatalogoMateriales = ficha/modelo (NNE). InventarioFisico = ejemplar real.
     - Tarjetas atadas al elemento; UNA activa a la vez; el resto es historial.
     - el ESTADO del elemento vive en su tarjeta activa.
     - Salidas = retiro del deposito (prestamo/reparacion/inspeccion/baja);
       IdUbicacion del elemento en NULL = esta afuera.
   ============================================================================ */

-- Descomentar si se quiere crear la base de datos:
-- CREATE DATABASE GestionMaterial;
-- GO
-- USE GestionMaterial;
-- GO

-- Requerido para indices filtrados y para crear triggers/procedimientos.
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* ---------- Limpieza (orden inverso de dependencias) ---------- */
-- Programabilidad (por si se re-ejecuta el proyecto completo)
DROP TRIGGER IF EXISTS trg_salida_abre_saca_del_deposito;
DROP TRIGGER IF EXISTS trg_salida_baja_genera_tarjeta;
DROP TRIGGER IF EXISTS trg_tarjeta_no_reactiva_baja;
DROP TRIGGER IF EXISTS trg_estado_no_borrar;
GO
DROP VIEW IF EXISTS vw_elementos_afuera;
DROP VIEW IF EXISTS vw_stock_disponible;
DROP VIEW IF EXISTS vw_historial_tarjetas;
DROP VIEW IF EXISTS vw_elementos_vencidos;
GO
DROP PROCEDURE IF EXISTS sp_AltaElemento;
DROP PROCEDURE IF EXISTS sp_RegistrarSalida;
DROP PROCEDURE IF EXISTS sp_RegistrarRetorno;
DROP PROCEDURE IF EXISTS sp_CambiarEstado;
DROP PROCEDURE IF EXISTS sp_ReporteSalidasVencidas;
GO
DROP FUNCTION IF EXISTS fn_DiasFueraDeposito;
DROP FUNCTION IF EXISTS fn_EstadoActual;
DROP FUNCTION IF EXISTS fn_DiasParaVencer;
GO
-- Tablas
DROP TABLE IF EXISTS Salidas;
DROP TABLE IF EXISTS MovimientosInventario;
DROP TABLE IF EXISTS Tarjetas;
DROP TABLE IF EXISTS InventarioFisico;
DROP TABLE IF EXISTS MotivosSalida;
DROP TABLE IF EXISTS MaterialesSistemasArmas;
DROP TABLE IF EXISTS CatalogoMateriales;
DROP TABLE IF EXISTS SistemasArmas;
DROP TABLE IF EXISTS TiposElemento;
DROP TABLE IF EXISTS EstadosElemento;
DROP TABLE IF EXISTS Ubicaciones;
DROP TABLE IF EXISTS Usuarios;
GO

/* ==================== Tablas maestras ==================== */

-- 1. Usuarios: operarios del sistema (cargan fichas, registran movimientos).
CREATE TABLE Usuarios (
    IdUsuario       INT IDENTITY(1,1) PRIMARY KEY,
    NombreUsuario   NVARCHAR(100) NOT NULL,
    ApellidoUsuario NVARCHAR(100) NOT NULL,
    RolUsuario      NVARCHAR(50)  NOT NULL
);
GO

-- 2. TiposElemento: clasificacion del material (rotable, herramienta, etc.).
CREATE TABLE TiposElemento (
    IdTipoElemento     INT IDENTITY(1,1) PRIMARY KEY,
    NombreTipoElemento NVARCHAR(100) NOT NULL,
    CONSTRAINT UQ_TiposElemento_Nombre UNIQUE (NombreTipoElemento) -- nombre de tipo unico
);
GO

-- 3. SistemasArmas: aeronaves / sistemas a los que sirve el material.
CREATE TABLE SistemasArmas (
    IdSistemaArmas     INT IDENTITY(1,1) PRIMARY KEY,
    CodigoSistemaArmas VARCHAR(50)   NOT NULL,  -- codigo -> VARCHAR
    ModeloSistemaArmas NVARCHAR(100) NOT NULL,
    CONSTRAINT UQ_SistemasArmas_Codigo UNIQUE (CodigoSistemaArmas)
);
GO

-- 4. EstadosElemento: catalogo de estados de la tarjeta (semilla fija).
CREATE TABLE EstadosElemento (
    IdEstadoElemento          INT IDENTITY(1,1) PRIMARY KEY,
    CodigoEstadoElemento      VARCHAR(30)   NOT NULL,
    DescripcionEstadoElemento NVARCHAR(255) NULL,
    CONSTRAINT UQ_EstadosElemento_Codigo UNIQUE (CodigoEstadoElemento),
    CONSTRAINT CHK_EstadosElemento_Codigo CHECK (LEN(CodigoEstadoElemento) > 0) -- dominio: no vacio
);
GO

-- 5. Ubicaciones: lugares fisicos de almacenamiento dentro del deposito.
CREATE TABLE Ubicaciones (
    IdUbicacion            INT IDENTITY(1,1) PRIMARY KEY,
    DepositoUbicacion      NVARCHAR(100) NOT NULL,
    SectorUbicacion        NVARCHAR(100) NULL,
    MapaHighlightUbicacion NVARCHAR(255) NULL
);
GO

-- 6. MotivosSalida: catalogo de motivos de retiro del deposito (semilla fija).
CREATE TABLE MotivosSalida (
    IdMotivoSalida          INT IDENTITY(1,1) PRIMARY KEY,
    CodigoMotivoSalida      VARCHAR(30)   NOT NULL,
    DescripcionMotivoSalida NVARCHAR(255) NULL,
    CONSTRAINT UQ_MotivosSalida_Codigo UNIQUE (CodigoMotivoSalida),
    CONSTRAINT CHK_MotivosSalida_Codigo CHECK (LEN(CodigoMotivoSalida) > 0)
);
GO

/* ==================== Catalogo ==================== */

-- 7. CatalogoMateriales: ficha/modelo del material (que es), PK natural NNE.
CREATE TABLE CatalogoMateriales (
    NNE                      NVARCHAR(20)  NOT NULL PRIMARY KEY, -- Numero Nacional de Efecto (clave natural)
    NumeroReferenciaMaterial VARCHAR(50)   NULL,                 -- Nro de referencia / parte (codigo)
    DesignacionMaterial      NVARCHAR(255) NOT NULL,
    ATAMaterial              VARCHAR(10)   NULL,                 -- capitulo ATA (codigo)
    IdTipoElemento           INT NOT NULL,                       -- "clasifica": TiposElemento (1)-(N) Catalogo
    IdUsuario                INT NULL,                           -- "registra": Usuarios (1)-(N) Catalogo
    CONSTRAINT FK_CatalogoMateriales_TiposElemento
        FOREIGN KEY (IdTipoElemento) REFERENCES TiposElemento (IdTipoElemento),
    CONSTRAINT FK_CatalogoMateriales_Usuarios
        FOREIGN KEY (IdUsuario) REFERENCES Usuarios (IdUsuario)
        ON DELETE SET NULL                                       -- si se borra el usuario, la ficha queda sin "cargado por"
);
GO

-- 8. MaterialesSistemasArmas: relacion N:N material-sistema (compatibilidad).
--    PK compuesta = relacion todo-clave, sin dependencias parciales (2FN).
CREATE TABLE MaterialesSistemasArmas (
    IdSistemaArmas INT          NOT NULL,
    NNE            NVARCHAR(20) NOT NULL,
    CONSTRAINT PK_MaterialesSistemasArmas PRIMARY KEY (IdSistemaArmas, NNE),
    CONSTRAINT FK_MaterialesSistemasArmas_SistemasArmas
        FOREIGN KEY (IdSistemaArmas) REFERENCES SistemasArmas (IdSistemaArmas)
        ON DELETE CASCADE,
    CONSTRAINT FK_MaterialesSistemasArmas_CatalogoMateriales
        FOREIGN KEY (NNE) REFERENCES CatalogoMateriales (NNE)
        ON DELETE CASCADE
);
GO

/* ==================== Inventario ==================== */

-- 9. InventarioFisico: cada ejemplar fisico real de un material del catalogo.
CREATE TABLE InventarioFisico (
    IdItem               INT IDENTITY(1,1) PRIMARY KEY,
    NNE                  NVARCHAR(20)  NOT NULL,   -- "instancia": Catalogo (1)-(N) Inventario
    NumeroSerieItem      VARCHAR(100)  NULL,       -- numero de serie (codigo)
    FechaVencimientoItem DATE          NULL,
    ObservacionesItem    NVARCHAR(500) NULL,
    TamanoItem           NVARCHAR(50)  NULL,
    IdUbicacion          INT           NULL,       -- "almacena"; NULL = fuera del deposito
    CONSTRAINT FK_InventarioFisico_CatalogoMateriales
        FOREIGN KEY (NNE) REFERENCES CatalogoMateriales (NNE),
    CONSTRAINT FK_InventarioFisico_Ubicaciones
        FOREIGN KEY (IdUbicacion) REFERENCES Ubicaciones (IdUbicacion)
        ON DELETE SET NULL                          -- si se borra una ubicacion, el elemento queda "sin ubicar"
);
GO

-- 10. Tarjetas: tarjeta fisica atada al elemento. El estado del elemento es el
--     estado de su tarjeta activa. Nro de parte/serie se DERIVAN (no se duplican).
CREATE TABLE Tarjetas (
    IdTarjeta                 INT IDENTITY(1,1) PRIMARY KEY,
    IdItem                    INT NOT NULL,            -- elemento al que esta atada
    IdEstadoElemento          INT NOT NULL,            -- estado de la tarjeta (verde/blanca/baja)
    CodigoTrazabilidadTarjeta VARCHAR(50)   NULL,
    NumeroTarjeta             VARCHAR(30)   NULL,      -- Nro impreso en la tarjeta fisica
    OrdenTrabajoTarjeta       VARCHAR(30)   NULL,      -- orden de trabajo
    FechaEmisionTarjeta       DATE NOT NULL DEFAULT CAST(SYSDATETIME() AS DATE),
    CausasTarjeta             NVARCHAR(500) NULL,      -- causas de rechazo / remocion
    InspectorTarjeta          NVARCHAR(100) NULL,      -- firma y aclaracion (persona fisica, texto)
    ActivaTarjeta             BIT NOT NULL DEFAULT 1,
    CONSTRAINT FK_Tarjetas_InventarioFisico
        FOREIGN KEY (IdItem) REFERENCES InventarioFisico (IdItem)
        ON DELETE CASCADE,                             -- si se borra el elemento, se va su historial de tarjetas
    CONSTRAINT FK_Tarjetas_EstadosElemento
        FOREIGN KEY (IdEstadoElemento) REFERENCES EstadosElemento (IdEstadoElemento)
);
GO

-- Integridad dura: UNA sola tarjeta activa por elemento (indice unico filtrado).
CREATE UNIQUE INDEX UQ_Tarjetas_ActivaPorItem
    ON Tarjetas (IdItem) WHERE ActivaTarjeta = 1;
GO

-- 11. MovimientosInventario: bitacora de trazabilidad de cada elemento.
CREATE TABLE MovimientosInventario (
    IdMovimiento            INT IDENTITY(1,1) PRIMARY KEY,
    IdItem                  INT NOT NULL,           -- "afecta": Movimiento (N)-(1) Inventario
    IdUbicacion             INT NULL,               -- "registra"; NULL = movimiento con el elemento afuera (P4-A)
    FechaRegistroMovimiento DATETIME2(0) NOT NULL DEFAULT SYSDATETIME(),
    AccionMovimiento        NVARCHAR(50)  NOT NULL,
    IdUsuarioRegistra       INT NULL,               -- "registra": Usuarios (1)-(N) Movimiento (P1-C)
    DetalleMovimiento       NVARCHAR(500) NULL,
    CONSTRAINT FK_MovimientosInventario_InventarioFisico
        FOREIGN KEY (IdItem) REFERENCES InventarioFisico (IdItem)
        ON DELETE CASCADE,
    CONSTRAINT FK_MovimientosInventario_Ubicaciones
        FOREIGN KEY (IdUbicacion) REFERENCES Ubicaciones (IdUbicacion)
        ON DELETE SET NULL,
    CONSTRAINT FK_MovimientosInventario_Usuarios
        FOREIGN KEY (IdUsuarioRegistra) REFERENCES Usuarios (IdUsuario)
        ON DELETE SET NULL
);
GO

-- 12. Salidas: retiro del deposito (prestamo/reparacion/inspeccion/baja).
--     FechaRetornoSalida NULL = el elemento sigue afuera (la baja nunca retorna).
CREATE TABLE Salidas (
    IdSalida                   INT IDENTITY(1,1) PRIMARY KEY,
    IdItem                     INT NOT NULL,
    IdMotivoSalida             INT NOT NULL,
    DestinoSalida              NVARCHAR(255) NULL,   -- taller, unidad a la que se presta, etc.
    FechaSalida                DATETIME2(0) NOT NULL DEFAULT SYSDATETIME(),
    FechaPrevistaRetornoSalida DATE NULL,
    FechaRetornoSalida         DATETIME2(0) NULL,
    RetiradoPorSalida          NVARCHAR(100) NULL,   -- persona fisica (texto)
    ObservacionesSalida        NVARCHAR(500) NULL,
    CONSTRAINT FK_Salidas_InventarioFisico
        FOREIGN KEY (IdItem) REFERENCES InventarioFisico (IdItem)
        ON DELETE CASCADE,
    CONSTRAINT FK_Salidas_MotivosSalida
        FOREIGN KEY (IdMotivoSalida) REFERENCES MotivosSalida (IdMotivoSalida),
    -- P13-A: coherencia de fechas
    CONSTRAINT CHK_Salidas_RetornoPosterior
        CHECK (FechaRetornoSalida IS NULL OR FechaRetornoSalida >= FechaSalida),
    CONSTRAINT CHK_Salidas_PrevistaPosterior
        CHECK (FechaPrevistaRetornoSalida IS NULL OR FechaPrevistaRetornoSalida >= CAST(FechaSalida AS DATE))
);
GO

-- Integridad dura: un elemento no puede tener dos salidas abiertas a la vez.
CREATE UNIQUE INDEX UQ_Salidas_AbiertaPorItem
    ON Salidas (IdItem) WHERE FechaRetornoSalida IS NULL;
GO

/* ==================== Indices sobre FKs ==================== */

CREATE INDEX IX_CatalogoMateriales_TipoElemento ON CatalogoMateriales (IdTipoElemento);
CREATE INDEX IX_CatalogoMateriales_Usuario      ON CatalogoMateriales (IdUsuario);
CREATE INDEX IX_MaterialesSistemasArmas_NNE     ON MaterialesSistemasArmas (NNE);
CREATE INDEX IX_InventarioFisico_NNE            ON InventarioFisico (NNE);
CREATE INDEX IX_InventarioFisico_Ubicacion      ON InventarioFisico (IdUbicacion);
CREATE INDEX IX_Tarjetas_Item                   ON Tarjetas (IdItem);
CREATE INDEX IX_Tarjetas_Estado                 ON Tarjetas (IdEstadoElemento);
CREATE INDEX IX_MovimientosInventario_Item      ON MovimientosInventario (IdItem);
CREATE INDEX IX_MovimientosInventario_Fecha     ON MovimientosInventario (FechaRegistroMovimiento);
CREATE INDEX IX_Salidas_Item                    ON Salidas (IdItem);
CREATE INDEX IX_Salidas_Motivo                  ON Salidas (IdMotivoSalida);
GO

/* ==================== Datos semilla: catalogos fijos ====================
   estados basados en las tarjetas fisicas del taller (I Brigada Aerea - G.T.1) */

INSERT INTO EstadosElemento (CodigoEstadoElemento, DescripcionEstadoElemento) VALUES
    ('EN_SERVICIO',             N'En servicio — operativo (tarjeta verde)'),
    ('EN_SERVICIO_TRANSITORIO', N'En servicio transitorio — pendiente de envio a reparacion (tarjeta blanca)'),
    ('BAJA',                    N'Baja — elemento fuera de circulacion');
GO

INSERT INTO MotivosSalida (CodigoMotivoSalida, DescripcionMotivoSalida) VALUES
    ('PRESTAMO',   N'Prestado — retorna al deposito al ser devuelto'),
    ('REPARACION', N'Enviado a reparacion — retorna al deposito'),
    ('INSPECCION', N'Enviado a inspeccion/verificacion — retorna al deposito'),
    ('BAJA',       N'Baja definitiva — no retorna al deposito');
GO

PRINT '01 - Esquema creado correctamente.';
GO
