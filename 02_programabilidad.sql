/* ============================================================================
   ARCHIVO 02 de 06 — PROGRAMABILIDAD (Transact-SQL)
   Requiere haber ejecutado 01 (gestion_material.sql).

   Contenido (temas de la materia que demuestra cada bloque):
     - FUNCIONES escalares ............... fn_DiasFueraDeposito, fn_EstadoActual, fn_DiasParaVencer
     - TRIGGERS AFTER .................... trg_salida_abre_saca_del_deposito,
                                          trg_salida_baja_genera_tarjeta,
                                          trg_tarjeta_no_reactiva_baja (integridad de transiciones)
     - TRIGGER INSTEAD OF ............... trg_estado_no_borrar (protege catalogo)
     - PROCEDIMIENTOS + TRANSACCIONES ... sp_AltaElemento, sp_RegistrarSalida,
                                          sp_RegistrarRetorno, sp_CambiarEstado
     - CURSOR ........................... sp_ReporteSalidasVencidas
   ============================================================================ */

-- Requerido para crear funciones/triggers/procedimientos con opciones correctas.
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* ==================== FUNCIONES ESCALARES ==================== */

-- Dias que un elemento lleva fuera del deposito (NULL si esta adentro).
CREATE FUNCTION fn_DiasFueraDeposito (@IdItem INT)
RETURNS INT
AS
BEGIN
    DECLARE @dias INT;
    SELECT @dias = DATEDIFF(DAY, s.FechaSalida, SYSDATETIME())
    FROM Salidas s
    WHERE s.IdItem = @IdItem AND s.FechaRetornoSalida IS NULL;
    RETURN @dias;
END;
GO

-- Codigo del estado de la tarjeta activa del elemento (NULL si no tiene tarjeta).
CREATE FUNCTION fn_EstadoActual (@IdItem INT)
RETURNS VARCHAR(30)
AS
BEGIN
    DECLARE @cod VARCHAR(30);
    SELECT @cod = e.CodigoEstadoElemento
    FROM Tarjetas t
    JOIN EstadosElemento e ON e.IdEstadoElemento = t.IdEstadoElemento
    WHERE t.IdItem = @IdItem AND t.ActivaTarjeta = 1;
    RETURN @cod;
END;
GO

-- Dias hasta el vencimiento (negativo = ya vencido; NULL si no aplica).
CREATE FUNCTION fn_DiasParaVencer (@IdItem INT)
RETURNS INT
AS
BEGIN
    DECLARE @dias INT;
    SELECT @dias = DATEDIFF(DAY, CAST(SYSDATETIME() AS DATE), FechaVencimientoItem)
    FROM InventarioFisico
    WHERE IdItem = @IdItem;
    RETURN @dias;
END;
GO

/* ==================== TRIGGERS ==================== */

/* AFTER INSERT en Salidas: al abrir una salida (sin fecha de retorno) el elemento
   deja de estar en el deposito (IdUbicacion = NULL). Sincroniza "esta afuera". */
CREATE TRIGGER trg_salida_abre_saca_del_deposito
ON Salidas
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE inv
    SET inv.IdUbicacion = NULL
    FROM InventarioFisico inv
    JOIN inserted i ON i.IdItem = inv.IdItem
    WHERE i.FechaRetornoSalida IS NULL;
END;
GO

/* AFTER INSERT en Salidas: si la salida es por BAJA, se genera automaticamente
   la tarjeta en estado BAJA (desactivando la tarjeta anterior). */
CREATE TRIGGER trg_salida_baja_genera_tarjeta
ON Salidas
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1
               FROM inserted i
               JOIN MotivosSalida m ON m.IdMotivoSalida = i.IdMotivoSalida
               WHERE m.CodigoMotivoSalida = 'BAJA')
    BEGIN
        DECLARE @id_baja INT = (SELECT IdEstadoElemento FROM EstadosElemento WHERE CodigoEstadoElemento = 'BAJA');

        -- desactivar la tarjeta activa de los elementos dados de baja
        UPDATE t
        SET t.ActivaTarjeta = 0
        FROM Tarjetas t
        JOIN inserted i ON i.IdItem = t.IdItem
        JOIN MotivosSalida m ON m.IdMotivoSalida = i.IdMotivoSalida
        WHERE m.CodigoMotivoSalida = 'BAJA' AND t.ActivaTarjeta = 1;

        -- crear la tarjeta BAJA
        INSERT INTO Tarjetas (IdItem, IdEstadoElemento, CausasTarjeta, ActivaTarjeta)
        SELECT i.IdItem, @id_baja, N'Baja registrada por salida definitiva', 1
        FROM inserted i
        JOIN MotivosSalida m ON m.IdMotivoSalida = i.IdMotivoSalida
        WHERE m.CodigoMotivoSalida = 'BAJA';
    END
END;
GO

/* AFTER INSERT en Tarjetas: integridad de TRANSICIONES. Un elemento dado de BAJA
   no puede volver a EN_SERVICIO (ni a ningun estado distinto de BAJA). */
CREATE TRIGGER trg_tarjeta_no_reactiva_baja
ON Tarjetas
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN EstadosElemento en ON en.IdEstadoElemento = i.IdEstadoElemento AND en.CodigoEstadoElemento <> 'BAJA'
        WHERE EXISTS (
            SELECT 1
            FROM Tarjetas t
            JOIN EstadosElemento eb ON eb.IdEstadoElemento = t.IdEstadoElemento
            WHERE t.IdItem = i.IdItem AND eb.CodigoEstadoElemento = 'BAJA'
        )
    )
    BEGIN
        THROW 50001, 'Transicion invalida: un elemento dado de BAJA no puede volver a servicio.', 1;
    END
END;
GO

/* INSTEAD OF DELETE en EstadosElemento: los estados son catalogo de referencia.
   Se permite borrar uno solo si NINGUNA tarjeta lo usa; si esta en uso, se rechaza. */
CREATE TRIGGER trg_estado_no_borrar
ON EstadosElemento
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM Tarjetas t JOIN deleted d ON d.IdEstadoElemento = t.IdEstadoElemento)
    BEGIN
        THROW 50002, 'No se puede borrar un estado en uso por tarjetas existentes.', 1;
    END

    DELETE e
    FROM EstadosElemento e
    JOIN deleted d ON d.IdEstadoElemento = e.IdEstadoElemento;
END;
GO

/* ==================== PROCEDIMIENTOS ALMACENADOS ==================== */

/* Alta de un ejemplar fisico + su primera tarjeta EN_SERVICIO (transaccion). */
CREATE PROCEDURE sp_AltaElemento
    @NNE              NVARCHAR(20),
    @NumeroSerie      VARCHAR(100)  = NULL,
    @IdUbicacion      INT           = NULL,
    @FechaVencimiento DATE          = NULL,
    @Tamano           NVARCHAR(50)  = NULL,
    @Observaciones    NVARCHAR(500) = NULL,
    @Inspector        NVARCHAR(100) = NULL,
    @IdItem           INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
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

/* Registrar un retiro del deposito. Valida: elemento existe, motivo valido,
   sin salida abierta previa y no dado de baja. Los triggers completan el efecto. */
CREATE PROCEDURE sp_RegistrarSalida
    @IdItem               INT,
    @CodigoMotivo         VARCHAR(30),
    @Destino              NVARCHAR(255) = NULL,
    @RetiradoPor          NVARCHAR(100) = NULL,
    @FechaPrevistaRetorno DATE          = NULL,
    @Observaciones        NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DECLARE @IdMotivo INT = (SELECT IdMotivoSalida FROM MotivosSalida WHERE CodigoMotivoSalida = @CodigoMotivo);

        IF NOT EXISTS (SELECT 1 FROM InventarioFisico WHERE IdItem = @IdItem)
            THROW 50020, 'El elemento no existe.', 1;
        IF @IdMotivo IS NULL
            THROW 50021, 'Motivo de salida invalido.', 1;
        IF EXISTS (SELECT 1 FROM Salidas WHERE IdItem = @IdItem AND FechaRetornoSalida IS NULL)
            THROW 50022, 'El elemento ya tiene una salida abierta.', 1;
        IF dbo.fn_EstadoActual(@IdItem) = 'BAJA'
            THROW 50023, 'El elemento esta dado de baja: no admite salidas.', 1;

        BEGIN TRANSACTION;
            INSERT INTO Salidas (IdItem, IdMotivoSalida, DestinoSalida, RetiradoPorSalida, FechaPrevistaRetornoSalida, ObservacionesSalida)
            VALUES (@IdItem, @IdMotivo, @Destino, @RetiradoPor, @FechaPrevistaRetorno, @Observaciones);
            -- triggers: sacan el elemento del deposito y, si es BAJA, generan la tarjeta BAJA
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

/* Registrar el retorno de una salida abierta y reubicar el elemento. */
CREATE PROCEDURE sp_RegistrarRetorno
    @IdSalida          INT,
    @IdUbicacion       INT,
    @IdUsuarioRegistra INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DECLARE @IdItem INT, @es_baja BIT;

        SELECT @IdItem = s.IdItem,
               @es_baja = CASE WHEN m.CodigoMotivoSalida = 'BAJA' THEN 1 ELSE 0 END
        FROM Salidas s
        JOIN MotivosSalida m ON m.IdMotivoSalida = s.IdMotivoSalida
        WHERE s.IdSalida = @IdSalida AND s.FechaRetornoSalida IS NULL;

        IF @IdItem IS NULL
            THROW 50030, 'No existe una salida abierta con ese id.', 1;
        IF @es_baja = 1
            THROW 50031, 'Una baja no retorna al deposito.', 1;
        IF NOT EXISTS (SELECT 1 FROM Ubicaciones WHERE IdUbicacion = @IdUbicacion)
            THROW 50032, 'La ubicacion destino no existe.', 1;

        BEGIN TRANSACTION;
            UPDATE Salidas SET FechaRetornoSalida = SYSDATETIME()
            WHERE IdSalida = @IdSalida;

            UPDATE InventarioFisico SET IdUbicacion = @IdUbicacion
            WHERE IdItem = @IdItem;

            INSERT INTO MovimientosInventario (IdItem, IdUbicacion, AccionMovimiento, IdUsuarioRegistra, DetalleMovimiento)
            VALUES (@IdItem, @IdUbicacion, N'RETORNO', @IdUsuarioRegistra, N'Retorno al deposito');
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

/* Cambiar el estado del elemento: desactiva la tarjeta activa y emite una nueva
   (mecanismo central del historial de tarjetas). El trigger de transiciones
   impide reactivar un elemento dado de baja. */
CREATE PROCEDURE sp_CambiarEstado
    @IdItem            INT,
    @CodigoEstado      VARCHAR(30),
    @OrdenTrabajo      VARCHAR(30)   = NULL,
    @Causas            NVARCHAR(500) = NULL,
    @Inspector         NVARCHAR(100) = NULL,
    @NumeroTarjeta     VARCHAR(30)   = NULL,
    @CodigoTrazabilidad VARCHAR(50)  = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DECLARE @IdEstado INT = (SELECT IdEstadoElemento FROM EstadosElemento WHERE CodigoEstadoElemento = @CodigoEstado);

        IF NOT EXISTS (SELECT 1 FROM InventarioFisico WHERE IdItem = @IdItem)
            THROW 50040, 'El elemento no existe.', 1;
        IF @IdEstado IS NULL
            THROW 50041, 'Estado invalido.', 1;

        BEGIN TRANSACTION;
            UPDATE Tarjetas SET ActivaTarjeta = 0 WHERE IdItem = @IdItem AND ActivaTarjeta = 1;

            INSERT INTO Tarjetas (IdItem, IdEstadoElemento, OrdenTrabajoTarjeta, CausasTarjeta, InspectorTarjeta, NumeroTarjeta, CodigoTrazabilidadTarjeta, ActivaTarjeta)
            VALUES (@IdItem, @IdEstado, @OrdenTrabajo, @Causas, @Inspector, @NumeroTarjeta, @CodigoTrazabilidad, 1);
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

/* ==================== CURSOR ==================== */

/* Reporte de salidas vencidas: recorre con un CURSOR las salidas abiertas cuya
   fecha prevista de retorno ya paso, las imprime y devuelve el listado ordenado
   por dias de atraso. Demuestra DECLARE/OPEN/FETCH/CLOSE/DEALLOCATE. */
CREATE PROCEDURE sp_ReporteSalidasVencidas
    @AFecha DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @AFecha IS NULL SET @AFecha = CAST(SYSDATETIME() AS DATE);

    DECLARE @rep TABLE (
        IdSalida       INT,
        IdItem         INT,
        Designacion    NVARCHAR(255),
        Motivo         VARCHAR(30),
        Destino        NVARCHAR(255),
        FechaPrevista  DATE,
        DiasAtraso     INT
    );

    DECLARE @IdSalida INT, @IdItem INT, @desig NVARCHAR(255),
            @motivo VARCHAR(30), @destino NVARCHAR(255), @prev DATE, @atraso INT;

    DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
        SELECT s.IdSalida, s.IdItem, c.DesignacionMaterial, m.CodigoMotivoSalida, s.DestinoSalida, s.FechaPrevistaRetornoSalida
        FROM Salidas s
        JOIN InventarioFisico inv   ON inv.IdItem = s.IdItem
        JOIN CatalogoMateriales c   ON c.NNE = inv.NNE
        JOIN MotivosSalida m        ON m.IdMotivoSalida = s.IdMotivoSalida
        WHERE s.FechaRetornoSalida IS NULL
          AND s.FechaPrevistaRetornoSalida IS NOT NULL
          AND s.FechaPrevistaRetornoSalida < @AFecha;

    OPEN cur;
    FETCH NEXT FROM cur INTO @IdSalida, @IdItem, @desig, @motivo, @destino, @prev;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @atraso = DATEDIFF(DAY, @prev, @AFecha);
        PRINT CONCAT('Salida ', @IdSalida, ' | item ', @IdItem, ' | ', @desig,
                     ' | ', @motivo, ' | atraso ', @atraso, ' dias');
        INSERT INTO @rep VALUES (@IdSalida, @IdItem, @desig, @motivo, @destino, @prev, @atraso);
        FETCH NEXT FROM cur INTO @IdSalida, @IdItem, @desig, @motivo, @destino, @prev;
    END

    CLOSE cur;
    DEALLOCATE cur;

    SELECT * FROM @rep ORDER BY DiasAtraso DESC;
END;
GO

PRINT '02 - Funciones, triggers, procedimientos y cursor creados correctamente.';
GO
