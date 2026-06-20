/* ============================================================================
   ARCHIVO 04 de 06 - VISTAS
   Requiere haber ejecutado 01 y 02 (las vistas usan funciones del archivo 02).

   Tema de la materia: Vistas (tablas virtuales), JOINs, abstraccion de consultas.
   ============================================================================ */

-- Requerido para crear vistas con opciones correctas.
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* Elementos que estan FUERA del deposito (con salida abierta). */
CREATE VIEW vw_elementos_afuera AS
SELECT inv.IdItem,
       c.NNE,
       c.DesignacionMaterial,
       inv.NumeroSerieItem,
       m.CodigoMotivoSalida                       AS Motivo,
       s.DestinoSalida,
       s.RetiradoPorSalida,
       s.FechaSalida,
       s.FechaPrevistaRetornoSalida,
       dbo.fn_DiasFueraDeposito(inv.IdItem)       AS DiasAfuera
FROM InventarioFisico inv
JOIN Salidas s            ON s.IdItem = inv.IdItem AND s.FechaRetornoSalida IS NULL
JOIN MotivosSalida m      ON m.IdMotivoSalida = s.IdMotivoSalida
JOIN CatalogoMateriales c ON c.NNE = inv.NNE;
GO

/* Stock realmente disponible: en servicio Y dentro del deposito. */
CREATE VIEW vw_stock_disponible AS
SELECT inv.IdItem,
       c.NNE,
       c.DesignacionMaterial,
       inv.NumeroSerieItem,
       inv.TamanoItem,
       u.DepositoUbicacion,
       u.SectorUbicacion
FROM InventarioFisico inv
JOIN CatalogoMateriales c ON c.NNE = inv.NNE
JOIN Ubicaciones u        ON u.IdUbicacion = inv.IdUbicacion
WHERE dbo.fn_EstadoActual(inv.IdItem) = 'EN_SERVICIO'
  AND inv.IdUbicacion IS NOT NULL;
GO

/* Historial completo de tarjetas por elemento (la activa marcada con ActivaTarjeta = 1). */
CREATE VIEW vw_historial_tarjetas AS
SELECT t.IdItem,
       t.IdTarjeta,
       e.CodigoEstadoElemento AS Estado,
       t.FechaEmisionTarjeta,
       t.OrdenTrabajoTarjeta,
       t.CausasTarjeta,
       t.InspectorTarjeta,
       t.ActivaTarjeta
FROM Tarjetas t
JOIN EstadosElemento e ON e.IdEstadoElemento = t.IdEstadoElemento;
GO

/* Elementos vencidos (fecha de vencimiento ya pasada). */
CREATE VIEW vw_elementos_vencidos AS
SELECT inv.IdItem,
       c.NNE,
       c.DesignacionMaterial,
       inv.NumeroSerieItem,
       inv.FechaVencimientoItem,
       dbo.fn_DiasParaVencer(inv.IdItem) AS DiasParaVencer
FROM InventarioFisico inv
JOIN CatalogoMateriales c ON c.NNE = inv.NNE
WHERE inv.FechaVencimientoItem IS NOT NULL
  AND inv.FechaVencimientoItem < CAST(SYSDATETIME() AS DATE);
GO

PRINT '04 - Vistas creadas correctamente.';
GO
