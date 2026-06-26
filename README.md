# Sistema de Gestión de Material - Depósito de Aeropartes

Proyecto final de Bases de Datos - Grupo 03. Modela el control de material de un
depósito de aeropartes (I Brigada Aérea - Taller G.T.1): catálogo, inventario
físico, tarjetas de estado, ubicaciones, salidas/retornos y trazabilidad.

Motor: **Microsoft SQL Server (Transact-SQL)**.

## Ejecución

Todo el código SQL está en un único archivo: **`script_completo.sql`**. Ejecutarlo de
arriba hacia abajo (en SSMS / Azure Data Studio: abrir y F5). Los lotes se separan con `GO`
y el script está organizado en seis partes, en orden de dependencia:

| Parte | Contenido |
|---|---|
| 01 | Esquema: tablas, restricciones, datos de catálogo |
| 02 | Una función, dos triggers y un procedimiento |
| 03 | Procedimientos CRUD (Insert y Read) por tabla |
| 04 | Vistas |
| 05 | Datos de ejemplo (INSERT directos) |
| 06 | Consultas de demostración y pruebas |

> Para crear una base nueva, descomentar el bloque `CREATE DATABASE` al inicio de la Parte 01
> (o crear la base a mano y ejecutar el script sobre ella).

> **Verificado:** el script se ejecutó de punta a punta sobre el motor de SQL Server (Azure SQL
> Edge), sin errores. Cumple el mínimo pedido por la consigna: 12 tablas en 3FN, 2 procedimientos
> CRUD por tabla, ≥10 filas por tabla (los catálogos chicos tienen 3-4), 11 consultas, 2 triggers,
> 2 vistas, 1 función y 1 procedimiento. Las pruebas de validación quedan comentadas al final de la
> Parte 06 (operaciones inválidas que el motor rechaza: texto en columna numérica, ATA fuera de
> rango, ATA no numérico, fecha de retorno anterior a la salida y borrar un estado en uso).

## Documentación

- **`modelo_logico.mermaid`** - diagrama entidad-relación (DER).
- **`DICCIONARIO_DATOS.md`** - diccionario de datos (una fila por atributo).
- **`NORMALIZACION.md`** - análisis de dependencias funcionales y prueba de 3FN.
- **`Informe_TP_Grupo3.docx`** - informe final en el formato de la cátedra (documento de entrega).
- **`DECISIONES_EQUIPO.md`** - decisiones de diseño y preguntas abiertas del equipo.
- **`GUIA_DEFENSA_SQL.md`** - explicación del script SQL desde cero (conceptos, diagramas ASCII y preguntas típicas) para estudiar y defender.
- **`RESUMEN_DEFENSA_SQL.md`** - version corta del anterior, pensada para copiar a mano y estudiar.

## Cobertura de los temas de la materia

| Tema | Dónde se demuestra |
|---|---|
| Modelo relacional, claves (PK/FK/alternativas) | esquema completo (parte 1) |
| Integridad: dominio, entidad, referencial | CHECK, PK, FK (parte 1) |
| Restricciones (PK, FK, UNIQUE, NOT NULL, CHECK) | parte 1 (incluye `CHK_CatalogoMateriales_ATA`: numérico 0-99, y CHECK de coherencia de fechas) |
| Políticas de FK (CASCADE / SET NULL) | FKs en parte 1 |
| Relación N:N con tabla intermedia | `MaterialesSistemasArmas` |
| Normalización 1FN / 2FN / 3FN + dependencias funcionales | `NORMALIZACION.md` |
| Función escalar | `fn_EstadoActual` (parte 2) |
| Triggers AFTER e INSTEAD OF | `trg_salida_abre_saca_del_deposito`, `trg_estado_no_borrar` (parte 2) |
| Procedimiento (parámetros IN/OUT, transacción, TRY/CATCH) | `sp_AltaElemento` (parte 2) |
| CRUD por tabla (≥2 procedimientos por tabla) | Insert + Read, 12 tablas (parte 3) |
| Vistas | 2 vistas (parte 4) |
| Datos de prueba (≥10 filas/tabla) | parte 5 |
| Operaciones de conjunto (UNION / INTERSECT / EXCEPT) | parte 6 |
| Subconsultas (EXISTS / NOT EXISTS / correlacionada) | parte 6 |
| GROUP BY / HAVING | parte 6 |
| CASE y funciones de fecha | parte 6 |
| Pruebas de validación (operaciones inválidas que se rechazan) | final de la parte 6 (comentadas) |

## Modelo en una frase

El **catálogo** (`CatalogoMateriales`) describe *qué es* cada material; el **inventario físico**
(`InventarioFisico`) es cada *ejemplar real*; la **tarjeta** (`Tarjetas`) activa porta su *estado*
(verde / blanca / baja) y guarda el historial; las **salidas** (`Salidas`) registran cada retiro del
depósito (préstamo, reparación, inspección, baja) y su retorno. Un elemento con `IdUbicacion = NULL`
está fuera del depósito.
