/* ============================================================================
   ARCHIVO 04 de 05 — DATOS DE EJEMPLO
   Requiere 01, 02 y 03. Carga datos realistas y ejercita los procedimientos y
   triggers (alta, salida, retorno, cambio de estado, baja, salida vencida).
   ============================================================================ */

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* ---------- Maestros ---------- */
INSERT INTO usuario (nombre, apellido, rol) VALUES
    (N'Pablo',  N'Cardozo', N'Encargado de depósito'),
    (N'Ana',    N'Gómez',   N'Cargador de datos'),
    (N'Luis',   N'Pérez',   N'Inspector');
GO

INSERT INTO tipo_elemento (nombre) VALUES
    (N'Componente rotable'),
    (N'Herramienta'),
    (N'Consumible'),
    (N'Instrumento');
GO

INSERT INTO sistema_armas (codigo, modelo) VALUES
    (N'PUC-A', N'Pucará IA-58'),
    (N'HER-B', N'Hércules C-130'),
    (N'PAM-T', N'Pampa IA-63');
GO

INSERT INTO ubicacion (deposito, sector, mapa_highlight) VALUES
    (N'Depósito Central',   N'Estantería A', N'A-01'),
    (N'Depósito Central',   N'Estantería B', N'B-04'),
    (N'Pañol Herramientas', N'Sector 1',     N'PH-1');
GO

/* ---------- Catálogo ---------- */
INSERT INTO catalogo_material (NNE, NREF, designacion, ATA, id_tipo_elemento, id_usuario) VALUES
    (N'1560-AR-001', N'PN-7788', N'Bomba hidráulica',       N'29', 1, 1),
    (N'2620-AR-014', N'PN-1042', N'Válvula de combustible', N'28', 1, 1),
    (N'5120-AR-220', N'TL-3360', N'Llave dinamométrica',    N'00', 2, 2),
    (N'6610-AR-007', N'IN-9001', N'Altímetro',              N'34', 4, 1),
    (N'2915-AR-033', N'PN-5521', N'Actuador de tren',       N'32', 1, 2),
    (N'4710-AR-099', N'PN-3030', N'Manguera de oxígeno',    N'35', 3, 2);  -- sin ejemplares (para EXCEPT)
GO

/* ---------- Compatibilidad material ↔ sistema de armas (N:N) ---------- */
DECLARE @s_puc INT = (SELECT id_sist_armas FROM sistema_armas WHERE codigo='PUC-A');
DECLARE @s_her INT = (SELECT id_sist_armas FROM sistema_armas WHERE codigo='HER-B');
DECLARE @s_pam INT = (SELECT id_sist_armas FROM sistema_armas WHERE codigo='PAM-T');

INSERT INTO material_sist_armas (id_sist_armas, NNE) VALUES
    (@s_puc, N'1560-AR-001'),
    (@s_puc, N'2915-AR-033'),
    (@s_her, N'1560-AR-001'),
    (@s_her, N'6610-AR-007'),
    (@s_pam, N'2620-AR-014');
GO

/* ---------- Ejemplares físicos (vía procedimiento) + movimientos ---------- */
DECLARE @i1 INT, @i2 INT, @i3 INT, @i4 INT, @i5 INT, @i6 INT;

EXEC sp_AltaElemento @NNE=N'1560-AR-001', @n_serie=N'SN-BH-001', @id_ubicacion=1, @vencimiento='2027-03-01', @inspector=N'Luis Pérez', @id_item=@i1 OUTPUT;
EXEC sp_AltaElemento @NNE=N'1560-AR-001', @n_serie=N'SN-BH-002', @id_ubicacion=1, @vencimiento='2024-01-15', @inspector=N'Luis Pérez', @id_item=@i2 OUTPUT;  -- vencido
EXEC sp_AltaElemento @NNE=N'2620-AR-014', @n_serie=N'SN-VC-010', @id_ubicacion=2, @id_item=@i3 OUTPUT;
EXEC sp_AltaElemento @NNE=N'5120-AR-220', @n_serie=N'SN-LL-100', @id_ubicacion=3, @tamano=N'1/2 pulgada', @id_item=@i4 OUTPUT;
EXEC sp_AltaElemento @NNE=N'6610-AR-007', @n_serie=N'SN-AL-050', @id_ubicacion=2, @vencimiento='2026-12-31', @id_item=@i5 OUTPUT;
EXEC sp_AltaElemento @NNE=N'2915-AR-033', @n_serie=N'SN-AC-077', @id_ubicacion=1, @id_item=@i6 OUTPUT;

/* Préstamo vigente (i3 sale del depósito; retorno previsto futuro) */
EXEC sp_RegistrarSalida @id_item=@i3, @codigo_motivo=N'PRESTAMO',
     @destino=N'Escuadrón Técnico', @retirado_por=N'Sgto. Díaz', @fecha_prevista_retorno='2026-09-30';

/* Reparación y posterior retorno (i4 sale y vuelve, reubicado) */
EXEC sp_RegistrarSalida @id_item=@i4, @codigo_motivo=N'REPARACION',
     @destino=N'Taller Hidráulica', @retirado_por=N'Cabo Ruiz', @fecha_prevista_retorno='2026-07-15';

DECLARE @sal_i4 INT = (SELECT id_salida FROM salida WHERE id_item=@i4 AND fecha_retorno IS NULL);
EXEC sp_RegistrarRetorno @id_salida=@sal_i4, @id_ubicacion=3, @id_usuario_registra=1;

/* Cambio de estado a "en servicio transitorio" (tarjeta blanca) — i5 */
EXEC sp_CambiarEstado @id_item=@i5, @codigo_estado=N'EN_SERVICIO_TRANSITORIO',
     @ot=N'OT-2026-441', @causas=N'Lectura errática en banco', @inspector=N'Luis Pérez',
     @nro_tarjeta=N'B-00231';

/* Baja definitiva — i6 (el trigger genera la tarjeta BAJA automáticamente) */
EXEC sp_RegistrarSalida @id_item=@i6, @codigo_motivo=N'BAJA',
     @destino=N'Rezago', @retirado_por=N'Pablo Cardozo', @observaciones=N'Daño irreparable';

/* Salida VENCIDA (carga histórica directa para el reporte por cursor):
   i1 prestado con fecha de retorno prevista ya pasada. */
DECLARE @m_prestamo INT = (SELECT id_motivo FROM motivo_salida WHERE codigo='PRESTAMO');
INSERT INTO salida (id_item, id_motivo, destino, retirado_por, fecha_salida, fecha_prevista_retorno)
VALUES (@i1, @m_prestamo, N'Banco de pruebas', N'Cabo Ruiz', '2025-09-01T08:00:00', '2025-09-20');
GO

PRINT '04 - Datos de ejemplo cargados correctamente.';
GO
