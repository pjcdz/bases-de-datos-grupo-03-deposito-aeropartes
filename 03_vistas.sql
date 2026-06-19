/* ============================================================================
hola   
ARCHIVO 03 de 05 — VISTAS
   Requiere haber ejecutado 01 y 02 (las vistas usan funciones del archivo 02).

   Tema de la materia: Vistas (tablas virtuales), JOINs, abstracción de consultas.
   ============================================================================ */

-- Requerido para crear vistas con opciones correctas.
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* Elementos que están FUERA del depósito (con salida abierta). */
CREATE VIEW vw_elementos_afuera AS
SELECT inv.id_item,
       c.NNE,
       c.designacion,
       inv.n_serie,
       m.codigo                                 AS motivo,
       s.destino,
       s.retirado_por,
       s.fecha_salida,
       s.fecha_prevista_retorno,
       dbo.fn_DiasFueraDeposito(inv.id_item)    AS dias_afuera
FROM inventario_fisico inv
JOIN salida s         ON s.id_item = inv.id_item AND s.fecha_retorno IS NULL
JOIN motivo_salida m  ON m.id_motivo = s.id_motivo
JOIN catalogo_material c ON c.NNE = inv.NNE;
GO

/* Stock realmente disponible: en servicio Y dentro del depósito. */
CREATE VIEW vw_stock_disponible AS
SELECT inv.id_item,
       c.NNE,
       c.designacion,
       inv.n_serie,
       inv.[tamaño],
       u.deposito,
       u.sector
FROM inventario_fisico inv
JOIN catalogo_material c ON c.NNE = inv.NNE
JOIN ubicacion u         ON u.id_ubicacion = inv.id_ubicacion
WHERE dbo.fn_EstadoActual(inv.id_item) = 'EN_SERVICIO'
  AND inv.id_ubicacion IS NOT NULL;
GO

/* Historial completo de tarjetas por elemento (la activa marcada con activa = 1). */
CREATE VIEW vw_historial_tarjetas AS
SELECT t.id_item,
       t.id_tarjeta,
       e.codigo        AS estado,
       t.fecha_emision,
       t.ot,
       t.causas,
       t.inspector,
       t.activa
FROM tarjeta t
JOIN estado_elemento e ON e.id_estado = t.id_estado;
GO

/* Elementos vencidos (fecha de vencimiento ya pasada). */
CREATE VIEW vw_elementos_vencidos AS
SELECT inv.id_item,
       c.NNE,
       c.designacion,
       inv.n_serie,
       inv.vencimiento,
       dbo.fn_DiasParaVencer(inv.id_item) AS dias_para_vencer
FROM inventario_fisico inv
JOIN catalogo_material c ON c.NNE = inv.NNE
WHERE inv.vencimiento IS NOT NULL
  AND inv.vencimiento < CAST(SYSDATETIME() AS DATE);
GO

PRINT '03 - Vistas creadas correctamente.';
GO
