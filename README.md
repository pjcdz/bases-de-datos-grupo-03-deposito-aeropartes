# Sistema de Gestión de Material - Depósito de Aeropartes

Proyecto final de Bases de Datos - Grupo 03. Modela el control de material de un
depósito de aeropartes (I Brigada Aérea - Taller G.T.1): catálogo, inventario
físico, tarjetas de estado, ubicaciones, salidas/retornos y trazabilidad.

Motor: **Microsoft SQL Server (Transact-SQL)**.

## Orden de ejecución

Ejecutar los scripts **en orden** (cada uno depende del anterior):

| # | Archivo | Contenido |
|---|---|---|
| 01 | `gestion_material.sql` | Esquema: tablas, restricciones, datos semilla |
| 02 | `02_programabilidad.sql` | Funciones, triggers, procedimientos de negocio, cursor |
| 03 | `03_crud.sql` | Procedimientos CRUD (Insert/Read/Update/Delete) por tabla |
| 04 | `04_vistas.sql` | Vistas |
| 05 | `05_datos_ejemplo.sql` | Datos de prueba (≥10 filas por tabla, carga vía procedimientos) |
| 06 | `06_consultas_demostracion.sql` | Consultas de demostración (correr una por una) |

> En SSMS / Azure Data Studio: abrir cada archivo y ejecutar (F5). Para crear una base
> nueva, descomentar el bloque `CREATE DATABASE` al inicio del archivo 01.

> **Verificado:** los 6 scripts se probaron de punta a punta sobre el motor de SQL Server
> (incluye CRUD por tabla, triggers, procedimientos, cursor, vistas, las 11 consultas demo y el
> rechazo correcto de las operaciones inválidas: doble salida, reactivar baja, borrar estado en
> uso, motivo inexistente y CHECK de fechas).

## Documentación

- **`modelo_logico.mermaid`** - diagrama entidad-relación (DER).
- **`DICCIONARIO_DATOS.md`** - diccionario de datos (una fila por atributo).
- **`NORMALIZACION.md`** - análisis de dependencias funcionales y prueba de 3FN.
- **`Informe_TP_Grupo3.docx`** - informe final en el formato de la cátedra (documento de entrega).
- **`DECISIONES_EQUIPO.md`** - decisiones de diseño y preguntas abiertas del equipo.

## Cobertura de los temas de la materia

| Tema | Dónde se demuestra |
|---|---|
| Modelo relacional, claves (PK/FK/alternativas) | esquema completo (01) |
| Integridad: dominio, entidad, referencial, **transiciones** | CHECK, PK, FK, trigger `trg_tarjeta_no_reactiva_baja` |
| Restricciones (PK, FK, UNIQUE, NOT NULL, CHECK) | 01 |
| Políticas de FK (CASCADE / SET NULL / NO ACTION) | FKs en 01 |
| Relación N:N con tabla intermedia | `MaterialesSistemasArmas` |
| Normalización 1FN / 2FN / 3FN + dependencias funcionales | `NORMALIZACION.md` |
| Funciones escalares | `fn_DiasFueraDeposito`, `fn_EstadoActual`, `fn_DiasParaVencer` (02) |
| **Triggers** AFTER e INSTEAD OF (INSERTED/DELETED, ROLLBACK) | 4 triggers en 02 |
| Procedimientos de negocio (parámetros IN/OUT, transacciones, TRY/CATCH) | 5 procedimientos en 02 |
| **CRUD por tabla** (Insert/Read/Update/Delete) | `03_crud.sql` (12 tablas) |
| **Cursor** (DECLARE/OPEN/FETCH/CLOSE/DEALLOCATE) | `sp_ReporteSalidasVencidas` (02) |
| Vistas | 4 vistas (04) |
| Datos de prueba (≥10 filas/tabla) | 05 |
| Operaciones de conjunto (UNION / INTERSECT / EXCEPT) | 06 |
| Subconsultas (EXISTS / NOT EXISTS / correlacionada) | 06 |
| GROUP BY / HAVING | 06 |
| Funciones (CASE, fechas) | 06 |

## Modelo en una frase

El **catálogo** (`CatalogoMateriales`) describe *qué es* cada material; el **inventario físico**
(`InventarioFisico`) es cada *ejemplar real*; la **tarjeta** (`Tarjetas`) activa porta su *estado*
(verde / blanca / baja) y guarda el historial; las **salidas** (`Salidas`) registran cada retiro del
depósito (préstamo, reparación, inspección, baja) y su retorno. Un elemento con `IdUbicacion = NULL`
está fuera del depósito.
