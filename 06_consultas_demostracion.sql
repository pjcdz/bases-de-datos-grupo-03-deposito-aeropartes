/* ============================================================================
   ARCHIVO 06 de 06 — CONSULTAS DE DEMOSTRACIÓN
   Requiere 01..05. Pensado para correr consulta por consulta en la defensa.
   Cada bloque demuestra un tema de "SQL Avanzado" de la materia.
   ============================================================================ */

SET QUOTED_IDENTIFIER ON;
GO

/* ---------- 1) GROUP BY + HAVING ----------
   Cantidad de ejemplares por estado actual; solo estados con mas de 1 elemento. */
SELECT dbo.fn_EstadoActual(inv.IdItem) AS Estado, COUNT(*) AS Cantidad
FROM InventarioFisico inv
GROUP BY dbo.fn_EstadoActual(inv.IdItem)
HAVING COUNT(*) > 1
ORDER BY Cantidad DESC;
GO

/* ---------- 2) NOT EXISTS ----------
   Elementos que NUNCA salieron del deposito. */
SELECT inv.IdItem, c.DesignacionMaterial, inv.NumeroSerieItem
FROM InventarioFisico inv
JOIN CatalogoMateriales c ON c.NNE = inv.NNE
WHERE NOT EXISTS (SELECT 1 FROM Salidas s WHERE s.IdItem = inv.IdItem);
GO

/* ---------- 3) EXISTS ----------
   Ubicaciones que tienen al menos un elemento actualmente almacenado. */
SELECT u.IdUbicacion, u.DepositoUbicacion, u.SectorUbicacion
FROM Ubicaciones u
WHERE EXISTS (SELECT 1 FROM InventarioFisico inv WHERE inv.IdUbicacion = u.IdUbicacion);
GO

/* ---------- 4) UNION ----------
   Directorio unificado de personas que aparecen en el sistema, de tres origenes. */
SELECT CONCAT(NombreUsuario, ' ', ApellidoUsuario) AS Persona, N'Usuario del sistema' AS Origen
FROM Usuarios
UNION
SELECT DISTINCT InspectorTarjeta, N'Inspector (tarjeta)'
FROM Tarjetas WHERE InspectorTarjeta IS NOT NULL
UNION
SELECT DISTINCT RetiradoPorSalida, N'Retiró material (salida)'
FROM Salidas WHERE RetiradoPorSalida IS NOT NULL
ORDER BY Persona;
GO

/* ---------- 5) INTERSECT ----------
   NNE que estan a la vez en inventario fisico y asociados a algun sistema de armas. */
SELECT NNE FROM InventarioFisico
INTERSECT
SELECT NNE FROM MaterialesSistemasArmas;
GO

/* ---------- 6) EXCEPT ----------
   NNE del catalogo que NO tienen ningun ejemplar cargado en inventario. */
SELECT NNE FROM CatalogoMateriales
EXCEPT
SELECT NNE FROM InventarioFisico;
GO

/* ---------- 7) Subconsulta correlacionada ----------
   Por cada elemento, cuantas tarjetas tuvo (tamaño de su historial). */
SELECT inv.IdItem, c.DesignacionMaterial,
       (SELECT COUNT(*) FROM Tarjetas t WHERE t.IdItem = inv.IdItem) AS TarjetasHistoricas
FROM InventarioFisico inv
JOIN CatalogoMateriales c ON c.NNE = inv.NNE
ORDER BY TarjetasHistoricas DESC;
GO

/* ---------- 8) CASE + función de fecha ----------
   Clasificacion de vencimiento de cada elemento. */
SELECT inv.IdItem, c.DesignacionMaterial, inv.FechaVencimientoItem,
       CASE
           WHEN inv.FechaVencimientoItem IS NULL                        THEN N'Sin vencimiento'
           WHEN inv.FechaVencimientoItem < CAST(SYSDATETIME() AS DATE)  THEN N'VENCIDO'
           WHEN dbo.fn_DiasParaVencer(inv.IdItem) <= 180                THEN N'Por vencer (<=6 meses)'
           ELSE N'Vigente'
       END AS Situacion
FROM InventarioFisico inv
JOIN CatalogoMateriales c ON c.NNE = inv.NNE
ORDER BY inv.FechaVencimientoItem;
GO

/* ---------- 9) Vistas ---------- */
SELECT * FROM vw_elementos_afuera   ORDER BY DiasAfuera DESC;
SELECT * FROM vw_stock_disponible   ORDER BY DesignacionMaterial;
-- historial de un elemento que tuvo mas de una tarjeta (cambio de estado o baja):
SELECT * FROM vw_historial_tarjetas
WHERE IdItem IN (SELECT IdItem FROM Tarjetas GROUP BY IdItem HAVING COUNT(*) > 1)
ORDER BY IdItem, FechaEmisionTarjeta;
SELECT * FROM vw_elementos_vencidos;
GO

/* ---------- 10) Procedimiento con CURSOR ----------
   Reporte de salidas vencidas (imprime por consola y devuelve el listado). */
EXEC sp_ReporteSalidasVencidas;
GO

/* ---------- 11) Prueba de las reglas de negocio (deben FALLAR a propósito) ----------
   Descomentar de a una para mostrar que las validaciones funcionan.

   -- Doble salida abierta del mismo elemento (item 1 ya esta afuera):
   -- EXEC sp_RegistrarSalida @IdItem=1, @CodigoMotivo='PRESTAMO';

   -- Reactivar un elemento dado de baja (item 6 esta en BAJA):
   -- EXEC sp_CambiarEstado @IdItem=6, @CodigoEstado='EN_SERVICIO';

   -- Borrar un estado en uso (lo impide el trigger INSTEAD OF):
   -- DELETE FROM EstadosElemento WHERE CodigoEstadoElemento='EN_SERVICIO';
*/
