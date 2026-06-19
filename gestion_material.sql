/* ============================================================================
   Sistema de Gestión de Material — Microsoft SQL Server (T-SQL)
   ARCHIVO 01 de 05 — ESQUEMA (DDL): tablas, restricciones, índices y semilla.

   Orden de ejecución del proyecto:
     01) gestion_material.sql              <- ESTE archivo (esquema + semilla)
     02) 02_programabilidad.sql            funciones, triggers, procedimientos, cursor
     03) 03_vistas.sql                     vistas
     04) 04_datos_ejemplo.sql              datos de prueba (usa los procedimientos)
     05) 05_consultas_demostracion.sql     consultas de demostración (SQL avanzado)

   Decisiones de modelo aplicadas (ver DECISIONES_EQUIPO.md):
     - P1-C: el usuario que REGISTRA un movimiento es FK a usuario
             (movimiento_inventario.id_usuario_registra). El inspector de la
             tarjeta y quien retira en una salida quedan como texto (firman en
             papel, no son cuentas del sistema).
     - P2-A: la relación usuario→catalogo se interpreta como "registra/carga"
             (quién dio de alta la ficha), no como "consulta".
     - P3-A: Nº de parte y Nº de serie NO se duplican en la tarjeta: se derivan
             del elemento (n_serie) y del catálogo (NREF/NNE). Normalización.
     - P4-A: movimiento_inventario.id_ubicacion pasa a ser NULL-able
             (NULL = el movimiento ocurrió con el elemento fuera del depósito).
     - P13-A: se agregan CHECK (coherencia de fechas) y políticas ON DELETE.

   Modelo de fondo:
     - catalogo_material = ficha/modelo (NNE). inventario_fisico = ejemplar real.
     - tarjeta atada al elemento; UNA activa a la vez; el resto es historial.
     - el ESTADO del elemento vive en su tarjeta activa.
     - salida = retiro del depósito (préstamo/reparación/inspección/baja);
       id_ubicacion del elemento en NULL = está afuera.
   ============================================================================ */

-- Descomentar si se quiere crear la base de datos:
-- CREATE DATABASE gestion_material;
-- GO
-- USE gestion_material;
-- GO

-- Requerido para índices filtrados y para crear triggers/procedimientos.
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* ---------- Limpieza (orden inverso de dependencias) ---------- */
-- Programabilidad (por si se re-ejecuta el proyecto completo)
DROP TRIGGER IF EXISTS trg_salida_abre_saca_del_deposito;
DROP TRIGGER IF EXISTS trg_salida_baja_genera_tarjeta;
DROP TRIGGER IF EXISTS trg_tarjeta_no_reactiva_baja;
DROP TRIGGER IF EXISTS trg_tarjeta_no_borrar_historial;
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
DROP TABLE IF EXISTS salida;
DROP TABLE IF EXISTS movimiento_inventario;
DROP TABLE IF EXISTS tarjeta;
DROP TABLE IF EXISTS inventario_fisico;
DROP TABLE IF EXISTS motivo_salida;
DROP TABLE IF EXISTS material_sist_armas;
DROP TABLE IF EXISTS catalogo_material;
DROP TABLE IF EXISTS sistema_armas;
DROP TABLE IF EXISTS tipo_elemento;
DROP TABLE IF EXISTS estado_elemento;
DROP TABLE IF EXISTS ubicacion;
DROP TABLE IF EXISTS usuario;
GO

/* ==================== Tablas maestras ==================== */

CREATE TABLE usuario (
    id_usuario  INT IDENTITY(1,1) NOT NULL,
    nombre      NVARCHAR(100) NOT NULL,
    apellido    NVARCHAR(100) NOT NULL,
    rol         NVARCHAR(50)  NOT NULL,
    CONSTRAINT PK_usuario PRIMARY KEY (id_usuario)
);
GO

CREATE TABLE tipo_elemento (
    id_tipo  INT IDENTITY(1,1) NOT NULL,
    nombre   NVARCHAR(100) NOT NULL,
    CONSTRAINT PK_tipo_elemento PRIMARY KEY (id_tipo),
    CONSTRAINT UQ_tipo_elemento_nombre UNIQUE (nombre)
);
GO

CREATE TABLE sistema_armas (
    id_sist_armas  INT IDENTITY(1,1) NOT NULL,
    codigo         NVARCHAR(50)  NOT NULL,
    modelo         NVARCHAR(100) NOT NULL,
    CONSTRAINT PK_sistema_armas PRIMARY KEY (id_sist_armas),
    CONSTRAINT UQ_sistema_armas_codigo UNIQUE (codigo)
);
GO

CREATE TABLE estado_elemento (
    id_estado    INT IDENTITY(1,1) NOT NULL,
    codigo       NVARCHAR(30)  NOT NULL,
    descripcion  NVARCHAR(255) NULL,
    CONSTRAINT PK_estado_elemento PRIMARY KEY (id_estado),
    CONSTRAINT UQ_estado_elemento_codigo UNIQUE (codigo),
    CONSTRAINT CK_estado_codigo CHECK (LEN(codigo) > 0)
);
GO

CREATE TABLE ubicacion (
    id_ubicacion    INT IDENTITY(1,1) NOT NULL,
    deposito        NVARCHAR(100) NOT NULL,
    sector          NVARCHAR(100) NULL,
    mapa_highlight  NVARCHAR(255) NULL,
    CONSTRAINT PK_ubicacion PRIMARY KEY (id_ubicacion)
);
GO

CREATE TABLE motivo_salida (
    id_motivo    INT IDENTITY(1,1) NOT NULL,
    codigo       NVARCHAR(30)  NOT NULL,
    descripcion  NVARCHAR(255) NULL,
    CONSTRAINT PK_motivo_salida PRIMARY KEY (id_motivo),
    CONSTRAINT UQ_motivo_salida_codigo UNIQUE (codigo),
    CONSTRAINT CK_motivo_codigo CHECK (LEN(codigo) > 0)
);
GO

/* ==================== Catálogo ==================== */

CREATE TABLE catalogo_material (
    NNE               NVARCHAR(20)  NOT NULL,   -- Número Nacional de Efecto (PK natural)
    NREF              NVARCHAR(50)  NULL,        -- Nº de referencia / parte (se DERIVA hacia la tarjeta)
    designacion       NVARCHAR(255) NOT NULL,
    ATA               NVARCHAR(10)  NULL,
    id_tipo_elemento  INT NOT NULL,             -- "clasifica": tipo_elemento (1) ── (N) catalogo
    id_usuario        INT NULL,                 -- "registra": usuario (1) ── (N) catalogo (quién cargó la ficha)
    CONSTRAINT PK_catalogo_material PRIMARY KEY (NNE),
    CONSTRAINT FK_catalogo_tipo
        FOREIGN KEY (id_tipo_elemento) REFERENCES tipo_elemento (id_tipo),
    CONSTRAINT FK_catalogo_usuario
        FOREIGN KEY (id_usuario) REFERENCES usuario (id_usuario)
        ON DELETE SET NULL                       -- si se borra el usuario, la ficha queda sin "cargado por"
);
GO

/* "utiliza/compatible": sistema_armas (N) ── (N) catalogo_material → tabla intermedia.
   PK compuesta: ejemplo de clave compuesta sin dependencias parciales (2FN). */
CREATE TABLE material_sist_armas (
    id_sist_armas  INT          NOT NULL,
    NNE            NVARCHAR(20) NOT NULL,
    CONSTRAINT PK_material_sist_armas PRIMARY KEY (id_sist_armas, NNE),
    CONSTRAINT FK_msa_sistema
        FOREIGN KEY (id_sist_armas) REFERENCES sistema_armas (id_sist_armas)
        ON DELETE CASCADE,
    CONSTRAINT FK_msa_catalogo
        FOREIGN KEY (NNE) REFERENCES catalogo_material (NNE)
        ON DELETE CASCADE
);
GO

/* ==================== Inventario ==================== */

CREATE TABLE inventario_fisico (
    id_item        INT IDENTITY(1,1) NOT NULL,
    NNE            NVARCHAR(20)  NOT NULL,      -- "instancia": catalogo (1) ── (N) inventario
    n_serie        NVARCHAR(100) NULL,
    vencimiento    DATE          NULL,
    observaciones  NVARCHAR(500) NULL,
    [tamaño]       NVARCHAR(50)  NULL,
    id_ubicacion   INT NULL,                    -- "almacena"; NULL = fuera del depósito
    CONSTRAINT PK_inventario_fisico PRIMARY KEY (id_item),
    CONSTRAINT FK_inventario_catalogo
        FOREIGN KEY (NNE) REFERENCES catalogo_material (NNE),
    CONSTRAINT FK_inventario_ubicacion
        FOREIGN KEY (id_ubicacion) REFERENCES ubicacion (id_ubicacion)
        ON DELETE SET NULL                       -- si se borra una ubicación, el elemento queda "sin ubicar"
);
GO

/* Tarjeta física atada al elemento. El estado del elemento es el estado de su
   tarjeta activa. Nº de parte y Nº de serie se DERIVAN del elemento/catálogo. */
CREATE TABLE tarjeta (
    id_tarjeta           INT IDENTITY(1,1) NOT NULL,
    id_item              INT NOT NULL,            -- elemento al que está atada
    id_estado            INT NOT NULL,            -- estado de la tarjeta (verde/blanca/baja)
    codigo_trazabilidad  NVARCHAR(50)  NULL,
    nro_tarjeta          NVARCHAR(30)  NULL,      -- Nº impreso en la tarjeta física
    ot                   NVARCHAR(30)  NULL,      -- orden de trabajo
    fecha_emision        DATE NOT NULL
        CONSTRAINT DF_tarjeta_fecha DEFAULT CAST(SYSDATETIME() AS DATE),
    causas               NVARCHAR(500) NULL,      -- causas de rechazo / remoción
    inspector            NVARCHAR(100) NULL,      -- firma y aclaración (persona física, texto)
    activa               BIT NOT NULL
        CONSTRAINT DF_tarjeta_activa DEFAULT 1,
    CONSTRAINT PK_tarjeta PRIMARY KEY (id_tarjeta),
    CONSTRAINT FK_tarjeta_item
        FOREIGN KEY (id_item) REFERENCES inventario_fisico (id_item)
        ON DELETE CASCADE,                        -- si se borra el elemento, se va su historial de tarjetas
    CONSTRAINT FK_tarjeta_estado
        FOREIGN KEY (id_estado) REFERENCES estado_elemento (id_estado)
);
GO

/* Una sola tarjeta activa por elemento; las demás quedan como historial.
   Esta es la garantía dura de integridad (no depende de la aplicación). */
CREATE UNIQUE INDEX UQ_tarjeta_activa_por_item
    ON tarjeta (id_item) WHERE activa = 1;
GO

CREATE TABLE movimiento_inventario (
    id_movimiento        INT IDENTITY(1,1) NOT NULL,
    id_item              INT NOT NULL,           -- "afecta": movimiento (N) ── (1) inventario
    id_ubicacion         INT NULL,               -- "registra"; NULL = movimiento con el elemento afuera (P4-A)
    fecha_registro       DATETIME2(0) NOT NULL
        CONSTRAINT DF_movimiento_fecha DEFAULT SYSDATETIME(),
    accion               NVARCHAR(50)  NOT NULL,
    id_usuario_registra  INT NULL,               -- "registra": usuario (1) ── (N) movimiento (P1-C)
    detalle              NVARCHAR(500) NULL,
    CONSTRAINT PK_movimiento_inventario PRIMARY KEY (id_movimiento),
    CONSTRAINT FK_movimiento_item
        FOREIGN KEY (id_item) REFERENCES inventario_fisico (id_item)
        ON DELETE CASCADE,
    CONSTRAINT FK_movimiento_ubicacion
        FOREIGN KEY (id_ubicacion) REFERENCES ubicacion (id_ubicacion)
        ON DELETE SET NULL,
    CONSTRAINT FK_movimiento_usuario
        FOREIGN KEY (id_usuario_registra) REFERENCES usuario (id_usuario)
        ON DELETE SET NULL
);
GO

/* Retiro del depósito: préstamo, reparación, inspección o baja.
   fecha_retorno NULL = el elemento sigue afuera (la baja nunca retorna). */
CREATE TABLE salida (
    id_salida               INT IDENTITY(1,1) NOT NULL,
    id_item                 INT NOT NULL,
    id_motivo               INT NOT NULL,
    destino                 NVARCHAR(255) NULL,   -- taller, unidad a la que se presta, etc.
    fecha_salida            DATETIME2(0) NOT NULL
        CONSTRAINT DF_salida_fecha DEFAULT SYSDATETIME(),
    fecha_prevista_retorno  DATE NULL,
    fecha_retorno           DATETIME2(0) NULL,
    retirado_por            NVARCHAR(100) NULL,   -- persona física (texto)
    observaciones           NVARCHAR(500) NULL,
    CONSTRAINT PK_salida PRIMARY KEY (id_salida),
    CONSTRAINT FK_salida_item
        FOREIGN KEY (id_item) REFERENCES inventario_fisico (id_item)
        ON DELETE CASCADE,
    CONSTRAINT FK_salida_motivo
        FOREIGN KEY (id_motivo) REFERENCES motivo_salida (id_motivo),
    -- P13-A: coherencia de fechas
    CONSTRAINT CK_salida_retorno_posterior
        CHECK (fecha_retorno IS NULL OR fecha_retorno >= fecha_salida),
    CONSTRAINT CK_salida_prevista_posterior
        CHECK (fecha_prevista_retorno IS NULL OR fecha_prevista_retorno >= CAST(fecha_salida AS DATE))
);
GO

/* Un elemento no puede tener dos salidas abiertas a la vez (garantía dura) */
CREATE UNIQUE INDEX UQ_salida_abierta_por_item
    ON salida (id_item) WHERE fecha_retorno IS NULL;
GO

/* ==================== Índices sobre FKs ==================== */

CREATE INDEX IX_catalogo_tipo        ON catalogo_material (id_tipo_elemento);
CREATE INDEX IX_catalogo_usuario     ON catalogo_material (id_usuario);
CREATE INDEX IX_msa_nne              ON material_sist_armas (NNE);
CREATE INDEX IX_inventario_nne       ON inventario_fisico (NNE);
CREATE INDEX IX_inventario_ubicacion ON inventario_fisico (id_ubicacion);
CREATE INDEX IX_tarjeta_item         ON tarjeta (id_item);
CREATE INDEX IX_tarjeta_estado       ON tarjeta (id_estado);
CREATE INDEX IX_movimiento_item      ON movimiento_inventario (id_item);
CREATE INDEX IX_movimiento_fecha     ON movimiento_inventario (fecha_registro);
CREATE INDEX IX_salida_item          ON salida (id_item);
CREATE INDEX IX_salida_motivo        ON salida (id_motivo);
GO

/* ==================== Datos semilla: catálogos fijos ====================
   estados basados en las tarjetas físicas del taller (I Brigada Aérea — G.T.1) */

INSERT INTO estado_elemento (codigo, descripcion) VALUES
    (N'EN_SERVICIO',             N'En servicio — operativo (tarjeta verde)'),
    (N'EN_SERVICIO_TRANSITORIO', N'En servicio transitorio — pendiente de envío a reparación (tarjeta blanca)'),
    (N'BAJA',                    N'Baja — elemento fuera de circulación');
GO

INSERT INTO motivo_salida (codigo, descripcion) VALUES
    (N'PRESTAMO',   N'Prestado — retorna al depósito al ser devuelto'),
    (N'REPARACION', N'Enviado a reparación — retorna al depósito'),
    (N'INSPECCION', N'Enviado a inspección/verificación — retorna al depósito'),
    (N'BAJA',       N'Baja definitiva — no retorna al depósito');
GO

PRINT '01 - Esquema creado correctamente.';
GO
