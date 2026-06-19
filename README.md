# Sistema de Gestión de Material — Depósito de Aeropartes

Proyecto final de Bases de Datos — Grupo 03. Modela el control de material de un
depósito de aeropartes (I Brigada Aérea — Taller G.T.1): catálogo, inventario
físico, tarjetas de estado, ubicaciones, salidas/retornos y trazabilidad.

Motor: **Microsoft SQL Server (Transact-SQL)**.

## Orden de ejecución

Ejecutar los scripts **en orden** (cada uno depende del anterior):

| # | Archivo | Contenido |
|---|---|---|
| 01 | `gestion_material.sql` | Esquema: tablas, restricciones, índices, datos semilla |
| 02 | `02_programabilidad.sql` | Funciones, triggers, procedimientos, cursor |
| 03 | `03_vistas.sql` | Vistas |
| 04 | `04_datos_ejemplo.sql` | Datos de prueba (carga vía procedimientos) |
| 05 | `05_consultas_demostracion.sql` | Consultas de demostración (correr una por una) |

> En SSMS / Azure Data Studio: abrir cada archivo y ejecutar (F5). Para crear una base
> nueva, descomentar el bloque `CREATE DATABASE` al inicio del archivo 01.
>
> **Nota:** las tablas `salida` y `tarjeta` usan **índices únicos filtrados**, que exigen
> `SET QUOTED_IDENTIFIER ON`. Los scripts ya lo activan al inicio. SSMS y Azure Data Studio lo
> tienen ON por defecto; si se ejecutan sentencias sueltas desde otra herramienta, anteponer
> `SET QUOTED_IDENTIFIER ON;`.

> **Verificado:** los 5 scripts se probaron de punta a punta sobre el motor de SQL Server
> (incluye triggers, procedimientos, cursor, vistas, las 11 consultas demo y el rechazo correcto
> de las 6 operaciones inválidas: doble salida, reactivar baja, borrar estado en uso, motivo
> inexistente y CHECK de fechas).

## Documentación

- **`modelo_logico.mermaid`** — diagrama entidad-relación (DER).
- **`NORMALIZACION.md`** — análisis de dependencias funcionales y prueba de 3FN.
- **`DECISIONES_EQUIPO.md`** — decisiones de diseño y preguntas abiertas del equipo.

## Cobertura de los temas de la materia

| Tema | Dónde se demuestra |
|---|---|
| Modelo relacional, claves (PK/FK/alternativas) | esquema completo (01) |
| Integridad: dominio, entidad, referencial, **transiciones** | CHECK, PK, FK, trigger `trg_tarjeta_no_reactiva_baja` |
| Restricciones (PK, FK, UNIQUE, NOT NULL, CHECK) | 01 |
| Políticas de FK (CASCADE / SET NULL / NO ACTION) | FKs en 01 |
| Relación N:N con tabla intermedia | `material_sist_armas` |
| Normalización 1FN / 2FN / 3FN + dependencias funcionales | `NORMALIZACION.md` |
| Índices | índices sobre FKs y únicos filtrados (01) |
| Funciones escalares | `fn_DiasFueraDeposito`, `fn_EstadoActual`, `fn_DiasParaVencer` (02) |
| **Triggers** AFTER e INSTEAD OF (INSERTED/DELETED, ROLLBACK) | 4 triggers en 02 |
| Procedimientos almacenados (parámetros IN/OUT, transacciones, TRY/CATCH) | 4 procedimientos en 02 |
| **Cursor** (DECLARE/OPEN/FETCH/CLOSE/DEALLOCATE) | `sp_ReporteSalidasVencidas` (02) |
| Vistas | 4 vistas (03) |
| Operaciones de conjunto (UNION / INTERSECT / EXCEPT) | 05 |
| Subconsultas (EXISTS / NOT EXISTS / correlacionada) | 05 |
| GROUP BY / HAVING | 05 |
| Funciones (CASE, fechas) | 05 |

## Modelo en una frase

El **catálogo** describe *qué es* cada material; el **inventario físico** es cada *ejemplar real*;
la **tarjeta** activa porta su *estado* (verde / blanca / baja) y guarda el historial; las
**salidas** registran cada retiro del depósito (préstamo, reparación, inspección, baja) y su
retorno. Un elemento con `id_ubicacion = NULL` está fuera del depósito.
