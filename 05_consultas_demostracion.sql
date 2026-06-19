/* ============================================================================
   ARCHIVO 05 de 05 — CONSULTAS DE DEMOSTRACIÓN
   Requiere 01..04. Pensado para correr consulta por consulta en la defensa.
   Cada bloque demuestra un tema de "SQL Avanzado" de la materia.
   ============================================================================ */

SET QUOTED_IDENTIFIER ON;
GO

/* ---------- 1) GROUP BY + HAVING ----------
   Cantidad de ejemplares por estado actual; solo estados con más de 1 elemento. */
SELECT dbo.fn_EstadoActual(inv.id_item) AS estado, COUNT(*) AS cantidad
FROM inventario_fisico inv
GROUP BY dbo.fn_EstadoActual(inv.id_item)
HAVING COUNT(*) > 1
ORDER BY cantidad DESC;
GO

/* ---------- 2) NOT EXISTS ----------
   Elementos que NUNCA salieron del depósito. */
SELECT inv.id_item, c.designacion, inv.n_serie
FROM inventario_fisico inv
JOIN catalogo_material c ON c.NNE = inv.NNE
WHERE NOT EXISTS (SELECT 1 FROM salida s WHERE s.id_item = inv.id_item);
GO

/* ---------- 3) EXISTS ----------
   Ubicaciones que tienen al menos un elemento actualmente almacenado. */
SELECT u.id_ubicacion, u.deposito, u.sector
FROM ubicacion u
WHERE EXISTS (SELECT 1 FROM inventario_fisico inv WHERE inv.id_ubicacion = u.id_ubicacion);
GO

/* ---------- 4) UNION ----------
   Directorio unificado de personas que aparecen en el sistema, de tres orígenes. */
SELECT CONCAT(nombre, ' ', apellido) AS persona, N'Usuario del sistema' AS origen
FROM usuario
UNION
SELECT DISTINCT inspector, N'Inspector (tarjeta)'
FROM tarjeta WHERE inspector IS NOT NULL
UNION
SELECT DISTINCT retirado_por, N'Retiró material (salida)'
FROM salida WHERE retirado_por IS NOT NULL
ORDER BY persona;
GO

/* ---------- 5) INTERSECT ----------
   NNE que están a la vez en inventario físico y asociados a algún sistema de armas. */
SELECT NNE FROM inventario_fisico
INTERSECT
SELECT NNE FROM material_sist_armas;
GO

/* ---------- 6) EXCEPT ----------
   NNE del catálogo que NO tienen ningún ejemplar cargado en inventario. */
SELECT NNE FROM catalogo_material
EXCEPT
SELECT NNE FROM inventario_fisico;
GO

/* ---------- 7) Subconsulta correlacionada ----------
   Por cada elemento, cuántas tarjetas tuvo (tamaño de su historial). */
SELECT inv.id_item, c.designacion,
       (SELECT COUNT(*) FROM tarjeta t WHERE t.id_item = inv.id_item) AS tarjetas_historicas
FROM inventario_fisico inv
JOIN catalogo_material c ON c.NNE = inv.NNE
ORDER BY tarjetas_historicas DESC;
GO

/* ---------- 8) CASE + función de fecha ----------
   Clasificación de vencimiento de cada elemento. */
SELECT inv.id_item, c.designacion, inv.vencimiento,
       CASE
           WHEN inv.vencimiento IS NULL                         THEN N'Sin vencimiento'
           WHEN inv.vencimiento < CAST(SYSDATETIME() AS DATE)   THEN N'VENCIDO'
           WHEN dbo.fn_DiasParaVencer(inv.id_item) <= 180       THEN N'Por vencer (≤6 meses)'
           ELSE N'Vigente'
       END AS situacion
FROM inventario_fisico inv
JOIN catalogo_material c ON c.NNE = inv.NNE
ORDER BY inv.vencimiento;
GO

/* ---------- 9) Vistas ---------- */
SELECT * FROM vw_elementos_afuera   ORDER BY dias_afuera DESC;
SELECT * FROM vw_stock_disponible   ORDER BY designacion;
SELECT * FROM vw_historial_tarjetas WHERE id_item = 5 ORDER BY fecha_emision;  -- i5: dos tarjetas
SELECT * FROM vw_elementos_vencidos;
GO

/* ---------- 10) Procedimiento con CURSOR ----------
   Reporte de salidas vencidas (imprime por consola y devuelve el listado). */
EXEC sp_ReporteSalidasVencidas;
GO

/* ---------- 11) Prueba de las reglas de negocio (deben FALLAR a propósito) ----------
   Descomentar de a una para mostrar que las validaciones funcionan.

   -- Doble salida abierta del mismo elemento (item 1 ya está afuera):
   -- EXEC sp_RegistrarSalida @id_item=1, @codigo_motivo=N'PRESTAMO';

   -- Reactivar un elemento dado de baja (item 6 está en BAJA):
   -- EXEC sp_CambiarEstado @id_item=6, @codigo_estado=N'EN_SERVICIO';

   -- Borrar un estado en uso (lo impide el trigger INSTEAD OF):
   -- DELETE FROM estado_elemento WHERE codigo='EN_SERVICIO';
*/
