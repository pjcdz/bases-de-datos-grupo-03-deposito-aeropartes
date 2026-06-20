/* ============================================================================
   ARCHIVO 05 de 06 - DATOS DE EJEMPLO
   Requiere 01, 02, 03 y 04. Carga datos realistas cumpliendo el minimo de la
   rubrica (>=10 filas por tabla; 3-4 en catalogos fijos chicos como EstadosElemento
   y MotivosSalida, que son semilla de 01). Ejercita procedimientos y triggers.
   ============================================================================ */

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* ---------- Usuarios (12) ---------- */
INSERT INTO Usuarios (NombreUsuario, ApellidoUsuario, RolUsuario) VALUES
    (N'Pablo',   N'Cardozo',   N'Encargado de deposito'),
    (N'Ana',     N'Gómez',     N'Cargador de datos'),
    (N'Luis',    N'Pérez',     N'Inspector'),
    (N'María',   N'López',     N'Jefe de taller'),
    (N'Jorge',   N'Díaz',      N'Logística'),
    (N'Sofía',   N'Ruiz',      N'Inspector'),
    (N'Diego',   N'Fernández', N'Almacenero'),
    (N'Carla',   N'Sosa',      N'Administrativo'),
    (N'Martín',  N'Romero',    N'Supervisor'),
    (N'Lucía',   N'Benítez',   N'Cargador de datos'),
    (N'Pedro',   N'Álvarez',   N'Mecánico'),
    (N'Valeria', N'Castro',    N'Control de calidad');
GO

/* ---------- TiposElemento (10) ---------- */
INSERT INTO TiposElemento (NombreTipoElemento) VALUES
    (N'Componente rotable'), (N'Herramienta'), (N'Consumible'), (N'Instrumento'),
    (N'Componente estructural'), (N'Componente eléctrico'), (N'Componente hidráulico'),
    (N'Componente neumático'), (N'Equipo de seguridad'), (N'Software/firmware');
GO

/* ---------- SistemasArmas / aeronaves (10) ---------- */
INSERT INTO SistemasArmas (CodigoSistemaArmas, ModeloSistemaArmas) VALUES
    ('PUC-A', N'Pucará IA-58'),   ('HER-B', N'Hércules C-130'), ('PAM-T', N'Pampa IA-63'),
    ('TUC-C', N'Tucano EMB-312'), ('MIR-3', N'Mirage III'),     ('SKY-A', N'A-4 Skyhawk'),
    ('BEL-2', N'Bell 212'),       ('SAA-3', N'Saab 340'),       ('TWI-O', N'Twin Otter DHC-6'),
    ('LEA-3', N'Learjet 35');
GO

/* ---------- Ubicaciones (10) ---------- */
INSERT INTO Ubicaciones (DepositoUbicacion, SectorUbicacion, MapaHighlightUbicacion) VALUES
    (N'Depósito Central',     N'Estantería A', N'A-01'),
    (N'Depósito Central',     N'Estantería B', N'B-04'),
    (N'Pañol Herramientas',   N'Sector 1',     N'PH-1'),
    (N'Depósito Central',     N'Estantería C', N'C-02'),
    (N'Depósito Central',     N'Estantería D', N'D-03'),
    (N'Cámara de Frío',       N'Sector 1',     N'CF-1'),
    (N'Sala de Instrumentos', N'Vitrina 1',    N'SI-1'),
    (N'Zona de Cuarentena',   N'Sector Q',     N'QZ-1'),
    (N'Pañol Herramientas',   N'Sector 2',     N'PH-2'),
    (N'Depósito Auxiliar',    N'Estantería E', N'E-05');
GO

/* ---------- CatalogoMateriales (12) ---------- */
INSERT INTO CatalogoMateriales (NNE, NumeroReferenciaMaterial, DesignacionMaterial, ATAMaterial, IdTipoElemento, IdUsuario) VALUES
    (N'1560-AR-001', 'PN-7788', N'Bomba hidráulica',       '29', 7, 1),
    (N'2620-AR-014', 'PN-1042', N'Válvula de combustible', '28', 1, 1),
    (N'5120-AR-220', 'TL-3360', N'Llave dinamométrica',    '00', 2, 2),
    (N'6610-AR-007', 'IN-9001', N'Altímetro',              '34', 4, 1),
    (N'2915-AR-033', 'PN-5521', N'Actuador de tren',       '32', 7, 2),
    (N'4710-AR-099', 'PN-3030', N'Manguera de oxígeno',    '35', 3, 2),   -- sin ejemplares (para EXCEPT)
    (N'2440-AR-051', 'PN-8820', N'Bomba de combustible',   '28', 1, 4),
    (N'2810-AR-066', 'IN-4410', N'Indicador de presión',   '31', 4, 3),
    (N'5340-AR-077', 'HW-2200', N'Juego de bulones',       '51', 3, 5),
    (N'2440-AR-088', 'EL-9300', N'Arnés eléctrico',        '24', 6, 4),
    (N'3210-AR-112', 'PN-1500', N'Conjunto de rueda',      '32', 5, 9),
    (N'1680-AR-130', 'PN-7001', N'Servoválvula',           '27', 7, 9);
GO

/* ---------- Compatibilidad material <-> sistema de armas (N:N) (13) ---------- */
INSERT INTO MaterialesSistemasArmas (IdSistemaArmas, NNE) VALUES
    (1, N'1560-AR-001'), (1, N'2915-AR-033'), (1, N'3210-AR-112'),
    (2, N'1560-AR-001'), (2, N'6610-AR-007'),
    (3, N'2620-AR-014'), (3, N'2810-AR-066'),
    (4, N'2440-AR-051'), (5, N'2440-AR-051'),
    (6, N'2440-AR-088'), (7, N'3210-AR-112'),
    (8, N'1680-AR-130'), (9, N'5340-AR-077');
GO

/* ---------- Ejemplares físicos (15, vía procedimiento) + operaciones ---------- */
DECLARE @i1 INT, @i2 INT, @i3 INT, @i4 INT, @i5 INT, @i6 INT, @i7 INT, @i8 INT,
        @i9 INT, @i10 INT, @i11 INT, @i12 INT, @i13 INT, @i14 INT, @i15 INT, @sal INT;

EXEC sp_AltaElemento @NNE=N'1560-AR-001', @NumeroSerie='SN-BH-001', @IdUbicacion=1,  @FechaVencimiento='2027-03-01', @Inspector=N'Luis Pérez', @IdItem=@i1  OUTPUT;
EXEC sp_AltaElemento @NNE=N'1560-AR-001', @NumeroSerie='SN-BH-002', @IdUbicacion=1,  @FechaVencimiento='2024-01-15', @Inspector=N'Luis Pérez', @IdItem=@i2  OUTPUT;  -- vencido
EXEC sp_AltaElemento @NNE=N'2620-AR-014', @NumeroSerie='SN-VC-010', @IdUbicacion=2,  @IdItem=@i3  OUTPUT;
EXEC sp_AltaElemento @NNE=N'5120-AR-220', @NumeroSerie='SN-LL-100', @IdUbicacion=3,  @Tamano=N'1/2 pulgada', @IdItem=@i4  OUTPUT;
EXEC sp_AltaElemento @NNE=N'6610-AR-007', @NumeroSerie='SN-AL-050', @IdUbicacion=7,  @FechaVencimiento='2026-12-31', @IdItem=@i5  OUTPUT;
EXEC sp_AltaElemento @NNE=N'2915-AR-033', @NumeroSerie='SN-AC-077', @IdUbicacion=1,  @IdItem=@i6  OUTPUT;
EXEC sp_AltaElemento @NNE=N'2440-AR-051', @NumeroSerie='SN-BC-201', @IdUbicacion=2,  @FechaVencimiento='2028-05-01', @IdItem=@i7  OUTPUT;
EXEC sp_AltaElemento @NNE=N'2810-AR-066', @NumeroSerie='SN-IP-300', @IdUbicacion=7,  @IdItem=@i8  OUTPUT;
EXEC sp_AltaElemento @NNE=N'5340-AR-077', @NumeroSerie='SN-JB-400', @IdUbicacion=3,  @IdItem=@i9  OUTPUT;
EXEC sp_AltaElemento @NNE=N'2440-AR-088', @NumeroSerie='SN-AE-500', @IdUbicacion=5,  @FechaVencimiento='2023-09-10', @IdItem=@i10 OUTPUT;  -- vencido
EXEC sp_AltaElemento @NNE=N'3210-AR-112', @NumeroSerie='SN-RU-600', @IdUbicacion=4,  @IdItem=@i11 OUTPUT;
EXEC sp_AltaElemento @NNE=N'1680-AR-130', @NumeroSerie='SN-SV-700', @IdUbicacion=1,  @FechaVencimiento='2027-11-20', @IdItem=@i12 OUTPUT;
EXEC sp_AltaElemento @NNE=N'1560-AR-001', @NumeroSerie='SN-BH-003', @IdUbicacion=4,  @IdItem=@i13 OUTPUT;
EXEC sp_AltaElemento @NNE=N'2620-AR-014', @NumeroSerie='SN-VC-011', @IdUbicacion=2,  @FechaVencimiento='2025-02-01', @IdItem=@i14 OUTPUT;  -- vencido
EXEC sp_AltaElemento @NNE=N'5340-AR-077', @NumeroSerie='SN-JB-401', @IdUbicacion=9,  @IdItem=@i15 OUTPUT;

/* Salidas vigentes (quedan afuera) */
EXEC sp_RegistrarSalida @IdItem=@i3,  @CodigoMotivo='PRESTAMO',   @Destino=N'Escuadrón Técnico',  @RetiradoPor=N'Sgto. Díaz',  @FechaPrevistaRetorno='2026-09-30';
EXEC sp_RegistrarSalida @IdItem=@i8,  @CodigoMotivo='PRESTAMO',   @Destino=N'Escuadrón II',       @RetiradoPor=N'Cabo Núñez',  @FechaPrevistaRetorno='2026-10-10';
EXEC sp_RegistrarSalida @IdItem=@i11, @CodigoMotivo='INSPECCION', @Destino=N'Control de Calidad', @RetiradoPor=N'Sofía Ruiz',  @FechaPrevistaRetorno='2026-09-05';
EXEC sp_RegistrarSalida @IdItem=@i13, @CodigoMotivo='PRESTAMO',   @Destino=N'Escuadrón III',      @RetiradoPor=N'Cabo Ruiz',   @FechaPrevistaRetorno='2026-11-01';

/* Salidas con retorno (reparación / inspección que vuelven) */
EXEC sp_RegistrarSalida @IdItem=@i4,  @CodigoMotivo='REPARACION', @Destino=N'Taller Hidráulica', @RetiradoPor=N'Pedro Álvarez', @FechaPrevistaRetorno='2026-07-15';
SET @sal = (SELECT IdSalida FROM Salidas WHERE IdItem=@i4 AND FechaRetornoSalida IS NULL);
EXEC sp_RegistrarRetorno @IdSalida=@sal, @IdUbicacion=3, @IdUsuarioRegistra=1;

EXEC sp_RegistrarSalida @IdItem=@i7,  @CodigoMotivo='INSPECCION', @Destino=N'Laboratorio', @RetiradoPor=N'Sofía Ruiz', @FechaPrevistaRetorno='2026-08-01';
SET @sal = (SELECT IdSalida FROM Salidas WHERE IdItem=@i7 AND FechaRetornoSalida IS NULL);
EXEC sp_RegistrarRetorno @IdSalida=@sal, @IdUbicacion=2, @IdUsuarioRegistra=5;

EXEC sp_RegistrarSalida @IdItem=@i9,  @CodigoMotivo='REPARACION', @Destino=N'Taller Mecánico', @RetiradoPor=N'Pedro Álvarez', @FechaPrevistaRetorno='2026-07-20';
SET @sal = (SELECT IdSalida FROM Salidas WHERE IdItem=@i9 AND FechaRetornoSalida IS NULL);
EXEC sp_RegistrarRetorno @IdSalida=@sal, @IdUbicacion=3, @IdUsuarioRegistra=5;

EXEC sp_RegistrarSalida @IdItem=@i15, @CodigoMotivo='INSPECCION', @Destino=N'Control de Calidad', @RetiradoPor=N'Valeria Castro', @FechaPrevistaRetorno='2026-08-15';
SET @sal = (SELECT IdSalida FROM Salidas WHERE IdItem=@i15 AND FechaRetornoSalida IS NULL);
EXEC sp_RegistrarRetorno @IdSalida=@sal, @IdUbicacion=9, @IdUsuarioRegistra=1;

/* Cambios de estado a "en servicio transitorio" (tarjeta blanca) */
EXEC sp_CambiarEstado @IdItem=@i5,  @CodigoEstado='EN_SERVICIO_TRANSITORIO', @OrdenTrabajo='OT-2026-441', @Causas=N'Lectura errática en banco',    @Inspector=N'Luis Pérez', @NumeroTarjeta='B-00231';
EXEC sp_CambiarEstado @IdItem=@i14, @CodigoEstado='EN_SERVICIO_TRANSITORIO', @OrdenTrabajo='OT-2026-502', @Causas=N'Pérdida en prueba de presión', @Inspector=N'Sofía Ruiz', @NumeroTarjeta='B-00232';

/* Bajas definitivas (el trigger genera la tarjeta BAJA automáticamente) */
EXEC sp_RegistrarSalida @IdItem=@i6,  @CodigoMotivo='BAJA', @Destino=N'Rezago', @RetiradoPor=N'Pablo Cardozo',    @Observaciones=N'Daño irreparable';
EXEC sp_RegistrarSalida @IdItem=@i10, @CodigoMotivo='BAJA', @Destino=N'Rezago', @RetiradoPor=N'Diego Fernández', @Observaciones=N'Vencido y deteriorado';

/* Salidas históricas VENCIDAS (INSERT directo con fechas pasadas) para el reporte por cursor */
DECLARE @m_prestamo INT   = (SELECT IdMotivoSalida FROM MotivosSalida WHERE CodigoMotivoSalida='PRESTAMO');
DECLARE @m_reparacion INT = (SELECT IdMotivoSalida FROM MotivosSalida WHERE CodigoMotivoSalida='REPARACION');
INSERT INTO Salidas (IdItem, IdMotivoSalida, DestinoSalida, RetiradoPorSalida, FechaSalida, FechaPrevistaRetornoSalida)
VALUES (@i1,  @m_prestamo,  N'Banco de pruebas', N'Cabo Ruiz',     '2025-09-01T08:00:00', '2025-09-20'),
       (@i12, @m_reparacion, N'Taller externo',  N'Pedro Álvarez', '2025-10-01T09:00:00', '2025-10-30');

/* Movimientos de inventario de rutina (recuentos / reubicaciones / controles) */
INSERT INTO MovimientosInventario (IdItem, IdUbicacion, AccionMovimiento, IdUsuarioRegistra, DetalleMovimiento) VALUES
    (@i1,  1, N'ALTA',        1,  N'Ingreso inicial al depósito'),
    (@i2,  1, N'RECUENTO',    2,  N'Recuento mensual'),
    (@i5,  7, N'REUBICACION', 5,  N'Movido a Sala de Instrumentos'),
    (@i7,  2, N'CONTROL',     12, N'Control de calidad OK'),
    (@i9,  3, N'RECUENTO',    7,  N'Recuento trimestral'),
    (@i11, 4, N'ALTA',        1,  N'Ingreso inicial al depósito'),
    (@i12, 1, N'CONTROL',     3,  N'Verificación de servoválvula'),
    (@i13, 4, N'RECUENTO',    10, N'Recuento mensual'),
    (@i14, 2, N'REUBICACION', 9,  N'Reubicado a Estantería B'),
    (@i15, 9, N'ALTA',        1,  N'Ingreso inicial al depósito');
GO

PRINT '05 - Datos de ejemplo cargados correctamente.';
GO
