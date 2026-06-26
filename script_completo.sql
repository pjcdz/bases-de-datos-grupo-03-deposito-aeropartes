-- trabajo practico integrador - sistema de gestion de material deposito de aeropartes
-- ingenieria de datos i uade - grupo 3
-- microsoft sql server. se ejecuta todo de arriba hacia abajo

-- parte 1 creacion de la base tablas, restricciones y datos de catalogo

-- descomentar si se quiere crear la base de datos
-- CREATE DATABASE GestionMaterial;
-- GO
-- USE GestionMaterial;
-- GO

-- limpieza orden inverso de dependencias
-- programabilidad por si se re-ejecuta el proyecto completo
DROP TRIGGER IF EXISTS trg_salida_abre_saca_del_deposito;
DROP TRIGGER IF EXISTS trg_estado_no_borrar;
GO
DROP VIEW IF EXISTS vw_stock_disponible;
DROP VIEW IF EXISTS vw_historial_tarjetas;
GO
DROP PROCEDURE IF EXISTS sp_AltaElemento;
DROP PROCEDURE IF EXISTS sp_Usuarios_Insert;
DROP PROCEDURE IF EXISTS sp_Usuarios_Read;
DROP PROCEDURE IF EXISTS sp_TiposElemento_Insert;
DROP PROCEDURE IF EXISTS sp_TiposElemento_Read;
DROP PROCEDURE IF EXISTS sp_SistemasArmas_Insert;
DROP PROCEDURE IF EXISTS sp_SistemasArmas_Read;
DROP PROCEDURE IF EXISTS sp_EstadosElemento_Insert;
DROP PROCEDURE IF EXISTS sp_EstadosElemento_Read;
DROP PROCEDURE IF EXISTS sp_Ubicaciones_Insert;
DROP PROCEDURE IF EXISTS sp_Ubicaciones_Read;
DROP PROCEDURE IF EXISTS sp_MotivosSalida_Insert;
DROP PROCEDURE IF EXISTS sp_MotivosSalida_Read;
DROP PROCEDURE IF EXISTS sp_CatalogoMateriales_Insert;
DROP PROCEDURE IF EXISTS sp_CatalogoMateriales_Read;
DROP PROCEDURE IF EXISTS sp_MaterialesSistemasArmas_Insert;
DROP PROCEDURE IF EXISTS sp_MaterialesSistemasArmas_Read;
DROP PROCEDURE IF EXISTS sp_InventarioFisico_Insert;
DROP PROCEDURE IF EXISTS sp_InventarioFisico_Read;
DROP PROCEDURE IF EXISTS sp_Tarjetas_Insert;
DROP PROCEDURE IF EXISTS sp_Tarjetas_Read;
DROP PROCEDURE IF EXISTS sp_MovimientosInventario_Insert;
DROP PROCEDURE IF EXISTS sp_MovimientosInventario_Read;
DROP PROCEDURE IF EXISTS sp_Salidas_Insert;
DROP PROCEDURE IF EXISTS sp_Salidas_Read;
GO
DROP FUNCTION IF EXISTS fn_EstadoActual;
GO
-- tablas
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

-- tablas maestras

-- 1. usuarios operarios del sistema cargan fichas, registran movimientos
CREATE TABLE Usuarios (
    IdUsuario       INT IDENTITY(1,1) PRIMARY KEY,
    NombreUsuario   VARCHAR(100) NOT NULL,
    ApellidoUsuario VARCHAR(100) NOT NULL,
    RolUsuario      VARCHAR(50)  NOT NULL
);
GO

-- 2. tiposelemento clasificacion del material rotable, herramienta, etc.
CREATE TABLE TiposElemento (
    IdTipoElemento     INT IDENTITY(1,1) PRIMARY KEY,
    NombreTipoElemento VARCHAR(100) NOT NULL,
    CONSTRAINT UQ_TiposElemento_Nombre UNIQUE (NombreTipoElemento) -- nombre de tipo unico
);
GO

-- 3. sistemasarmas aeronaves / sistemas a los que sirve el material
CREATE TABLE SistemasArmas (
    IdSistemaArmas     INT IDENTITY(1,1) PRIMARY KEY,
    CodigoSistemaArmas VARCHAR(50)   NOT NULL,  -- codigo -> varchar
    ModeloSistemaArmas VARCHAR(100) NOT NULL,
    CONSTRAINT UQ_SistemasArmas_Codigo UNIQUE (CodigoSistemaArmas)
);
GO

-- 4. estadoselemento catalogo de estados de la tarjeta semilla fija
CREATE TABLE EstadosElemento (
    IdEstadoElemento          INT IDENTITY(1,1) PRIMARY KEY,
    CodigoEstadoElemento      VARCHAR(30)   NOT NULL,
    DescripcionEstadoElemento VARCHAR(255) NULL,
    CONSTRAINT UQ_EstadosElemento_Codigo UNIQUE (CodigoEstadoElemento),
    CONSTRAINT CHK_EstadosElemento_Codigo CHECK (LEN(CodigoEstadoElemento) > 0) -- dominio no vacio
);
GO

-- 5. ubicaciones lugares fisicos de almacenamiento dentro del deposito
CREATE TABLE Ubicaciones (
    IdUbicacion            INT IDENTITY(1,1) PRIMARY KEY,
    DepositoUbicacion      VARCHAR(100) NOT NULL,
    SectorUbicacion        VARCHAR(100) NULL,
    MapaHighlightUbicacion VARCHAR(255) NULL
);
GO

-- 6. motivossalida catalogo de motivos de retiro del deposito semilla fija
CREATE TABLE MotivosSalida (
    IdMotivoSalida          INT IDENTITY(1,1) PRIMARY KEY,
    CodigoMotivoSalida      VARCHAR(30)   NOT NULL,
    DescripcionMotivoSalida VARCHAR(255) NULL,
    CONSTRAINT UQ_MotivosSalida_Codigo UNIQUE (CodigoMotivoSalida),
    CONSTRAINT CHK_MotivosSalida_Codigo CHECK (LEN(CodigoMotivoSalida) > 0)
);
GO

-- catalogo

-- 7. catalogomateriales ficha/modelo del material que es , pk natural nne
CREATE TABLE CatalogoMateriales (
    NNE                      VARCHAR(20)  NOT NULL PRIMARY KEY, -- numero nacional de efecto clave natural
    NumeroReferenciaMaterial VARCHAR(50)   NULL,                 -- nro de referencia / parte codigo
    DesignacionMaterial      VARCHAR(255) NOT NULL,
    ATAMaterial              VARCHAR(10)   NULL,                 -- capitulo ata codigo
    IdTipoElemento           INT NOT NULL,                       -- clasifica tiposelemento 1 - n catalogo
    IdUsuario                INT NULL,                           -- registra usuarios 1 - n catalogo
    CONSTRAINT FK_CatalogoMateriales_TiposElemento
        FOREIGN KEY (IdTipoElemento) REFERENCES TiposElemento (IdTipoElemento),
    CONSTRAINT FK_CatalogoMateriales_Usuarios
        FOREIGN KEY (IdUsuario) REFERENCES Usuarios (IdUsuario)
        ON DELETE SET NULL,                                      -- si se borra el usuario, la ficha queda sin cargado por
    CONSTRAINT CHK_CatalogoMateriales_ATA
        CHECK (ATAMaterial IS NULL
               OR (TRY_CAST(ATAMaterial AS INT) IS NOT NULL
                   AND TRY_CAST(ATAMaterial AS INT) BETWEEN 0 AND 99))
);
GO

-- 8. materialessistemasarmas relacion n n material-sistema compatibilidad
-- pk compuesta = relacion todo-clave, sin dependencias parciales 2fn
CREATE TABLE MaterialesSistemasArmas (
    IdSistemaArmas INT          NOT NULL,
    NNE            VARCHAR(20) NOT NULL,
    CONSTRAINT PK_MaterialesSistemasArmas PRIMARY KEY (IdSistemaArmas, NNE),
    CONSTRAINT FK_MaterialesSistemasArmas_SistemasArmas
        FOREIGN KEY (IdSistemaArmas) REFERENCES SistemasArmas (IdSistemaArmas)
        ON DELETE CASCADE,
    CONSTRAINT FK_MaterialesSistemasArmas_CatalogoMateriales
        FOREIGN KEY (NNE) REFERENCES CatalogoMateriales (NNE)
        ON DELETE CASCADE
);
GO

-- inventario

-- 9. inventariofisico cada ejemplar fisico real de un material del catalogo
CREATE TABLE InventarioFisico (
    IdItem               INT IDENTITY(1,1) PRIMARY KEY,
    NNE                  VARCHAR(20)  NOT NULL,   -- instancia catalogo 1 - n inventario
    NumeroSerieItem      VARCHAR(100)  NULL,       -- numero de serie codigo
    FechaVencimientoItem DATE          NULL,
    ObservacionesItem    VARCHAR(500) NULL,
    TamanoItem           VARCHAR(50)  NULL,
    IdUbicacion          INT           NULL,       -- almacena null = fuera del deposito
    CONSTRAINT FK_InventarioFisico_CatalogoMateriales
        FOREIGN KEY (NNE) REFERENCES CatalogoMateriales (NNE),
    CONSTRAINT FK_InventarioFisico_Ubicaciones
        FOREIGN KEY (IdUbicacion) REFERENCES Ubicaciones (IdUbicacion)
        ON DELETE SET NULL                          -- si se borra una ubicacion, el elemento queda sin ubicar
);
GO

-- 10. tarjetas tarjeta fisica atada al elemento. el estado del elemento es el
-- estado de su tarjeta activa. nro de parte/serie se derivan no se duplican
CREATE TABLE Tarjetas (
    IdTarjeta                 INT IDENTITY(1,1) PRIMARY KEY,
    IdItem                    INT NOT NULL,            -- elemento al que esta atada
    IdEstadoElemento          INT NOT NULL,            -- estado de la tarjeta verde/blanca/baja
    CodigoTrazabilidadTarjeta VARCHAR(50)   NULL,
    NumeroTarjeta             VARCHAR(30)   NULL,      -- nro impreso en la tarjeta fisica
    OrdenTrabajoTarjeta       VARCHAR(30)   NULL,      -- orden de trabajo
    FechaEmisionTarjeta       DATE NOT NULL DEFAULT CAST(SYSDATETIME() AS DATE),
    CausasTarjeta             VARCHAR(500) NULL,      -- causas de rechazo / remocion
    InspectorTarjeta          VARCHAR(100) NULL,      -- firma y aclaracion persona fisica, texto
    ActivaTarjeta             BIT NOT NULL DEFAULT 1,
    CONSTRAINT FK_Tarjetas_InventarioFisico
        FOREIGN KEY (IdItem) REFERENCES InventarioFisico (IdItem)
        ON DELETE CASCADE,                             -- si se borra el elemento, se va su historial de tarjetas
    CONSTRAINT FK_Tarjetas_EstadosElemento
        FOREIGN KEY (IdEstadoElemento) REFERENCES EstadosElemento (IdEstadoElemento)
);
GO

-- 11. movimientosinventario bitacora de trazabilidad de cada elemento
CREATE TABLE MovimientosInventario (
    IdMovimiento            INT IDENTITY(1,1) PRIMARY KEY,
    IdItem                  INT NOT NULL,           -- afecta movimiento n - 1 inventario
    IdUbicacion             INT NULL,               -- registra null = movimiento con el elemento afuera
    FechaRegistroMovimiento DATETIME2(0) NOT NULL DEFAULT SYSDATETIME(),
    AccionMovimiento        VARCHAR(50)  NOT NULL,
    IdUsuarioRegistra       INT NULL,               -- registra usuarios 1 - n movimiento
    DetalleMovimiento       VARCHAR(500) NULL,
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

-- 12. salidas retiro del deposito prestamo/reparacion/inspeccion/baja
-- fecharetornosalida null = el elemento sigue afuera la baja nunca retorna
CREATE TABLE Salidas (
    IdSalida                   INT IDENTITY(1,1) PRIMARY KEY,
    IdItem                     INT NOT NULL,
    IdMotivoSalida             INT NOT NULL,
    DestinoSalida              VARCHAR(255) NULL,   -- taller, unidad a la que se presta, etc
    FechaSalida                DATETIME2(0) NOT NULL DEFAULT SYSDATETIME(),
    FechaPrevistaRetornoSalida DATE NULL,
    FechaRetornoSalida         DATETIME2(0) NULL,
    RetiradoPorSalida          VARCHAR(100) NULL,   -- persona fisica texto
    ObservacionesSalida        VARCHAR(500) NULL,
    CONSTRAINT FK_Salidas_InventarioFisico
        FOREIGN KEY (IdItem) REFERENCES InventarioFisico (IdItem)
        ON DELETE CASCADE,
    CONSTRAINT FK_Salidas_MotivosSalida
        FOREIGN KEY (IdMotivoSalida) REFERENCES MotivosSalida (IdMotivoSalida),
    -- coherencia de fechas
    CONSTRAINT CHK_Salidas_RetornoPosterior
        CHECK (FechaRetornoSalida IS NULL OR FechaRetornoSalida >= FechaSalida),
    CONSTRAINT CHK_Salidas_PrevistaPosterior
        CHECK (FechaPrevistaRetornoSalida IS NULL OR FechaPrevistaRetornoSalida >= CAST(FechaSalida AS DATE))
);
GO

-- datos de catalogo estados de la tarjeta y motivos de salida

INSERT INTO EstadosElemento (CodigoEstadoElemento, DescripcionEstadoElemento) VALUES
    ('EN_SERVICIO',             'En servicio - operativo (tarjeta verde)'),
    ('EN_SERVICIO_TRANSITORIO', 'En servicio transitorio - pendiente de envio a reparacion (tarjeta blanca)'),
    ('BAJA',                    'Baja - elemento fuera de circulacion');
GO

INSERT INTO MotivosSalida (CodigoMotivoSalida, DescripcionMotivoSalida) VALUES
    ('PRESTAMO',   'Prestado - retorna al deposito al ser devuelto'),
    ('REPARACIO', 'Enviado a reparacion - retorna al deposito'),
    ('INSPECCIO', 'Enviado a inspeccion/verificacion - retorna al deposito'),
    ('BAJA',       'Baja definitiva - no retorna al deposito');
GO

-- parte 2 funciones, triggers y procedimiento

-- codigo del estado de la tarjeta activa del elemento null si no tiene tarjeta
CREATE FUNCTION fn_EstadoActual (@IdItem INT)
RETURNS VARCHAR(30)
AS
BEGIN
    DECLARE @cod VARCHAR(30);
    SELECT @cod = EstadosElemento.CodigoEstadoElemento
    FROM Tarjetas
    JOIN EstadosElemento ON EstadosElemento.IdEstadoElemento = Tarjetas.IdEstadoElemento
    WHERE Tarjetas.IdItem = @IdItem AND Tarjetas.ActivaTarjeta = 1;
    RETURN @cod;
END;
GO

-- triggers

-- after insert en salidas al abrir una salida sin fecha de retorno el elemento deja de estar en el deposito idubicacion = null . sincroniza esta afuera
CREATE TRIGGER trg_salida_abre_saca_del_deposito
ON Salidas
AFTER INSERT
AS
BEGIN
    UPDATE InventarioFisico
    SET InventarioFisico.IdUbicacion = NULL
    FROM InventarioFisico
    JOIN inserted ON inserted.IdItem = InventarioFisico.IdItem
    WHERE inserted.FechaRetornoSalida IS NULL;
END;
GO

-- instead of delete en estadoselemento los estados son catalogo de referencia. se permite borrar uno solo si ninguna tarjeta lo usa si esta en uso, se rechaza
CREATE TRIGGER trg_estado_no_borrar
ON EstadosElemento
INSTEAD OF DELETE
AS
BEGIN

    IF EXISTS (SELECT 1 FROM Tarjetas JOIN deleted ON deleted.IdEstadoElemento = Tarjetas.IdEstadoElemento)
    BEGIN
        THROW 50002, 'No se puede borrar un estado en uso por tarjetas existentes.', 1;
    END

    DELETE EstadosElemento
    FROM EstadosElemento
    JOIN deleted ON deleted.IdEstadoElemento = EstadosElemento.IdEstadoElemento;
END;
GO

-- procedimientos almacenados

-- alta de un ejemplar fisico + su primera tarjeta en_servicio transaccion
CREATE PROCEDURE sp_AltaElemento
    @NNE              VARCHAR(20),
    @NumeroSerie      VARCHAR(100)  = NULL,
    @IdUbicacion      INT           = NULL,
    @FechaVencimiento DATE          = NULL,
    @Tamano           VARCHAR(50)  = NULL,
    @Observaciones    VARCHAR(500) = NULL,
    @Inspector        VARCHAR(100) = NULL,
    @IdItem           INT OUTPUT
AS
BEGIN
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM CatalogoMateriales WHERE NNE = @NNE)
            THROW 50010, 'El NNE no existe en el catalogo.', 1;

        BEGIN TRANSACTION;
            INSERT INTO InventarioFisico (NNE, NumeroSerieItem, FechaVencimientoItem, ObservacionesItem, TamanoItem, IdUbicacion)
            VALUES (@NNE, @NumeroSerie, @FechaVencimiento, @Observaciones, @Tamano, @IdUbicacion);

            SET @IdItem = CAST(SCOPE_IDENTITY() AS INT);

            INSERT INTO Tarjetas (IdItem, IdEstadoElemento, InspectorTarjeta, ActivaTarjeta)
            SELECT @IdItem, IdEstadoElemento, @Inspector, 1
            FROM EstadosElemento WHERE CodigoEstadoElemento = 'EN_SERVICIO';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- parte 3 procedimientos crud (alta y consulta) por tabla

-- usuarios
CREATE PROCEDURE sp_Usuarios_Insert
    @NombreUsuario VARCHAR(100), @ApellidoUsuario VARCHAR(100), @RolUsuario VARCHAR(50),
    @IdUsuario INT OUTPUT
AS
BEGIN
    INSERT INTO Usuarios (NombreUsuario, ApellidoUsuario, RolUsuario)
    VALUES (@NombreUsuario, @ApellidoUsuario, @RolUsuario);
    SET @IdUsuario = CAST(SCOPE_IDENTITY() AS INT);
END;
GO
CREATE PROCEDURE sp_Usuarios_Read
    @IdUsuario INT = NULL
AS
BEGIN
    SELECT IdUsuario, NombreUsuario, ApellidoUsuario, RolUsuario
    FROM Usuarios
    WHERE (@IdUsuario IS NULL OR IdUsuario = @IdUsuario);
END;
GO

-- tiposelemento
CREATE PROCEDURE sp_TiposElemento_Insert
    @NombreTipoElemento VARCHAR(100), @IdTipoElemento INT OUTPUT
AS
BEGIN
    INSERT INTO TiposElemento (NombreTipoElemento) VALUES (@NombreTipoElemento);
    SET @IdTipoElemento = CAST(SCOPE_IDENTITY() AS INT);
END;
GO
CREATE PROCEDURE sp_TiposElemento_Read
    @IdTipoElemento INT = NULL
AS
BEGIN
    SELECT IdTipoElemento, NombreTipoElemento FROM TiposElemento
    WHERE (@IdTipoElemento IS NULL OR IdTipoElemento = @IdTipoElemento);
END;
GO

-- sistemasarmas
CREATE PROCEDURE sp_SistemasArmas_Insert
    @CodigoSistemaArmas VARCHAR(50), @ModeloSistemaArmas VARCHAR(100), @IdSistemaArmas INT OUTPUT
AS
BEGIN
    INSERT INTO SistemasArmas (CodigoSistemaArmas, ModeloSistemaArmas) VALUES (@CodigoSistemaArmas, @ModeloSistemaArmas);
    SET @IdSistemaArmas = CAST(SCOPE_IDENTITY() AS INT);
END;
GO
CREATE PROCEDURE sp_SistemasArmas_Read
    @IdSistemaArmas INT = NULL
AS
BEGIN
    SELECT IdSistemaArmas, CodigoSistemaArmas, ModeloSistemaArmas FROM SistemasArmas
    WHERE (@IdSistemaArmas IS NULL OR IdSistemaArmas = @IdSistemaArmas);
END;
GO

-- estadoselemento
CREATE PROCEDURE sp_EstadosElemento_Insert
    @CodigoEstadoElemento VARCHAR(30), @DescripcionEstadoElemento VARCHAR(255) = NULL, @IdEstadoElemento INT OUTPUT
AS
BEGIN
    INSERT INTO EstadosElemento (CodigoEstadoElemento, DescripcionEstadoElemento) VALUES (@CodigoEstadoElemento, @DescripcionEstadoElemento);
    SET @IdEstadoElemento = CAST(SCOPE_IDENTITY() AS INT);
END;
GO
CREATE PROCEDURE sp_EstadosElemento_Read
    @IdEstadoElemento INT = NULL
AS
BEGIN
    SELECT IdEstadoElemento, CodigoEstadoElemento, DescripcionEstadoElemento FROM EstadosElemento
    WHERE (@IdEstadoElemento IS NULL OR IdEstadoElemento = @IdEstadoElemento);
END;
GO

-- ubicaciones
CREATE PROCEDURE sp_Ubicaciones_Insert
    @DepositoUbicacion VARCHAR(100), @SectorUbicacion VARCHAR(100) = NULL,
    @MapaHighlightUbicacion VARCHAR(255) = NULL, @IdUbicacion INT OUTPUT
AS
BEGIN
    INSERT INTO Ubicaciones (DepositoUbicacion, SectorUbicacion, MapaHighlightUbicacion)
    VALUES (@DepositoUbicacion, @SectorUbicacion, @MapaHighlightUbicacion);
    SET @IdUbicacion = CAST(SCOPE_IDENTITY() AS INT);
END;
GO
CREATE PROCEDURE sp_Ubicaciones_Read
    @IdUbicacion INT = NULL
AS
BEGIN
    SELECT IdUbicacion, DepositoUbicacion, SectorUbicacion, MapaHighlightUbicacion FROM Ubicaciones
    WHERE (@IdUbicacion IS NULL OR IdUbicacion = @IdUbicacion);
END;
GO

-- motivossalida
CREATE PROCEDURE sp_MotivosSalida_Insert
    @CodigoMotivoSalida VARCHAR(30), @DescripcionMotivoSalida VARCHAR(255) = NULL, @IdMotivoSalida INT OUTPUT
AS
BEGIN
    INSERT INTO MotivosSalida (CodigoMotivoSalida, DescripcionMotivoSalida) VALUES (@CodigoMotivoSalida, @DescripcionMotivoSalida);
    SET @IdMotivoSalida = CAST(SCOPE_IDENTITY() AS INT);
END;
GO
CREATE PROCEDURE sp_MotivosSalida_Read
    @IdMotivoSalida INT = NULL
AS
BEGIN
    SELECT IdMotivoSalida, CodigoMotivoSalida, DescripcionMotivoSalida FROM MotivosSalida
    WHERE (@IdMotivoSalida IS NULL OR IdMotivoSalida = @IdMotivoSalida);
END;
GO

-- catalogomateriales pk natural nne
CREATE PROCEDURE sp_CatalogoMateriales_Insert
    @NNE VARCHAR(20), @DesignacionMaterial VARCHAR(255), @IdTipoElemento INT,
    @NumeroReferenciaMaterial VARCHAR(50) = NULL, @ATAMaterial VARCHAR(10) = NULL, @IdUsuario INT = NULL
AS
BEGIN
    BEGIN TRY
        INSERT INTO CatalogoMateriales (NNE, NumeroReferenciaMaterial, DesignacionMaterial, ATAMaterial, IdTipoElemento, IdUsuario)
        VALUES (@NNE, @NumeroReferenciaMaterial, @DesignacionMaterial, @ATAMaterial, @IdTipoElemento, @IdUsuario);
    END TRY
    BEGIN CATCH THROW; END CATCH
END;
GO
CREATE PROCEDURE sp_CatalogoMateriales_Read
    @NNE VARCHAR(20) = NULL
AS
BEGIN
    SELECT NNE, NumeroReferenciaMaterial, DesignacionMaterial, ATAMaterial, IdTipoElemento, IdUsuario
    FROM CatalogoMateriales
    WHERE (@NNE IS NULL OR NNE = @NNE);
END;
GO

-- materialessistemasarmas relacion todo-clave sin update
CREATE PROCEDURE sp_MaterialesSistemasArmas_Insert
    @IdSistemaArmas INT, @NNE VARCHAR(20)
AS
BEGIN
    BEGIN TRY
        INSERT INTO MaterialesSistemasArmas (IdSistemaArmas, NNE) VALUES (@IdSistemaArmas, @NNE);
    END TRY
    BEGIN CATCH THROW; END CATCH
END;
GO
CREATE PROCEDURE sp_MaterialesSistemasArmas_Read
    @IdSistemaArmas INT = NULL, @NNE VARCHAR(20) = NULL
AS
BEGIN
    SELECT IdSistemaArmas, NNE FROM MaterialesSistemasArmas
    WHERE (@IdSistemaArmas IS NULL OR IdSistemaArmas = @IdSistemaArmas)
      AND (@NNE IS NULL OR NNE = @NNE);
END;
GO

-- inventariofisico
CREATE PROCEDURE sp_InventarioFisico_Insert
    @NNE VARCHAR(20), @NumeroSerieItem VARCHAR(100) = NULL, @FechaVencimientoItem DATE = NULL,
    @ObservacionesItem VARCHAR(500) = NULL, @TamanoItem VARCHAR(50) = NULL,
    @IdUbicacion INT = NULL, @IdItem INT OUTPUT
AS
BEGIN
    BEGIN TRY
        INSERT INTO InventarioFisico (NNE, NumeroSerieItem, FechaVencimientoItem, ObservacionesItem, TamanoItem, IdUbicacion)
        VALUES (@NNE, @NumeroSerieItem, @FechaVencimientoItem, @ObservacionesItem, @TamanoItem, @IdUbicacion);
        SET @IdItem = CAST(SCOPE_IDENTITY() AS INT);
    END TRY
    BEGIN CATCH THROW; END CATCH
END;
GO
CREATE PROCEDURE sp_InventarioFisico_Read
    @IdItem INT = NULL
AS
BEGIN
    SELECT IdItem, NNE, NumeroSerieItem, FechaVencimientoItem, ObservacionesItem, TamanoItem, IdUbicacion
    FROM InventarioFisico
    WHERE (@IdItem IS NULL OR IdItem = @IdItem);
END;
GO

-- tarjetas
CREATE PROCEDURE sp_Tarjetas_Insert
    @IdItem INT, @IdEstadoElemento INT, @CodigoTrazabilidadTarjeta VARCHAR(50) = NULL,
    @NumeroTarjeta VARCHAR(30) = NULL, @OrdenTrabajoTarjeta VARCHAR(30) = NULL,
    @CausasTarjeta VARCHAR(500) = NULL, @InspectorTarjeta VARCHAR(100) = NULL,
    @ActivaTarjeta BIT = 1, @IdTarjeta INT OUTPUT
AS
BEGIN
    -- inserta una tarjeta para el ejemplar (la tarjeta activa define el estado del elemento)
    BEGIN TRY
        INSERT INTO Tarjetas (IdItem, IdEstadoElemento, CodigoTrazabilidadTarjeta, NumeroTarjeta, OrdenTrabajoTarjeta, CausasTarjeta, InspectorTarjeta, ActivaTarjeta)
        VALUES (@IdItem, @IdEstadoElemento, @CodigoTrazabilidadTarjeta, @NumeroTarjeta, @OrdenTrabajoTarjeta, @CausasTarjeta, @InspectorTarjeta, @ActivaTarjeta);
        SET @IdTarjeta = CAST(SCOPE_IDENTITY() AS INT);
    END TRY
    BEGIN CATCH THROW; END CATCH
END;
GO
CREATE PROCEDURE sp_Tarjetas_Read
    @IdTarjeta INT = NULL
AS
BEGIN
    SELECT IdTarjeta, IdItem, IdEstadoElemento, CodigoTrazabilidadTarjeta, NumeroTarjeta, OrdenTrabajoTarjeta,
           FechaEmisionTarjeta, CausasTarjeta, InspectorTarjeta, ActivaTarjeta
    FROM Tarjetas
    WHERE (@IdTarjeta IS NULL OR IdTarjeta = @IdTarjeta);
END;
GO

-- movimientosinventario
CREATE PROCEDURE sp_MovimientosInventario_Insert
    @IdItem INT, @AccionMovimiento VARCHAR(50), @IdUbicacion INT = NULL,
    @IdUsuarioRegistra INT = NULL, @DetalleMovimiento VARCHAR(500) = NULL,
    @IdMovimiento INT OUTPUT
AS
BEGIN
    BEGIN TRY
        INSERT INTO MovimientosInventario (IdItem, IdUbicacion, AccionMovimiento, IdUsuarioRegistra, DetalleMovimiento)
        VALUES (@IdItem, @IdUbicacion, @AccionMovimiento, @IdUsuarioRegistra, @DetalleMovimiento);
        SET @IdMovimiento = CAST(SCOPE_IDENTITY() AS INT);
    END TRY
    BEGIN CATCH THROW; END CATCH
END;
GO
CREATE PROCEDURE sp_MovimientosInventario_Read
    @IdMovimiento INT = NULL
AS
BEGIN
    SELECT IdMovimiento, IdItem, IdUbicacion, FechaRegistroMovimiento, AccionMovimiento, IdUsuarioRegistra, DetalleMovimiento
    FROM MovimientosInventario
    WHERE (@IdMovimiento IS NULL OR IdMovimiento = @IdMovimiento);
END;
GO

-- salidas
CREATE PROCEDURE sp_Salidas_Insert
    @IdItem INT, @IdMotivoSalida INT, @DestinoSalida VARCHAR(255) = NULL,
    @FechaPrevistaRetornoSalida DATE = NULL, @RetiradoPorSalida VARCHAR(100) = NULL,
    @ObservacionesSalida VARCHAR(500) = NULL, @IdSalida INT OUTPUT
AS
BEGIN
    -- al insertar la salida, el trigger trg_salida_abre saca el elemento del deposito si no tiene fecha de retorno
    BEGIN TRY
        INSERT INTO Salidas (IdItem, IdMotivoSalida, DestinoSalida, FechaPrevistaRetornoSalida, RetiradoPorSalida, ObservacionesSalida)
        VALUES (@IdItem, @IdMotivoSalida, @DestinoSalida, @FechaPrevistaRetornoSalida, @RetiradoPorSalida, @ObservacionesSalida);
        SET @IdSalida = CAST(SCOPE_IDENTITY() AS INT);
    END TRY
    BEGIN CATCH THROW; END CATCH
END;
GO
CREATE PROCEDURE sp_Salidas_Read
    @IdSalida INT = NULL
AS
BEGIN
    SELECT IdSalida, IdItem, IdMotivoSalida, DestinoSalida, FechaSalida,
           FechaPrevistaRetornoSalida, FechaRetornoSalida, RetiradoPorSalida, ObservacionesSalida
    FROM Salidas
    WHERE (@IdSalida IS NULL OR IdSalida = @IdSalida);
END;
GO

-- parte 4 vistas

-- stock realmente disponible en servicio y dentro del deposito
CREATE VIEW vw_stock_disponible AS
SELECT InventarioFisico.IdItem,
       CatalogoMateriales.NNE,
       CatalogoMateriales.DesignacionMaterial,
       InventarioFisico.NumeroSerieItem,
       InventarioFisico.TamanoItem,
       Ubicaciones.DepositoUbicacion,
       Ubicaciones.SectorUbicacion
FROM InventarioFisico
JOIN CatalogoMateriales ON CatalogoMateriales.NNE = InventarioFisico.NNE
JOIN Ubicaciones        ON Ubicaciones.IdUbicacion = InventarioFisico.IdUbicacion
WHERE dbo.fn_EstadoActual(InventarioFisico.IdItem) = 'EN_SERVICIO'
  AND InventarioFisico.IdUbicacion IS NOT NULL;
GO

-- historial completo de tarjetas por elemento la activa marcada con activatarjeta = 1
CREATE VIEW vw_historial_tarjetas AS
SELECT Tarjetas.IdItem,
       Tarjetas.IdTarjeta,
       EstadosElemento.CodigoEstadoElemento AS Estado,
       Tarjetas.FechaEmisionTarjeta,
       Tarjetas.OrdenTrabajoTarjeta,
       Tarjetas.CausasTarjeta,
       Tarjetas.InspectorTarjeta,
       Tarjetas.ActivaTarjeta
FROM Tarjetas
JOIN EstadosElemento ON EstadosElemento.IdEstadoElemento = Tarjetas.IdEstadoElemento;
GO

-- parte 5 carga de datos de ejemplo

-- usuarios 12
INSERT INTO Usuarios (NombreUsuario, ApellidoUsuario, RolUsuario) VALUES
    ('Pablo',   'Cardozo',   'Encargado de deposito'),
    ('Ana',     'Gomez',     'Cargador de datos'),
    ('Luis',    'Perez',     'Inspector'),
    ('Maria',   'Lopez',     'Jefe de taller'),
    ('Jorge',   'Diaz',      'Logistica'),
    ('Sofia',   'Ruiz',      'Inspector'),
    ('Diego',   'Fernandez', 'Almacenero'),
    ('Carla',   'Sosa',      'Administrativo'),
    ('Martin',  'Romero',    'Supervisor'),
    ('Lucia',   'Benitez',   'Cargador de datos'),
    ('Pedro',   'Alvarez',   'Mecanico'),
    ('Valeria', 'Castro',    'Control de calidad');
GO

-- tiposelemento 10
INSERT INTO TiposElemento (NombreTipoElemento) VALUES
    ('Componente rotable'), ('Herramienta'), ('Consumible'), ('Instrumento'),
    ('Componente estructural'), ('Componente electrico'), ('Componente hidraulico'),
    ('Componente neumatico'), ('Equipo de seguridad'), ('Software/firmware');
GO

-- sistemasarmas / aeronaves 10
INSERT INTO SistemasArmas (CodigoSistemaArmas, ModeloSistemaArmas) VALUES
    ('PUC-A', 'Pucara IA-58'),   ('HER-B', 'Hercules C-130'), ('PAM-T', 'Pampa IA-63'),
    ('TUC-C', 'Tucano EMB-312'), ('MIR-3', 'Mirage III'),     ('SKY-A', 'A-4 Skyhawk'),
    ('BEL-2', 'Bell 212'),       ('SAA-3', 'Saab 340'),       ('TWI-O', 'Twin Otter DHC-6'),
    ('LEA-3', 'Learjet 35');
GO

-- ubicaciones 10
INSERT INTO Ubicaciones (DepositoUbicacion, SectorUbicacion, MapaHighlightUbicacion) VALUES
    ('Deposito Central',     'Estanteria A', 'A-01'),
    ('Deposito Central',     'Estanteria B', 'B-04'),
    ('Panol Herramientas',   'Sector 1',     'PH-1'),
    ('Deposito Central',     'Estanteria C', 'C-02'),
    ('Deposito Central',     'Estanteria D', 'D-03'),
    ('Camara de Frio',       'Sector 1',     'CF-1'),
    ('Sala de Instrumentos', 'Vitrina 1',    'SI-1'),
    ('Zona de Cuarentena',   'Sector Q',     'QZ-1'),
    ('Panol Herramientas',   'Sector 2',     'PH-2'),
    ('Deposito Auxiliar',    'Estanteria E', 'E-05');
GO

-- catalogomateriales 12 (el ATA es un codigo numerico, lo valida el CHECK)
INSERT INTO CatalogoMateriales (NNE, NumeroReferenciaMaterial, DesignacionMaterial, ATAMaterial, IdTipoElemento, IdUsuario) VALUES
    ('1560-AR-001', 'PN-7788', 'Bomba hidraulica',       '29', 7, 1),
    ('2620-AR-014', 'PN-1042', 'Valvula de combustible', '28', 1, 1),
    ('5120-AR-220', 'TL-3360', 'Llave dinamometrica',    '00', 2, 2),
    ('6610-AR-007', 'IN-9001', 'Altimetro',              '34', 4, 1),
    ('2915-AR-033', 'PN-5521', 'Actuador de tren',       '32', 7, 2),
    ('4710-AR-099', 'PN-3030', 'Manguera de oxigeno',    '35', 3, 2),
    ('2440-AR-051', 'PN-8820', 'Bomba de combustible',   '28', 1, 4),
    ('2810-AR-066', 'IN-4410', 'Indicador de presion',   '31', 4, 3),
    ('5340-AR-077', 'HW-2200', 'Juego de bulones',       '51', 3, 5),
    ('2440-AR-088', 'EL-9300', 'Arnes electrico',        '24', 6, 4),
    ('3210-AR-112', 'PN-1500', 'Conjunto de rueda',      '32', 5, 9),
    ('1680-AR-130', 'PN-7001', 'Servovalvula',           '27', 7, 9);
GO

-- compatibilidad material - sistema de armas (n a n) 13
INSERT INTO MaterialesSistemasArmas (IdSistemaArmas, NNE) VALUES
    (1, '1560-AR-001'), (1, '2915-AR-033'), (1, '3210-AR-112'),
    (2, '1560-AR-001'), (2, '6610-AR-007'),
    (3, '2620-AR-014'), (3, '2810-AR-066'),
    (4, '2440-AR-051'), (5, '2440-AR-051'),
    (6, '2440-AR-088'), (7, '3210-AR-112'),
    (8, '1680-AR-130'), (9, '5340-AR-077');
GO

-- ejemplares fisicos 15 (insert directo, el IdItem se autonumera del 1 al 15)
INSERT INTO InventarioFisico (NNE, NumeroSerieItem, FechaVencimientoItem, TamanoItem, IdUbicacion) VALUES
    ('1560-AR-001', 'SN-BH-001', '2027-03-01', NULL,           1),
    ('1560-AR-001', 'SN-BH-002', '2024-01-15', NULL,           1),
    ('2620-AR-014', 'SN-VC-010', NULL,         NULL,           2),
    ('5120-AR-220', 'SN-LL-100', NULL,         '1/2 pulgada', 3),
    ('6610-AR-007', 'SN-AL-050', '2026-12-31', NULL,           7),
    ('2915-AR-033', 'SN-AC-077', NULL,         NULL,           1),
    ('2440-AR-051', 'SN-BC-201', '2028-05-01', NULL,           2),
    ('2810-AR-066', 'SN-IP-300', NULL,         NULL,           7),
    ('5340-AR-077', 'SN-JB-400', NULL,         NULL,           3),
    ('2440-AR-088', 'SN-AE-500', '2023-09-10', NULL,           5),
    ('3210-AR-112', 'SN-RU-600', NULL,         NULL,           4),
    ('1680-AR-130', 'SN-SV-700', '2027-11-20', NULL,           1),
    ('1560-AR-001', 'SN-BH-003', NULL,         NULL,           4),
    ('2620-AR-014', 'SN-VC-011', '2025-02-01', NULL,           2),
    ('5340-AR-077', 'SN-JB-401', NULL,         NULL,           9);
GO

-- tarjetas: una activa por ejemplar (estado 1=en servicio, 2=transitorio, 3=baja)
INSERT INTO Tarjetas (IdItem, IdEstadoElemento, InspectorTarjeta, ActivaTarjeta) VALUES
    (1,  1, 'Luis Perez',      1),
    (2,  1, 'Luis Perez',      1),
    (3,  1, 'Sofia Ruiz',      1),
    (4,  1, 'Pedro Alvarez',   1),
    (5,  1, 'Luis Perez',      0),
    (6,  1, 'Pablo Cardozo',   0),
    (7,  1, 'Sofia Ruiz',      1),
    (8,  1, 'Diego Fernandez', 1),
    (9,  1, 'Pedro Alvarez',   1),
    (10, 1, 'Diego Fernandez', 0),
    (11, 1, 'Sofia Ruiz',      1),
    (12, 1, 'Luis Perez',      1),
    (13, 1, 'Sofia Ruiz',      1),
    (14, 1, 'Luis Perez',      0),
    (15, 1, 'Valeria Castro',  1);
GO

-- segundas tarjetas: cambios de estado (asi quedan ejemplares con historial)
INSERT INTO Tarjetas (IdItem, IdEstadoElemento, OrdenTrabajoTarjeta, CausasTarjeta, InspectorTarjeta, ActivaTarjeta) VALUES
    (5,  2, 'OT-2026-441', 'Lectura erratica en banco',    'Luis Perez',      1),
    (14, 2, 'OT-2026-502', 'Perdida en prueba de presion', 'Sofia Ruiz',      1),
    (6,  3, NULL,          'Dano irreparable',             'Pablo Cardozo',   1),
    (10, 3, NULL,          'Vencido y deteriorado',        'Diego Fernandez', 1);
GO

-- salidas: motivo 1=prestamo 2=reparacion 3=inspeccion 4=baja
-- las que no tienen fecha de retorno quedan afuera (el trigger les pone ubicacion null)
INSERT INTO Salidas (IdItem, IdMotivoSalida, DestinoSalida, RetiradoPorSalida, FechaSalida, FechaPrevistaRetornoSalida, FechaRetornoSalida) VALUES
    (3,  1, 'Escuadron Tecnico',  'Sgto. Diaz',      '2026-06-01', '2026-09-30', NULL),
    (8,  1, 'Escuadron II',       'Cabo Nunez',      '2026-06-05', '2026-10-10', NULL),
    (11, 3, 'Control de Calidad', 'Sofia Ruiz',      '2026-06-03', '2026-09-05', NULL),
    (13, 1, 'Escuadron III',      'Cabo Ruiz',       '2026-06-10', '2026-11-01', NULL),
    (4,  2, 'Taller Hidraulica',  'Pedro Alvarez',   '2026-05-01', '2026-07-15', '2026-05-20'),
    (7,  3, 'Laboratorio',        'Sofia Ruiz',      '2026-05-02', '2026-08-01', '2026-05-25'),
    (9,  2, 'Taller Mecanico',    'Pedro Alvarez',   '2026-05-03', '2026-07-20', '2026-05-28'),
    (15, 3, 'Control de Calidad', 'Valeria Castro',  '2026-05-04', '2026-08-15', '2026-05-30'),
    (6,  4, 'Rezago',             'Pablo Cardozo',   '2026-04-10', NULL,         NULL),
    (10, 4, 'Rezago',             'Diego Fernandez', '2026-04-12', NULL,         NULL),
    (1,  1, 'Banco de pruebas',   'Cabo Ruiz',       '2025-09-01', '2025-09-20', '2025-09-18'),
    (12, 2, 'Taller externo',     'Pedro Alvarez',   '2025-10-01', '2025-10-30', '2025-10-28');
GO

-- movimientos de inventario (recuentos, reubicaciones, controles)
INSERT INTO MovimientosInventario (IdItem, IdUbicacion, AccionMovimiento, IdUsuarioRegistra, DetalleMovimiento) VALUES
    (1,  1, 'ALTA',        1,  'Ingreso inicial al deposito'),
    (2,  1, 'RECUENTO',    2,  'Recuento mensual'),
    (5,  7, 'REUBICACIO', 5,  'Movido a Sala de Instrumentos'),
    (7,  2, 'CONTROL',     12, 'Control de calidad OK'),
    (9,  3, 'RECUENTO',    7,  'Recuento trimestral'),
    (11, 4, 'ALTA',        1,  'Ingreso inicial al deposito'),
    (12, 1, 'CONTROL',     3,  'Verificacion de servovalvula'),
    (13, 4, 'RECUENTO',    10, 'Recuento mensual'),
    (14, 2, 'REUBICACIO', 9,  'Reubicado a Estanteria B'),
    (15, 9, 'ALTA',        1,  'Ingreso inicial al deposito');
GO

-- ejemplo de uso del procedimiento sp_AltaElemento (da de alta un ejemplar y su tarjeta)
DECLARE @nuevo INT;
EXEC sp_AltaElemento @NNE = '6610-AR-007', @NumeroSerie = 'SN-AL-051', @IdUbicacion = 7, @FechaVencimiento = '2028-01-01', @Inspector = 'Sofia Ruiz', @IdItem = @nuevo OUTPUT;
GO

-- parte 6 consultas de demostracion y pruebas

-- 1 group by + having
-- cantidad de ejemplares por estado actual, solo estados con mas de 1 elemento
SELECT dbo.fn_EstadoActual(InventarioFisico.IdItem) AS Estado, COUNT(*) AS Cantidad
FROM InventarioFisico
GROUP BY dbo.fn_EstadoActual(InventarioFisico.IdItem)
HAVING COUNT(*) > 1
ORDER BY Cantidad DESC;
GO

-- 2 not exists
-- elementos que nunca salieron del deposito
SELECT InventarioFisico.IdItem, CatalogoMateriales.DesignacionMaterial, InventarioFisico.NumeroSerieItem
FROM InventarioFisico
JOIN CatalogoMateriales ON CatalogoMateriales.NNE = InventarioFisico.NNE
WHERE NOT EXISTS (SELECT 1 FROM Salidas WHERE Salidas.IdItem = InventarioFisico.IdItem);
GO

-- 3 exists
-- ubicaciones que tienen al menos un elemento guardado
SELECT Ubicaciones.IdUbicacion, Ubicaciones.DepositoUbicacion, Ubicaciones.SectorUbicacion
FROM Ubicaciones
WHERE EXISTS (SELECT 1 FROM InventarioFisico WHERE InventarioFisico.IdUbicacion = Ubicaciones.IdUbicacion);
GO

-- 4 union
-- lista unica de personas que aparecen en el sistema, de tres lados
SELECT CONCAT(NombreUsuario, ' ', ApellidoUsuario) AS Persona, 'Usuario del sistema' AS Origen
FROM Usuarios
UNION
SELECT DISTINCT InspectorTarjeta, 'Inspector (tarjeta)'
FROM Tarjetas WHERE InspectorTarjeta IS NOT NULL
UNION
SELECT DISTINCT RetiradoPorSalida, 'Retiro material (salida)'
FROM Salidas WHERE RetiradoPorSalida IS NOT NULL
ORDER BY Persona;
GO

-- 5 intersect
-- nne que estan en inventario y tambien asociados a un sistema de armas
SELECT NNE FROM InventarioFisico
INTERSECT
SELECT NNE FROM MaterialesSistemasArmas;
GO

-- 6 except
-- nne del catalogo que no tienen ningun ejemplar en inventario
SELECT NNE FROM CatalogoMateriales
EXCEPT
SELECT NNE FROM InventarioFisico;
GO

-- 7 subconsulta correlacionada
-- por cada elemento, cuantas tarjetas tuvo (su historial)
SELECT InventarioFisico.IdItem, CatalogoMateriales.DesignacionMaterial,
       (SELECT COUNT(*) FROM Tarjetas WHERE Tarjetas.IdItem = InventarioFisico.IdItem) AS TarjetasHistoricas
FROM InventarioFisico
JOIN CatalogoMateriales ON CatalogoMateriales.NNE = InventarioFisico.NNE
ORDER BY TarjetasHistoricas DESC;
GO

-- 8 case + funcion de fecha
-- clasifico el vencimiento de cada elemento
SELECT InventarioFisico.IdItem, CatalogoMateriales.DesignacionMaterial, InventarioFisico.FechaVencimientoItem,
       CASE
           WHEN InventarioFisico.FechaVencimientoItem IS NULL                       THEN 'sin vencimiento'
           WHEN InventarioFisico.FechaVencimientoItem < CAST(SYSDATETIME() AS DATE) THEN 'vencido'
           WHEN DATEDIFF(DAY, CAST(SYSDATETIME() AS DATE), InventarioFisico.FechaVencimientoItem) <= 180 THEN 'por vencer'
           ELSE 'vigente'
       END AS Situacion
FROM InventarioFisico
JOIN CatalogoMateriales ON CatalogoMateriales.NNE = InventarioFisico.NNE
ORDER BY InventarioFisico.FechaVencimientoItem;
GO

-- 9 consultas sobre las dos vistas
SELECT * FROM vw_stock_disponible ORDER BY DesignacionMaterial;
SELECT * FROM vw_historial_tarjetas
WHERE IdItem IN (SELECT IdItem FROM Tarjetas GROUP BY IdItem HAVING COUNT(*) > 1)
ORDER BY IdItem, FechaEmisionTarjeta;
GO

-- 10 join: cada ejemplar con su material y su ubicacion (left join porque los que estan afuera no tienen ubicacion)
SELECT InventarioFisico.IdItem, CatalogoMateriales.DesignacionMaterial, InventarioFisico.NumeroSerieItem,
       Ubicaciones.DepositoUbicacion, Ubicaciones.SectorUbicacion
FROM InventarioFisico
JOIN CatalogoMateriales ON CatalogoMateriales.NNE = InventarioFisico.NNE
LEFT JOIN Ubicaciones   ON Ubicaciones.IdUbicacion = InventarioFisico.IdUbicacion
ORDER BY InventarioFisico.IdItem;
GO

-- 11 cantidad de materiales del catalogo por tipo
SELECT TiposElemento.NombreTipoElemento, COUNT(*) AS CantidadMateriales
FROM CatalogoMateriales
JOIN TiposElemento ON TiposElemento.IdTipoElemento = CatalogoMateriales.IdTipoElemento
GROUP BY TiposElemento.NombreTipoElemento
ORDER BY CantidadMateriales DESC;
GO

-- pruebas: cosas que la base NO deja hacer. las dejo comentadas porque fallan a proposito.
-- si las descomento y ejecuto una por una, cada una tira el error que anote al lado.

-- meter texto en una columna numerica -> ERROR: no puede convertir 'DIEZ' a int
-- INSERT INTO MaterialesSistemasArmas (IdSistemaArmas, NNE) VALUES ('DIEZ', '1560-AR-001');

-- ata fuera del rango 0-99 -> ERROR: choca con el CHECK CHK_CatalogoMateriales_ATA
-- INSERT INTO CatalogoMateriales (NNE, DesignacionMaterial, ATAMaterial, IdTipoElemento) VALUES ('TEST-1', 'prueba', '150', 1);

-- ata con letras en vez de numero -> ERROR: el mismo CHECK lo rechaza
-- INSERT INTO CatalogoMateriales (NNE, DesignacionMaterial, ATAMaterial, IdTipoElemento) VALUES ('TEST-2', 'prueba', 'ABC', 1);

-- fecha de retorno anterior a la de salida -> ERROR: choca con el CHECK CHK_Salidas_RetornoPosterior
-- INSERT INTO Salidas (IdItem, IdMotivoSalida, FechaSalida, FechaRetornoSalida) VALUES (1, 1, '2024-01-10', '2024-01-05');

-- borrar un estado que esta en uso -> ERROR: lo bloquea el trigger trg_estado_no_borrar
-- DELETE FROM EstadosElemento WHERE CodigoEstadoElemento = 'EN_SERVICIO';

