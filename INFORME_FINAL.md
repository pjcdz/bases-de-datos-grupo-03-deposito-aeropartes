# Informe Final — Trabajo Práctico Integrador

> Documento base. Las secciones técnicas están redactadas; las de proceso (SCRUM, roles,
> cronograma) están marcadas con **`[COMPLETAR EQUIPO]`**. Pasar a `.docx`/PDF para la entrega.

---

## Portada
`[COMPLETAR EQUIPO]`
- **Título:** Sistema de Gestión de Material — Depósito de Aeropartes
- **Materia:** Ingeniería de Datos I — **Docente:** Ing. Franco Emanuel Salazar — **UADE**
- **Equipo / Grupo 03:** `[integrantes y roles SCRUM]`
- **Fecha:** `[fecha de entrega]`

---

## 1. Resumen ejecutivo
Se diseñó e implementó una base de datos relacional en Microsoft SQL Server para gestionar el
material de un depósito de aeropartes (control de inventario, estados, ubicaciones, salidas y
trazabilidad). El modelo está normalizado a 3FN (12 tablas) e incluye lógica de negocio en el
servidor: funciones, triggers, procedimientos almacenados (CRUD + negocio), un cursor y vistas.
La solución resuelve el control del ciclo de vida de cada elemento: alta, cambios de estado
mediante tarjetas, retiros/retornos del depósito y baja definitiva, con reglas de integridad
garantizadas por la base.

## 2. Introducción y contexto
En un depósito de aeropartes (basado en el Taller G.T.1, I Brigada Aérea) cada elemento —una
agroparte, una herramienta o un instrumento— se controla con una **tarjeta física** que indica su
estado (verde = en servicio, blanca = en servicio transitorio, baja). Los elementos no siempre
están en el depósito: se prestan, se envían a reparación o inspección, o se dan de baja. El
problema es llevar de forma confiable el inventario, el estado vigente de cada elemento, su
historial y su ubicación (dentro o fuera del depósito). Una planilla manual genera datos
contradictorios y pérdida de trazabilidad; una base de datos relacional normalizada resuelve la
integridad y permite consultas y reportes.

## 3. Objetivos del sistema

### 3.1 Objetivos funcionales
- Registrar el catálogo de materiales (NNE, designación, tipo) y sus ejemplares físicos.
- Mantener el estado vigente de cada elemento mediante tarjetas, conservando el historial completo.
- Registrar retiros del depósito (préstamo, reparación, inspección, baja) y sus retornos.
- Saber en todo momento qué está disponible, qué está afuera y desde cuándo.
- Generar reportes (salidas vencidas, elementos vencidos, stock disponible, historial).
- Ofrecer operaciones CRUD sobre todas las entidades.

### 3.2 Objetivos no funcionales
- **Integridad:** reglas garantizadas por la base (PK/FK, CHECK, índices únicos filtrados, triggers).
- **Consistencia:** una sola tarjeta activa por elemento y una sola salida abierta por elemento.
- **Mantenibilidad:** modelo normalizado (3FN), lógica encapsulada en procedimientos y funciones.
- **Rendimiento:** índices sobre claves foráneas y columnas filtradas.
- **Trazabilidad / auditoría:** bitácora de movimientos por elemento.
- **Portabilidad:** Transact-SQL estándar de SQL Server; scripts ejecutables en orden.

## 4. Diseño de la Base de Datos

### 4.1 Modelo conceptual
Entidades principales: **CATÁLOGO** (qué es el material), **INVENTARIO** (el ejemplar físico),
**TARJETA** (estado + historial), **UBICACIÓN**, **SALIDA** (retiro), y catálogos auxiliares
(TIPO, ESTADO, MOTIVO, SISTEMA DE ARMAS, USUARIO). Relaciones clave: un catálogo tiene muchos
ejemplares; un ejemplar tiene muchas tarjetas (una activa); un ejemplar tiene muchas salidas; un
material es compatible con muchos sistemas de armas (N:N).

### 4.2 Modelo lógico
Ver diagrama entidad-relación en **`modelo_logico.mermaid`** (DER con cardinalidades).

### 4.3 Modelo físico
Implementado en **`gestion_material.sql`** (DDL: tablas, tipos, restricciones, índices). Detalle
de cada atributo en **`DICCIONARIO_DATOS.md`**.

### 4.4 Diccionario de datos
Ver **`DICCIONARIO_DATOS.md`** (una fila por atributo: tipo, nulabilidad, clave, dominio, referencia).

## 5. Dependencias funcionales y Normalización
El análisis completo de dependencias funcionales y la justificación de que todas las tablas están
en **3FN** se encuentra en **`NORMALIZACION.md`**. Puntos destacados:
- N:N material–sistema resuelto con tabla intermedia `MaterialesSistemasArmas` (1FN).
- Sin dependencias parciales (única clave compuesta es relación todo-clave) (2FN).
- Sin dependencias transitivas: designación, estado y Nº de parte/serie no se duplican, se derivan (3FN).

## 6. Plan de Desarrollo (metodología y cronograma)
`[COMPLETAR EQUIPO]` — Metodología SCRUM: roles del equipo, backlog de producto, Sprints de 7 días,
dailies, revisiones y retrospectivas. Cronograma de Sprints y tablero (Trello).

## 7. Implementación técnica (resumen de scripts)
| Archivo | Contenido |
|---|---|
| `gestion_material.sql` | Esquema: 12 tablas en 3FN, restricciones, índices, datos semilla |
| `02_programabilidad.sql` | 3 funciones, 4 triggers (AFTER + INSTEAD OF), 5 procedimientos de negocio, 1 cursor |
| `03_crud.sql` | Procedimientos CRUD (Insert/Read/Update/Delete) para cada tabla |
| `04_vistas.sql` | 4 vistas |
| `05_datos_ejemplo.sql` | Datos de prueba (≥10 filas por tabla) |
| `06_consultas_demostracion.sql` | 11 consultas (JOINs, subconsultas, agregados, conjuntos) |

**Evidencia de calidad:** los 6 scripts fueron ejecutados de extremo a extremo sobre el motor de
SQL Server, verificando que todo crea correctamente, que las 11 consultas devuelven resultados
coherentes y que las reglas de negocio rechazan operaciones inválidas (doble salida, reactivar una
baja, borrar un estado en uso, motivo inexistente, CHECK de fechas).

## 8. Conclusiones
El modelo relacional normalizado, combinado con lógica en el servidor (triggers, procedimientos,
funciones, cursor) y restricciones declarativas, garantiza la integridad del inventario sin
depender de la aplicación cliente. La separación catálogo/ejemplar/tarjeta refleja fielmente la
realidad del depósito y habilita el historial y la trazabilidad. `[COMPLETAR EQUIPO: aprendizajes
del trabajo en equipo y la metodología ágil.]`

## 9. Referencias y anexos
- Scripts SQL: `gestion_material.sql`, `02_programabilidad.sql` … `06_consultas_demostracion.sql`.
- Diagrama: `modelo_logico.mermaid`. Diccionario: `DICCIONARIO_DATOS.md`. Normalización: `NORMALIZACION.md`.
- Instrucciones de ejecución: `README.md`.
- `[COMPLETAR EQUIPO: capturas de pantalla de la ejecución, tablero SCRUM, etc.]`
