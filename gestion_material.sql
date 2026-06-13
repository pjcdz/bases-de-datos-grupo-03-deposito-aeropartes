/* ============================================================================
   Sistema de Gestión de Material — Microsoft SQL Server (T-SQL)
   Generado a partir del DER.

   Cambios respecto al diagrama lógico previo:
     - Se agrega la tabla USUARIO y la relación "consulta"
       (usuario 1 ── N catalogo_material → FK id_usuario en catalogo_material).
     - TRAZABILIDAD se renombra a MOVIMIENTO_INVENTARIO (como en el DER).
     - MOVIMIENTO_INVENTARIO incorpora id_ubicacion por la relación "registra"
       (ubicacion 1 ── N movimiento_inventario, según el DER).
     - Se agrega el atributo "tamaño" en inventario_fisico (presente en el DER).
     - ESTADO pasa a ser ESTADO_ELEMENTO, con datos semilla según las tarjetas
       físicas del taller: EN SERVICIO / EN SERVICIO TRANSITORIO / BAJA.
     - Nueva tabla TARJETA: la tarjeta física atada a cada elemento. Porta el
       estado, código de trazabilidad, Nº, OT, causas e inspector. Un elemento
       tiene UNA tarjeta activa a la vez; las anteriores quedan como historial.
       El estado deja de estar en inventario_fisico y pasa a la tarjeta.
       (Nº de parte y Nº de serie no se duplican en tarjeta: se derivan del
       elemento → id_item → n_serie y NNE → NREF del catálogo.)
     - Nuevas tablas SALIDA y MOTIVO_SALIDA: registran cada retiro del depósito
       (préstamo, reparación, inspección, baja) con fecha de salida y de retorno.
       id_ubicacion en inventario_fisico pasa a ser NULL = fuera del depósito;
       la salida abierta (fecha_retorno NULL) dice dónde y por qué está afuera.
   ============================================================================ */

-- Descomentar si se quiere crear la base de datos:
-- CREATE DATABASE gestion_material;
-- GO
-- USE gestion_material;
-- GO

/* ---------- Limpieza (orden inverso de dependencias) ---------- */
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
    CONSTRAINT UQ_estado_elemento_codigo UNIQUE (codigo)
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
    CONSTRAINT UQ_motivo_salida_codigo UNIQUE (codigo)
);
GO

/* ==================== Catálogo ==================== */

CREATE TABLE catalogo_material (
    NNE               NVARCHAR(20)  NOT NULL,   -- Número Nacional de Efecto (PK natural)
    NREF              NVARCHAR(50)  NULL,
    designacion       NVARCHAR(255) NOT NULL,
    ATA               NVARCHAR(10)  NULL,
    id_tipo_elemento  INT NOT NULL,             -- "tiene" / "clasifica"
    id_usuario        INT NULL,                 -- "consulta": usuario (1) ── (N) catalogo_material
    CONSTRAINT PK_catalogo_material PRIMARY KEY (NNE),
    CONSTRAINT FK_catalogo_tipo
        FOREIGN KEY (id_tipo_elemento) REFERENCES tipo_elemento (id_tipo),
    CONSTRAINT FK_catalogo_usuario
        FOREIGN KEY (id_usuario) REFERENCES usuario (id_usuario)
);
GO

/* "utiliza": sistema_armas (N) ── (N) catalogo_material → tabla intermedia */
CREATE TABLE material_sist_armas (
    id_sist_armas  INT          NOT NULL,
    NNE            NVARCHAR(20) NOT NULL,
    CONSTRAINT PK_material_sist_armas PRIMARY KEY (id_sist_armas, NNE),
    CONSTRAINT FK_msa_sistema
        FOREIGN KEY (id_sist_armas) REFERENCES sistema_armas (id_sist_armas),
    CONSTRAINT FK_msa_catalogo
        FOREIGN KEY (NNE) REFERENCES catalogo_material (NNE)
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
);
GO

/* Tarjeta física atada al elemento. El estado del elemento es el estado de su
   tarjeta activa. Nº de parte y Nº de serie se leen del elemento/catálogo. */
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
    inspector            NVARCHAR(100) NULL,      -- firma y aclaración
    activa               BIT NOT NULL
        CONSTRAINT DF_tarjeta_activa DEFAULT 1,
    CONSTRAINT PK_tarjeta PRIMARY KEY (id_tarjeta),
    CONSTRAINT FK_tarjeta_item
        FOREIGN KEY (id_item) REFERENCES inventario_fisico (id_item),
    CONSTRAINT FK_tarjeta_estado
        FOREIGN KEY (id_estado) REFERENCES estado_elemento (id_estado)
);
GO

/* Una sola tarjeta activa por elemento; las demás quedan como historial */
CREATE UNIQUE INDEX UQ_tarjeta_activa_por_item
    ON tarjeta (id_item) WHERE activa = 1;
GO

CREATE TABLE movimiento_inventario (
    id_movimiento   INT IDENTITY(1,1) NOT NULL,
    id_item         INT NOT NULL,               -- "afecta": movimiento (N) ── (1) inventario
    id_ubicacion    INT NOT NULL,               -- "registra": ubicacion (1) ── (N) movimiento
    fecha_registro  DATETIME2(0) NOT NULL
        CONSTRAINT DF_movimiento_fecha DEFAULT SYSDATETIME(),
    accion          NVARCHAR(50)  NOT NULL,
    usuario         NVARCHAR(100) NULL,         -- auditoría (del modelo lógico)
    detalle         NVARCHAR(500) NULL,
    CONSTRAINT PK_movimiento_inventario PRIMARY KEY (id_movimiento),
    CONSTRAINT FK_movimiento_item
        FOREIGN KEY (id_item) REFERENCES inventario_fisico (id_item),
    CONSTRAINT FK_movimiento_ubicacion
        FOREIGN KEY (id_ubicacion) REFERENCES ubicacion (id_ubicacion)
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
    retirado_por            NVARCHAR(100) NULL,
    observaciones           NVARCHAR(500) NULL,
    CONSTRAINT PK_salida PRIMARY KEY (id_salida),
    CONSTRAINT FK_salida_item
        FOREIGN KEY (id_item) REFERENCES inventario_fisico (id_item),
    CONSTRAINT FK_salida_motivo
        FOREIGN KEY (id_motivo) REFERENCES motivo_salida (id_motivo)
);
GO

/* Un elemento no puede tener dos salidas abiertas a la vez */
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

/* ==================== Datos semilla: estados del elemento ====================
   Basados en las tarjetas físicas del taller (I Brigada Aérea — Taller G.T.1) */

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
