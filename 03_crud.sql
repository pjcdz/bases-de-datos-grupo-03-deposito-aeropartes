/* ============================================================================
   ARCHIVO 03 de 06 - PROCEDIMIENTOS CRUD POR TABLA
   Requiere haber ejecutado 01 (gestion_material.sql).

   Rubrica 17.b: "al menos dos procedimientos almacenados de CRUD para cada tabla".
   Se implementa el CRUD completo (Insert / Read / Update / Delete) para cada una
   de las 12 tablas. Convencion: sp_<Tabla>_<Operacion>.
   - Read con parametro NULL devuelve todas las filas; con valor, la fila puntual.
   - Insert de PK IDENTITY devuelve el id por parametro OUTPUT.
   - Update/Delete validan existencia y propagan errores con TRY/CATCH + THROW.
   MaterialesSistemasArmas es relacion todo-clave: lleva Insert/Read/Delete (sin Update).
   ============================================================================ */

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* ==================== Usuarios ==================== */
CREATE OR ALTER PROCEDURE sp_Usuarios_Insert
    @NombreUsuario NVARCHAR(100), @ApellidoUsuario NVARCHAR(100), @RolUsuario NVARCHAR(50),
    @IdUsuario INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO Usuarios (NombreUsuario, ApellidoUsuario, RolUsuario)
    VALUES (@NombreUsuario, @ApellidoUsuario, @RolUsuario);
    SET @IdUsuario = CAST(SCOPE_IDENTITY() AS INT);
END;
GO
CREATE OR ALTER PROCEDURE sp_Usuarios_Read
    @IdUsuario INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT IdUsuario, NombreUsuario, ApellidoUsuario, RolUsuario
    FROM Usuarios
    WHERE (@IdUsuario IS NULL OR IdUsuario = @IdUsuario);
END;
GO
CREATE OR ALTER PROCEDURE sp_Usuarios_Update
    @IdUsuario INT, @NombreUsuario NVARCHAR(100), @ApellidoUsuario NVARCHAR(100), @RolUsuario NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM Usuarios WHERE IdUsuario = @IdUsuario)
            THROW 51000, 'Usuario inexistente.', 1;
        UPDATE Usuarios SET NombreUsuario = @NombreUsuario, ApellidoUsuario = @ApellidoUsuario, RolUsuario = @RolUsuario
        WHERE IdUsuario = @IdUsuario;
    END TRY
    BEGIN CATCH THROW; END CATCH
END;
GO
CREATE OR ALTER PROCEDURE sp_Usuarios_Delete
    @IdUsuario INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM Usuarios WHERE IdUsuario = @IdUsuario)
            THROW 51001, 'Usuario inexistente.', 1;
        DELETE FROM Usuarios WHERE IdUsuario = @IdUsuario;
    END TRY
    BEGIN CATCH THROW; END CATCH
END;
GO

/* ==================== TiposElemento ==================== */
CREATE OR ALTER PROCEDURE sp_TiposElemento_Insert
    @NombreTipoElemento NVARCHAR(100), @IdTipoElemento INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO TiposElemento (NombreTipoElemento) VALUES (@NombreTipoElemento);
    SET @IdTipoElemento = CAST(SCOPE_IDENTITY() AS INT);
END;
GO
CREATE OR ALTER PROCEDURE sp_TiposElemento_Read
    @IdTipoElemento INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT IdTipoElemento, NombreTipoElemento FROM TiposElemento
    WHERE (@IdTipoElemento IS NULL OR IdTipoElemento = @IdTipoElemento);
END;
GO
CREATE OR ALTER PROCEDURE sp_TiposElemento_Update
    @IdTipoElemento INT, @NombreTipoElemento NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM TiposElemento WHERE IdTipoElemento = @IdTipoElemento)
            THROW 51010, 'TipoElemento inexistente.', 1;
        UPDATE TiposElemento SET NombreTipoElemento = @NombreTipoElemento WHERE IdTipoElemento = @IdTipoElemento;
    END TRY
    BEGIN CATCH THROW; END CATCH
END;
GO
CREATE OR ALTER PROCEDURE sp_TiposElemento_Delete
    @IdTipoElemento INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM TiposElemento WHERE IdTipoElemento = @IdTipoElemento)
            THROW 51011, 'TipoElemento inexistente.', 1;
        DELETE FROM TiposElemento WHERE IdTipoElemento = @IdTipoElemento;
    END TRY
    BEGIN CATCH THROW; END CATCH
END;
GO

/* ==================== SistemasArmas ==================== */
CREATE OR ALTER PROCEDURE sp_SistemasArmas_Insert
    @CodigoSistemaArmas VARCHAR(50), @ModeloSistemaArmas NVARCHAR(100), @IdSistemaArmas INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO SistemasArmas (CodigoSistemaArmas, ModeloSistemaArmas) VALUES (@CodigoSistemaArmas, @ModeloSistemaArmas);
    SET @IdSistemaArmas = CAST(SCOPE_IDENTITY() AS INT);
END;
GO
CREATE OR ALTER PROCEDURE sp_SistemasArmas_Read
    @IdSistemaArmas INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT IdSistemaArmas, CodigoSistemaArmas, ModeloSistemaArmas FROM SistemasArmas
    WHERE (@IdSistemaArmas IS NULL OR IdSistemaArmas = @IdSistemaArmas);
END;
GO
CREATE OR ALTER PROCEDURE sp_SistemasArmas_Update
    @IdSistemaArmas INT, @CodigoSistemaArmas VARCHAR(50), @ModeloSistemaArmas NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM SistemasArmas WHERE IdSistemaArmas = @IdSistemaArmas)
            THROW 51020, 'SistemaArmas inexistente.', 1;
        UPDATE SistemasArmas SET CodigoSistemaArmas = @CodigoSistemaArmas, ModeloSistemaArmas = @ModeloSistemaArmas
        WHERE IdSistemaArmas = @IdSistemaArmas;
    END TRY
    BEGIN CATCH THROW; END CATCH
END;
GO
CREATE OR ALTER PROCEDURE sp_SistemasArmas_Delete
    @IdSistemaArmas INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM SistemasArmas WHERE IdSistemaArmas = @IdSistemaArmas)
            THROW 51021, 'SistemaArmas inexistente.', 1;
        DELETE FROM SistemasArmas WHERE IdSistemaArmas = @IdSistemaArmas;
    END TRY
    BEGIN CATCH THROW; END CATCH
END;
GO

/* ==================== EstadosElemento ==================== */
CREATE OR ALTER PROCEDURE sp_EstadosElemento_Insert
    @CodigoEstadoElemento VARCHAR(30), @DescripcionEstadoElemento NVARCHAR(255) = NULL, @IdEstadoElemento INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO EstadosElemento (CodigoEstadoElemento, DescripcionEstadoElemento) VALUES (@CodigoEstadoElemento, @DescripcionEstadoElemento);
    SET @IdEstadoElemento = CAST(SCOPE_IDENTITY() AS INT);
END;
GO
CREATE OR ALTER PROCEDURE sp_EstadosElemento_Read
    @IdEstadoElemento INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT IdEstadoElemento, CodigoEstadoElemento, DescripcionEstadoElemento FROM EstadosElemento
    WHERE (@IdEstadoElemento IS NULL OR IdEstadoElemento = @IdEstadoElemento);
END;
GO
CREATE OR ALTER PROCEDURE sp_EstadosElemento_Update
    @IdEstadoElemento INT, @CodigoEstadoElemento VARCHAR(30), @DescripcionEstadoElemento NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM EstadosElemento WHERE IdEstadoElemento = @IdEstadoElemento)
            THROW 51030, 'EstadoElemento inexistente.', 1;
        UPDATE EstadosElemento SET CodigoEstadoElemento = @CodigoEstadoElemento, DescripcionEstadoElemento = @DescripcionEstadoElemento
        WHERE IdEstadoElemento = @IdEstadoElemento;
    END TRY
    BEGIN CATCH THROW; END CATCH
END;
GO
CREATE OR ALTER PROCEDURE sp_EstadosElemento_Delete
    @IdEstadoElemento INT
AS
BEGIN
    SET NOCOUNT ON;
    -- el trigger INSTEAD OF trg_estado_no_borrar impide borrar estados en uso
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM EstadosElemento WHERE IdEstadoElemento = @IdEstadoElemento)
            THROW 51031, 'EstadoElemento inexistente.', 1;
        DELETE FROM EstadosElemento WHERE IdEstadoElemento = @IdEstadoElemento;
    END TRY
    BEGIN CATCH THROW; END CATCH
END;
GO

/* ==================== Ubicaciones ==================== */
CREATE OR ALTER PROCEDURE sp_Ubicaciones_Insert
    @DepositoUbicacion NVARCHAR(100), @SectorUbicacion NVARCHAR(100) = NULL,
    @MapaHighlightUbicacion NVARCHAR(255) = NULL, @IdUbicacion INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO Ubicaciones (DepositoUbicacion, SectorUbicacion, MapaHighlightUbicacion)
    VALUES (@DepositoUbicacion, @SectorUbicacion, @MapaHighlightUbicacion);
    SET @IdUbicacion = CAST(SCOPE_IDENTITY() AS INT);
END;
GO
CREATE OR ALTER PROCEDURE sp_Ubicaciones_Read
    @IdUbicacion INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT IdUbicacion, DepositoUbicacion, SectorUbicacion, MapaHighlightUbicacion FROM Ubicaciones
    WHERE (@IdUbicacion IS NULL OR IdUbicacion = @IdUbicacion);
END;
GO
CREATE OR ALTER PROCEDURE sp_Ubicaciones_Update
    @IdUbicacion INT, @DepositoUbicacion NVARCHAR(100),
    @SectorUbicacion NVARCHAR(100) = NULL, @MapaHighlightUbicacion NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM Ubicaciones WHERE IdUbicacion = @IdUbicacion)
            THROW 51040, 'Ubicacion inexistente.', 1;
        UPDATE Ubicaciones SET DepositoUbicacion = @DepositoUbicacion, SectorUbicacion = @SectorUbicacion, MapaHighlightUbicacion = @MapaHighlightUbicacion
        WHERE IdUbicacion = @IdUbicacion;
    END TRY
    BEGIN CATCH THROW; END CATCH
END;
GO
CREATE OR ALTER PROCEDURE sp_Ubicaciones_Delete
    @IdUbicacion INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM Ubicaciones WHERE IdUbicacion = @IdUbicacion)
            THROW 51041, 'Ubicacion inexistente.', 1;
        DELETE FROM Ubicaciones WHERE IdUbicacion = @IdUbicacion;
    END TRY
    BEGIN CATCH THROW; END CATCH
END;
GO

/* ==================== MotivosSalida ==================== */
CREATE OR ALTER PROCEDURE sp_MotivosSalida_Insert
    @CodigoMotivoSalida VARCHAR(30), @DescripcionMotivoSalida NVARCHAR(255) = NULL, @IdMotivoSalida INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO MotivosSalida (CodigoMotivoSalida, DescripcionMotivoSalida) VALUES (@CodigoMotivoSalida, @DescripcionMotivoSalida);
    SET @IdMotivoSalida = CAST(SCOPE_IDENTITY() AS INT);
END;
GO
CREATE OR ALTER PROCEDURE sp_MotivosSalida_Read
    @IdMotivoSalida INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT IdMotivoSalida, CodigoMotivoSalida, DescripcionMotivoSalida FROM MotivosSalida
    WHERE (@IdMotivoSalida IS NULL OR IdMotivoSalida = @IdMotivoSalida);
END;
GO
CREATE OR ALTER PROCEDURE sp_MotivosSalida_Update
    @IdMotivoSalida INT, @CodigoMotivoSalida VARCHAR(30), @DescripcionMotivoSalida NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM MotivosSalida WHERE IdMotivoSalida = @IdMotivoSalida)
            THROW 51050, 'MotivoSalida inexistente.', 1;
        UPDATE MotivosSalida SET CodigoMotivoSalida = @CodigoMotivoSalida, DescripcionMotivoSalida = @DescripcionMotivoSalida
        WHERE IdMotivoSalida = @IdMotivoSalida;
    END TRY
    BEGIN CATCH THROW; END CATCH
END;
GO
CREATE OR ALTER PROCEDURE sp_MotivosSalida_Delete
    @IdMotivoSalida INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM MotivosSalida WHERE IdMotivoSalida = @IdMotivoSalida)
            THROW 51051, 'MotivoSalida inexistente.', 1;
        DELETE FROM MotivosSalida WHERE IdMotivoSalida = @IdMotivoSalida;
    END TRY
    BEGIN CATCH THROW; END CATCH
END;
GO

/* ==================== CatalogoMateriales (PK natural NNE) ==================== */
CREATE OR ALTER PROCEDURE sp_CatalogoMateriales_Insert
    @NNE NVARCHAR(20), @DesignacionMaterial NVARCHAR(255), @IdTipoElemento INT,
    @NumeroReferenciaMaterial VARCHAR(50) = NULL, @ATAMaterial VARCHAR(10) = NULL, @IdUsuario INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        INSERT INTO CatalogoMateriales (NNE, NumeroReferenciaMaterial, DesignacionMaterial, ATAMaterial, IdTipoElemento, IdUsuario)
        VALUES (@NNE, @NumeroReferenciaMaterial, @DesignacionMaterial, @ATAMaterial, @IdTipoElemento, @IdUsuario);
    END TRY
    BEGIN CATCH THROW; END CATCH
END;
GO
CREATE OR ALTER PROCEDURE sp_CatalogoMateriales_Read
    @NNE NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT NNE, NumeroReferenciaMaterial, DesignacionMaterial, ATAMaterial, IdTipoElemento, IdUsuario
    FROM CatalogoMateriales
    WHERE (@NNE IS NULL OR NNE = @NNE);
END;
GO
CREATE OR ALTER PROCEDURE sp_CatalogoMateriales_Update
    @NNE NVARCHAR(20), @DesignacionMaterial NVARCHAR(255), @IdTipoElemento INT,
    @NumeroReferenciaMaterial VARCHAR(50) = NULL, @ATAMaterial VARCHAR(10) = NULL, @IdUsuario INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM CatalogoMateriales WHERE NNE = @NNE)
            THROW 51060, 'CatalogoMaterial inexistente.', 1;
        UPDATE CatalogoMateriales
        SET NumeroReferenciaMaterial = @NumeroReferenciaMaterial, DesignacionMaterial = @DesignacionMaterial, ATAMaterial = @ATAMaterial,
            IdTipoElemento = @IdTipoElemento, IdUsuario = @IdUsuario
        WHERE NNE = @NNE;
    END TRY
    BEGIN CATCH THROW; END CATCH
END;
GO
CREATE OR ALTER PROCEDURE sp_CatalogoMateriales_Delete
    @NNE NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM CatalogoMateriales WHERE NNE = @NNE)
            THROW 51061, 'CatalogoMaterial inexistente.', 1;
        DELETE FROM CatalogoMateriales WHERE NNE = @NNE;
    END TRY
    BEGIN CATCH THROW; END CATCH
END;
GO

/* ==================== MaterialesSistemasArmas (relacion todo-clave: sin Update) ==================== */
CREATE OR ALTER PROCEDURE sp_MaterialesSistemasArmas_Insert
    @IdSistemaArmas INT, @NNE NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        INSERT INTO MaterialesSistemasArmas (IdSistemaArmas, NNE) VALUES (@IdSistemaArmas, @NNE);
    END TRY
    BEGIN CATCH THROW; END CATCH
END;
GO
CREATE OR ALTER PROCEDURE sp_MaterialesSistemasArmas_Read
    @IdSistemaArmas INT = NULL, @NNE NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT IdSistemaArmas, NNE FROM MaterialesSistemasArmas
    WHERE (@IdSistemaArmas IS NULL OR IdSistemaArmas = @IdSistemaArmas)
      AND (@NNE IS NULL OR NNE = @NNE);
END;
GO
CREATE OR ALTER PROCEDURE sp_MaterialesSistemasArmas_Delete
    @IdSistemaArmas INT, @NNE NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM MaterialesSistemasArmas
                       WHERE IdSistemaArmas = @IdSistemaArmas AND NNE = @NNE)
            THROW 51070, 'MaterialSistemaArmas inexistente.', 1;
        DELETE FROM MaterialesSistemasArmas WHERE IdSistemaArmas = @IdSistemaArmas AND NNE = @NNE;
    END TRY
    BEGIN CATCH THROW; END CATCH
END;
GO

/* ==================== InventarioFisico ==================== */
CREATE OR ALTER PROCEDURE sp_InventarioFisico_Insert
    @NNE NVARCHAR(20), @NumeroSerieItem VARCHAR(100) = NULL, @FechaVencimientoItem DATE = NULL,
    @ObservacionesItem NVARCHAR(500) = NULL, @TamanoItem NVARCHAR(50) = NULL,
    @IdUbicacion INT = NULL, @IdItem INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        INSERT INTO InventarioFisico (NNE, NumeroSerieItem, FechaVencimientoItem, ObservacionesItem, TamanoItem, IdUbicacion)
        VALUES (@NNE, @NumeroSerieItem, @FechaVencimientoItem, @ObservacionesItem, @TamanoItem, @IdUbicacion);
        SET @IdItem = CAST(SCOPE_IDENTITY() AS INT);
    END TRY
    BEGIN CATCH THROW; END CATCH
END;
GO
CREATE OR ALTER PROCEDURE sp_InventarioFisico_Read
    @IdItem INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT IdItem, NNE, NumeroSerieItem, FechaVencimientoItem, ObservacionesItem, TamanoItem, IdUbicacion
    FROM InventarioFisico
    WHERE (@IdItem IS NULL OR IdItem = @IdItem);
END;
GO
CREATE OR ALTER PROCEDURE sp_InventarioFisico_Update
    @IdItem INT, @NNE NVARCHAR(20), @NumeroSerieItem VARCHAR(100) = NULL,
    @FechaVencimientoItem DATE = NULL, @ObservacionesItem NVARCHAR(500) = NULL,
    @TamanoItem NVARCHAR(50) = NULL, @IdUbicacion INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM InventarioFisico WHERE IdItem = @IdItem)
            THROW 51080, 'Item de inventario inexistente.', 1;
        UPDATE InventarioFisico
        SET NNE = @NNE, NumeroSerieItem = @NumeroSerieItem, FechaVencimientoItem = @FechaVencimientoItem,
            ObservacionesItem = @ObservacionesItem, TamanoItem = @TamanoItem, IdUbicacion = @IdUbicacion
        WHERE IdItem = @IdItem;
    END TRY
    BEGIN CATCH THROW; END CATCH
END;
GO
CREATE OR ALTER PROCEDURE sp_InventarioFisico_Delete
    @IdItem INT
AS
BEGIN
    SET NOCOUNT ON;
    -- por FK ON DELETE CASCADE se eliminan tambien sus tarjetas, salidas y movimientos
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM InventarioFisico WHERE IdItem = @IdItem)
            THROW 51081, 'Item de inventario inexistente.', 1;
        DELETE FROM InventarioFisico WHERE IdItem = @IdItem;
    END TRY
    BEGIN CATCH THROW; END CATCH
END;
GO

/* ==================== Tarjetas ==================== */
CREATE OR ALTER PROCEDURE sp_Tarjetas_Insert
    @IdItem INT, @IdEstadoElemento INT, @CodigoTrazabilidadTarjeta VARCHAR(50) = NULL,
    @NumeroTarjeta VARCHAR(30) = NULL, @OrdenTrabajoTarjeta VARCHAR(30) = NULL,
    @CausasTarjeta NVARCHAR(500) = NULL, @InspectorTarjeta NVARCHAR(100) = NULL,
    @ActivaTarjeta BIT = 1, @IdTarjeta INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    -- el trigger valida la transicion de estados (un elemento en BAJA no se reactiva)
    BEGIN TRY
        INSERT INTO Tarjetas (IdItem, IdEstadoElemento, CodigoTrazabilidadTarjeta, NumeroTarjeta, OrdenTrabajoTarjeta, CausasTarjeta, InspectorTarjeta, ActivaTarjeta)
        VALUES (@IdItem, @IdEstadoElemento, @CodigoTrazabilidadTarjeta, @NumeroTarjeta, @OrdenTrabajoTarjeta, @CausasTarjeta, @InspectorTarjeta, @ActivaTarjeta);
        SET @IdTarjeta = CAST(SCOPE_IDENTITY() AS INT);
    END TRY
    BEGIN CATCH THROW; END CATCH
END;
GO
CREATE OR ALTER PROCEDURE sp_Tarjetas_Read
    @IdTarjeta INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT IdTarjeta, IdItem, IdEstadoElemento, CodigoTrazabilidadTarjeta, NumeroTarjeta, OrdenTrabajoTarjeta,
           FechaEmisionTarjeta, CausasTarjeta, InspectorTarjeta, ActivaTarjeta
    FROM Tarjetas
    WHERE (@IdTarjeta IS NULL OR IdTarjeta = @IdTarjeta);
END;
GO
CREATE OR ALTER PROCEDURE sp_Tarjetas_Update
    @IdTarjeta INT, @IdEstadoElemento INT, @CodigoTrazabilidadTarjeta VARCHAR(50) = NULL,
    @NumeroTarjeta VARCHAR(30) = NULL, @OrdenTrabajoTarjeta VARCHAR(30) = NULL,
    @CausasTarjeta NVARCHAR(500) = NULL, @InspectorTarjeta NVARCHAR(100) = NULL, @ActivaTarjeta BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM Tarjetas WHERE IdTarjeta = @IdTarjeta)
            THROW 51090, 'Tarjeta inexistente.', 1;
        UPDATE Tarjetas
        SET IdEstadoElemento = @IdEstadoElemento, CodigoTrazabilidadTarjeta = @CodigoTrazabilidadTarjeta,
            NumeroTarjeta = @NumeroTarjeta, OrdenTrabajoTarjeta = @OrdenTrabajoTarjeta, CausasTarjeta = @CausasTarjeta,
            InspectorTarjeta = @InspectorTarjeta, ActivaTarjeta = @ActivaTarjeta
        WHERE IdTarjeta = @IdTarjeta;
    END TRY
    BEGIN CATCH THROW; END CATCH
END;
GO
CREATE OR ALTER PROCEDURE sp_Tarjetas_Delete
    @IdTarjeta INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM Tarjetas WHERE IdTarjeta = @IdTarjeta)
            THROW 51091, 'Tarjeta inexistente.', 1;
        DELETE FROM Tarjetas WHERE IdTarjeta = @IdTarjeta;
    END TRY
    BEGIN CATCH THROW; END CATCH
END;
GO

/* ==================== MovimientosInventario ==================== */
CREATE OR ALTER PROCEDURE sp_MovimientosInventario_Insert
    @IdItem INT, @AccionMovimiento NVARCHAR(50), @IdUbicacion INT = NULL,
    @IdUsuarioRegistra INT = NULL, @DetalleMovimiento NVARCHAR(500) = NULL,
    @IdMovimiento INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        INSERT INTO MovimientosInventario (IdItem, IdUbicacion, AccionMovimiento, IdUsuarioRegistra, DetalleMovimiento)
        VALUES (@IdItem, @IdUbicacion, @AccionMovimiento, @IdUsuarioRegistra, @DetalleMovimiento);
        SET @IdMovimiento = CAST(SCOPE_IDENTITY() AS INT);
    END TRY
    BEGIN CATCH THROW; END CATCH
END;
GO
CREATE OR ALTER PROCEDURE sp_MovimientosInventario_Read
    @IdMovimiento INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT IdMovimiento, IdItem, IdUbicacion, FechaRegistroMovimiento, AccionMovimiento, IdUsuarioRegistra, DetalleMovimiento
    FROM MovimientosInventario
    WHERE (@IdMovimiento IS NULL OR IdMovimiento = @IdMovimiento);
END;
GO
CREATE OR ALTER PROCEDURE sp_MovimientosInventario_Update
    @IdMovimiento INT, @AccionMovimiento NVARCHAR(50), @IdUbicacion INT = NULL,
    @IdUsuarioRegistra INT = NULL, @DetalleMovimiento NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM MovimientosInventario WHERE IdMovimiento = @IdMovimiento)
            THROW 51100, 'Movimiento inexistente.', 1;
        UPDATE MovimientosInventario
        SET AccionMovimiento = @AccionMovimiento, IdUbicacion = @IdUbicacion,
            IdUsuarioRegistra = @IdUsuarioRegistra, DetalleMovimiento = @DetalleMovimiento
        WHERE IdMovimiento = @IdMovimiento;
    END TRY
    BEGIN CATCH THROW; END CATCH
END;
GO
CREATE OR ALTER PROCEDURE sp_MovimientosInventario_Delete
    @IdMovimiento INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM MovimientosInventario WHERE IdMovimiento = @IdMovimiento)
            THROW 51101, 'Movimiento inexistente.', 1;
        DELETE FROM MovimientosInventario WHERE IdMovimiento = @IdMovimiento;
    END TRY
    BEGIN CATCH THROW; END CATCH
END;
GO

/* ==================== Salidas ==================== */
CREATE OR ALTER PROCEDURE sp_Salidas_Insert
    @IdItem INT, @IdMotivoSalida INT, @DestinoSalida NVARCHAR(255) = NULL,
    @FechaPrevistaRetornoSalida DATE = NULL, @RetiradoPorSalida NVARCHAR(100) = NULL,
    @ObservacionesSalida NVARCHAR(500) = NULL, @IdSalida INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    -- los triggers de salida sacan el elemento del deposito y, si es BAJA, generan la tarjeta
    BEGIN TRY
        INSERT INTO Salidas (IdItem, IdMotivoSalida, DestinoSalida, FechaPrevistaRetornoSalida, RetiradoPorSalida, ObservacionesSalida)
        VALUES (@IdItem, @IdMotivoSalida, @DestinoSalida, @FechaPrevistaRetornoSalida, @RetiradoPorSalida, @ObservacionesSalida);
        SET @IdSalida = CAST(SCOPE_IDENTITY() AS INT);
    END TRY
    BEGIN CATCH THROW; END CATCH
END;
GO
CREATE OR ALTER PROCEDURE sp_Salidas_Read
    @IdSalida INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT IdSalida, IdItem, IdMotivoSalida, DestinoSalida, FechaSalida,
           FechaPrevistaRetornoSalida, FechaRetornoSalida, RetiradoPorSalida, ObservacionesSalida
    FROM Salidas
    WHERE (@IdSalida IS NULL OR IdSalida = @IdSalida);
END;
GO
CREATE OR ALTER PROCEDURE sp_Salidas_Update
    @IdSalida INT, @DestinoSalida NVARCHAR(255) = NULL,
    @FechaPrevistaRetornoSalida DATE = NULL, @FechaRetornoSalida DATETIME2(0) = NULL,
    @RetiradoPorSalida NVARCHAR(100) = NULL, @ObservacionesSalida NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM Salidas WHERE IdSalida = @IdSalida)
            THROW 51110, 'Salida inexistente.', 1;
        UPDATE Salidas
        SET DestinoSalida = @DestinoSalida, FechaPrevistaRetornoSalida = @FechaPrevistaRetornoSalida,
            FechaRetornoSalida = @FechaRetornoSalida, RetiradoPorSalida = @RetiradoPorSalida, ObservacionesSalida = @ObservacionesSalida
        WHERE IdSalida = @IdSalida;
    END TRY
    BEGIN CATCH THROW; END CATCH
END;
GO
CREATE OR ALTER PROCEDURE sp_Salidas_Delete
    @IdSalida INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM Salidas WHERE IdSalida = @IdSalida)
            THROW 51111, 'Salida inexistente.', 1;
        DELETE FROM Salidas WHERE IdSalida = @IdSalida;
    END TRY
    BEGIN CATCH THROW; END CATCH
END;
GO

PRINT '03 - Procedimientos CRUD por tabla creados correctamente.';
GO
