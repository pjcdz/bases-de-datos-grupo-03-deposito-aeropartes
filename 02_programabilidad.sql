/* ============================================================================
   ARCHIVO 02 de 05 — PROGRAMABILIDAD (Transact-SQL)
   Requiere haber ejecutado 01 (gestion_material.sql).

   Contenido (temas de la materia que demuestra cada bloque):
     - FUNCIONES escalares ............... fn_DiasFueraDeposito, fn_EstadoActual, fn_DiasParaVencer
     - TRIGGERS AFTER .................... trg_salida_abre_saca_del_deposito,
                                          trg_salida_baja_genera_tarjeta,
                                          trg_tarjeta_no_reactiva_baja (integridad de transiciones)
     - TRIGGER INSTEAD OF ............... trg_estado_no_borrar (protege catálogo)
     - PROCEDIMIENTOS + TRANSACCIONES ... sp_AltaElemento, sp_RegistrarSalida,
                                          sp_RegistrarRetorno, sp_CambiarEstado
     - CURSOR ........................... sp_ReporteSalidasVencidas
   ============================================================================ */

-- Requerido para crear funciones/triggers/procedimientos con opciones correctas.
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* ==================== FUNCIONES ESCALARES ==================== */

-- Días que un elemento lleva fuera del depósito (NULL si está adentro).
CREATE FUNCTION fn_DiasFueraDeposito (@id_item INT)
RETURNS INT
AS
BEGIN
    DECLARE @dias INT;
    SELECT @dias = DATEDIFF(DAY, s.fecha_salida, SYSDATETIME())
    FROM salida s
    WHERE s.id_item = @id_item AND s.fecha_retorno IS NULL;
    RETURN @dias;
END;
GO

-- Código del estado de la tarjeta activa del elemento (NULL si no tiene tarjeta).
CREATE FUNCTION fn_EstadoActual (@id_item INT)
RETURNS NVARCHAR(30)
AS
BEGIN
    DECLARE @cod NVARCHAR(30);
    SELECT @cod = e.codigo
    FROM tarjeta t
    JOIN estado_elemento e ON e.id_estado = t.id_estado
    WHERE t.id_item = @id_item AND t.activa = 1;
    RETURN @cod;
END;
GO

-- Días hasta el vencimiento (negativo = ya vencido; NULL si no aplica).
CREATE FUNCTION fn_DiasParaVencer (@id_item INT)
RETURNS INT
AS
BEGIN
    DECLARE @dias INT;
    SELECT @dias = DATEDIFF(DAY, CAST(SYSDATETIME() AS DATE), vencimiento)
    FROM inventario_fisico
    WHERE id_item = @id_item;
    RETURN @dias;
END;
GO

/* ==================== TRIGGERS ==================== */

/* AFTER INSERT en salida: al abrir una salida (sin fecha de retorno) el elemento
   deja de estar en el depósito (id_ubicacion = NULL). Resuelve la sincronización
   "está afuera" para que nunca figure adentro con una salida abierta. */
CREATE TRIGGER trg_salida_abre_saca_del_deposito
ON salida
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE inv
    SET inv.id_ubicacion = NULL
    FROM inventario_fisico inv
    JOIN inserted i ON i.id_item = inv.id_item
    WHERE i.fecha_retorno IS NULL;
END;
GO

/* AFTER INSERT en salida: si la salida es por BAJA, se genera automáticamente
   la tarjeta en estado BAJA (desactivando la tarjeta anterior). Mantiene en
   sincronía el estado del elemento con su salida definitiva. */
CREATE TRIGGER trg_salida_baja_genera_tarjeta
ON salida
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1
               FROM inserted i
               JOIN motivo_salida m ON m.id_motivo = i.id_motivo
               WHERE m.codigo = 'BAJA')
    BEGIN
        DECLARE @id_baja INT = (SELECT id_estado FROM estado_elemento WHERE codigo = 'BAJA');

        -- desactivar la tarjeta activa de los elementos dados de baja
        UPDATE t
        SET t.activa = 0
        FROM tarjeta t
        JOIN inserted i ON i.id_item = t.id_item
        JOIN motivo_salida m ON m.id_motivo = i.id_motivo
        WHERE m.codigo = 'BAJA' AND t.activa = 1;

        -- crear la tarjeta BAJA
        INSERT INTO tarjeta (id_item, id_estado, causas, activa)
        SELECT i.id_item, @id_baja, N'Baja registrada por salida definitiva', 1
        FROM inserted i
        JOIN motivo_salida m ON m.id_motivo = i.id_motivo
        WHERE m.codigo = 'BAJA';
    END
END;
GO

/* AFTER INSERT en tarjeta: integridad de TRANSICIONES. Un elemento dado de BAJA
   no puede volver a EN_SERVICIO (ni a ningún estado distinto de BAJA). */
CREATE TRIGGER trg_tarjeta_no_reactiva_baja
ON tarjeta
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN estado_elemento en ON en.id_estado = i.id_estado AND en.codigo <> 'BAJA'
        WHERE EXISTS (
            SELECT 1
            FROM tarjeta t
            JOIN estado_elemento eb ON eb.id_estado = t.id_estado
            WHERE t.id_item = i.id_item AND eb.codigo = 'BAJA'
        )
    )
    BEGIN
        THROW 50001, 'Transición inválida: un elemento dado de BAJA no puede volver a servicio.', 1;
    END
END;
GO

/* INSTEAD OF DELETE en estado_elemento: los estados son catálogo de referencia.
   Se permite borrar uno solo si NINGUNA tarjeta lo usa; si está en uso, se rechaza
   en lugar de romper la integridad referencial. */
CREATE TRIGGER trg_estado_no_borrar
ON estado_elemento
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM tarjeta t JOIN deleted d ON d.id_estado = t.id_estado)
    BEGIN
        THROW 50002, 'No se puede borrar un estado en uso por tarjetas existentes.', 1;
    END

    DELETE e
    FROM estado_elemento e
    JOIN deleted d ON d.id_estado = e.id_estado;
END;
GO

/* ==================== PROCEDIMIENTOS ALMACENADOS ==================== */

/* Alta de un ejemplar físico + su primera tarjeta EN_SERVICIO (transacción). */
CREATE PROCEDURE sp_AltaElemento
    @NNE           NVARCHAR(20),
    @n_serie       NVARCHAR(100) = NULL,
    @id_ubicacion  INT           = NULL,
    @vencimiento   DATE          = NULL,
    @tamano        NVARCHAR(50)  = NULL,
    @observaciones NVARCHAR(500) = NULL,
    @inspector     NVARCHAR(100) = NULL,
    @id_item       INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM catalogo_material WHERE NNE = @NNE)
            THROW 50010, 'El NNE no existe en el catálogo.', 1;

        BEGIN TRANSACTION;
            INSERT INTO inventario_fisico (NNE, n_serie, vencimiento, observaciones, [tamaño], id_ubicacion)
            VALUES (@NNE, @n_serie, @vencimiento, @observaciones, @tamano, @id_ubicacion);

            SET @id_item = CAST(SCOPE_IDENTITY() AS INT);

            INSERT INTO tarjeta (id_item, id_estado, inspector, activa)
            SELECT @id_item, id_estado, @inspector, 1
            FROM estado_elemento WHERE codigo = 'EN_SERVICIO';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

/* Registrar un retiro del depósito. Valida: elemento existe, motivo válido,
   sin salida abierta previa y no dado de baja. Los triggers completan el efecto. */
CREATE PROCEDURE sp_RegistrarSalida
    @id_item                INT,
    @codigo_motivo          NVARCHAR(30),
    @destino                NVARCHAR(255) = NULL,
    @retirado_por           NVARCHAR(100) = NULL,
    @fecha_prevista_retorno DATE          = NULL,
    @observaciones          NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DECLARE @id_motivo INT = (SELECT id_motivo FROM motivo_salida WHERE codigo = @codigo_motivo);

        IF NOT EXISTS (SELECT 1 FROM inventario_fisico WHERE id_item = @id_item)
            THROW 50020, 'El elemento no existe.', 1;
        IF @id_motivo IS NULL
            THROW 50021, 'Motivo de salida inválido.', 1;
        IF EXISTS (SELECT 1 FROM salida WHERE id_item = @id_item AND fecha_retorno IS NULL)
            THROW 50022, 'El elemento ya tiene una salida abierta.', 1;
        IF dbo.fn_EstadoActual(@id_item) = 'BAJA'
            THROW 50023, 'El elemento está dado de baja: no admite salidas.', 1;

        BEGIN TRANSACTION;
            INSERT INTO salida (id_item, id_motivo, destino, retirado_por, fecha_prevista_retorno, observaciones)
            VALUES (@id_item, @id_motivo, @destino, @retirado_por, @fecha_prevista_retorno, @observaciones);
            -- triggers: sacan el elemento del depósito y, si es BAJA, generan la tarjeta BAJA
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
    @id_salida           INT,
    @id_ubicacion        INT,
    @id_usuario_registra INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DECLARE @id_item INT, @es_baja BIT;

        SELECT @id_item = s.id_item,
               @es_baja = CASE WHEN m.codigo = 'BAJA' THEN 1 ELSE 0 END
        FROM salida s
        JOIN motivo_salida m ON m.id_motivo = s.id_motivo
        WHERE s.id_salida = @id_salida AND s.fecha_retorno IS NULL;

        IF @id_item IS NULL
            THROW 50030, 'No existe una salida abierta con ese id.', 1;
        IF @es_baja = 1
            THROW 50031, 'Una baja no retorna al depósito.', 1;
        IF NOT EXISTS (SELECT 1 FROM ubicacion WHERE id_ubicacion = @id_ubicacion)
            THROW 50032, 'La ubicación destino no existe.', 1;

        BEGIN TRANSACTION;
            UPDATE salida SET fecha_retorno = SYSDATETIME()
            WHERE id_salida = @id_salida;

            UPDATE inventario_fisico SET id_ubicacion = @id_ubicacion
            WHERE id_item = @id_item;

            INSERT INTO movimiento_inventario (id_item, id_ubicacion, accion, id_usuario_registra, detalle)
            VALUES (@id_item, @id_ubicacion, N'RETORNO', @id_usuario_registra, N'Retorno al depósito');
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
    @id_item             INT,
    @codigo_estado       NVARCHAR(30),
    @ot                  NVARCHAR(30)  = NULL,
    @causas              NVARCHAR(500) = NULL,
    @inspector           NVARCHAR(100) = NULL,
    @nro_tarjeta         NVARCHAR(30)  = NULL,
    @codigo_trazabilidad NVARCHAR(50)  = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DECLARE @id_estado INT = (SELECT id_estado FROM estado_elemento WHERE codigo = @codigo_estado);

        IF NOT EXISTS (SELECT 1 FROM inventario_fisico WHERE id_item = @id_item)
            THROW 50040, 'El elemento no existe.', 1;
        IF @id_estado IS NULL
            THROW 50041, 'Estado inválido.', 1;

        BEGIN TRANSACTION;
            UPDATE tarjeta SET activa = 0 WHERE id_item = @id_item AND activa = 1;

            INSERT INTO tarjeta (id_item, id_estado, ot, causas, inspector, nro_tarjeta, codigo_trazabilidad, activa)
            VALUES (@id_item, @id_estado, @ot, @causas, @inspector, @nro_tarjeta, @codigo_trazabilidad, 1);
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
   fecha prevista de retorno ya pasó, las imprime y devuelve el listado ordenado
   por días de atraso. Demuestra el ciclo completo DECLARE/OPEN/FETCH/CLOSE/DEALLOCATE. */
CREATE PROCEDURE sp_ReporteSalidasVencidas
    @a_fecha DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @a_fecha IS NULL SET @a_fecha = CAST(SYSDATETIME() AS DATE);

    DECLARE @rep TABLE (
        id_salida    INT,
        id_item      INT,
        designacion  NVARCHAR(255),
        motivo       NVARCHAR(30),
        destino      NVARCHAR(255),
        fecha_prevista DATE,
        dias_atraso  INT
    );

    DECLARE @id_salida INT, @id_item INT, @desig NVARCHAR(255),
            @motivo NVARCHAR(30), @destino NVARCHAR(255), @prev DATE, @atraso INT;

    DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
        SELECT s.id_salida, s.id_item, c.designacion, m.codigo, s.destino, s.fecha_prevista_retorno
        FROM salida s
        JOIN inventario_fisico inv ON inv.id_item = s.id_item
        JOIN catalogo_material c   ON c.NNE = inv.NNE
        JOIN motivo_salida m       ON m.id_motivo = s.id_motivo
        WHERE s.fecha_retorno IS NULL
          AND s.fecha_prevista_retorno IS NOT NULL
          AND s.fecha_prevista_retorno < @a_fecha;

    OPEN cur;
    FETCH NEXT FROM cur INTO @id_salida, @id_item, @desig, @motivo, @destino, @prev;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @atraso = DATEDIFF(DAY, @prev, @a_fecha);
        PRINT CONCAT('Salida ', @id_salida, ' | item ', @id_item, ' | ', @desig,
                     ' | ', @motivo, ' | atraso ', @atraso, ' días');
        INSERT INTO @rep VALUES (@id_salida, @id_item, @desig, @motivo, @destino, @prev, @atraso);
        FETCH NEXT FROM cur INTO @id_salida, @id_item, @desig, @motivo, @destino, @prev;
    END

    CLOSE cur;
    DEALLOCATE cur;

    SELECT * FROM @rep ORDER BY dias_atraso DESC;
END;
GO

PRINT '02 - Funciones, triggers, procedimientos y cursor creados correctamente.';
GO
