# Resumen para defender el SQL (version para copiar a mano)

Motor: Microsoft SQL Server (lenguaje T-SQL). Un solo archivo,
script_completo.sql, que corre de arriba a abajo en 6 partes. Dominio:
deposito de aeropartes. Esta hoja resume lo esencial; la version larga
es GUIA_DEFENSA_SQL.md.

---

## 0. Mapa del dominio

INTUICION: el catalogo dice "que es" un material; el inventario es cada
ejemplar real; la tarjeta activa dice en que estado esta cada ejemplar.

```
 TiposElemento --> CatalogoMateriales --(1:N)--> InventarioFisico
                        | (N:N con                    |
                        |  SistemasArmas)        +----+----+----+
                        v                        |    |    |
          MaterialesSistemasArmas      Tarjetas  Salidas  Movim.
```

- CatalogoMateriales: ficha del material, clave natural NNE.
- InventarioFisico: cada ejemplar fisico (IdItem). IdUbicacion NULL = afuera.
- Tarjetas: una activa por ejemplar; su estado es el estado del ejemplar.
- Salidas: retiros del deposito (prestamo/reparacion/inspeccion/baja).
- MovimientosInventario: bitacora. Usuarios/Ubicaciones/etc.: catalogos.

---

## 1. Fundamentos (T-SQL al lado de Programacion II)

- `@nombre` es una VARIABLE. `DECLARE @x INT;` = declarar; `SET @x = 5;` = asignar.
- `GO` separa LOTES (batches). No es T-SQL: es un separador del cliente.
  Las variables no cruzan un `GO`.
- Tipos: `INT` entero, `VARCHAR(n)` texto, `DATE` fecha, `DATETIME2(0)`
  fecha+hora, `BIT` 0/1 (booleano).
- `NULL` = dato ausente. Logica de 3 valores: `NULL = NULL` no da
  verdadero, da desconocido. Por eso se usa `IS NULL` / `IS NOT NULL`.
- `IDENTITY(1,1)` = la columna se autonumera (1,2,3...). No reusa numeros borrados.
- `dbo.` es el esquema; las funciones escalares se invocan como `dbo.fn_...`.
- `-- esto es un comentario`.

| Programacion II | T-SQL |
|---|---|
| variable | `@x` (`DECLARE`/`SET`) |
| funcion / metodo | `CREATE FUNCTION` / `CREATE PROCEDURE` |
| parametro | `@param` |
| valor de retorno | `RETURN` (funcion) / parametro `OUTPUT` (proc) |
| if/else | `IF` / `CASE` |
| cast de tipo | `CAST` / `TRY_CAST` |
| pasar por referencia | parametro `OUTPUT` |

---

## 2. Tablas, claves y restricciones

- PRIMARY KEY (PK): identifica de forma unica cada fila.
  - Surrogate: `INT IDENTITY(1,1) PRIMARY KEY` (numero artificial). Ej Usuarios.
  - Natural: una columna real ya unica. Ej `NNE` en CatalogoMateriales.
  - Compuesta: dos columnas juntas. Ej `PRIMARY KEY (IdSistemaArmas, NNE)`
    en la N:N (un par no se repite).
- UNIQUE (clave alternativa, AK): no se repite, pero no es la PK.
  Ej `CONSTRAINT UQ_TiposElemento_Nombre UNIQUE (NombreTipoElemento)`.
- NOT NULL: la columna es obligatoria.
- CHECK: regla de dominio que el motor valida en cada INSERT/UPDATE.
  - `CHECK (LEN(codigo) > 0)`: no vacio.
  - ATA: `CHECK (ATAMaterial IS NULL OR (TRY_CAST(ATAMaterial AS INT)
    IS NOT NULL AND TRY_CAST(...) BETWEEN 0 AND 99))`. O sea: numerico y 0-99.
    `TRY_CAST` intenta convertir y devuelve NULL si no puede (no rompe).
  - Fechas: `CHECK (FechaRetornoSalida IS NULL OR FechaRetornoSalida
    >= FechaSalida)`: el retorno no puede ser anterior a la salida.
- FOREIGN KEY (FK): la columna apunta a la PK de otra tabla.
  `CONSTRAINT FK_x FOREIGN KEY (col) REFERENCES Tabla(col)`. El nombre
  sirve para que el error diga cual regla se rompio.
- ON DELETE (que pasa con los hijos si borras el padre):

```
 borro el padre (CatalogoMateriales NNE-1)

 CASCADE   --> se borran los hijos tambien (InventarioFisico de ese NNE)
 SET NULL  --> el hijo queda con su FK en NULL (ej IdUsuario)
 NO ACTION --> el motor RECHAZA el borrado si hay hijos (default)
```

- DEFAULT: valor que pone el motor si no se especifica.
  Ej `FechaSalida DATETIME2(0) DEFAULT SYSDATETIME()`, `ActivaTarjeta BIT DEFAULT 1`.
- `DROP ... IF EXISTS` al inicio: borra los objetos si ya existen, en
  orden inverso de dependencias (primero hijos, luego padres). Asi el
  script se puede correr muchas veces sin error de "ya existe".

---

## 3. Programabilidad (lo que mas te preguntan)

### 3.1 Funcion escalar  fn_EstadoActual

INTUICION: una cuenta con nombre que recibe datos y devuelve UN valor
(como una funcion en Programacion II).

```
CREATE FUNCTION fn_EstadoActual (@IdItem INT) RETURNS VARCHAR(30)
AS BEGIN
   DECLARE @cod VARCHAR(30);
   SELECT @cod = EstadosElemento.CodigoEstadoElemento
   FROM Tarjetas JOIN EstadosElemento ON ...
   WHERE Tarjetas.IdItem = @IdItem AND Tarjetas.ActivaTarjeta = 1;
   RETURN @cod;          -- devuelve NULL si no tiene tarjeta activa
END;
```

- Recibe un IdItem y devuelve el codigo de estado de su tarjeta ACTIVA.
- Se invoca con `dbo.fn_EstadoActual(IdItem)`. La usan una vista y una consulta.

### 3.2 Triggers  (codigo que se dispara solo ante un evento)

Pseudo-tablas: dentro del trigger, `inserted` tiene las filas que se
insertaron y `deleted` las que se borraron.

- AFTER INSERT `trg_salida_abre_saca_del_deposito` (sobre Salidas):
  cuando se inserta una salida SIN fecha de retorno, pone
  `IdUbicacion = NULL` en el ejemplar (queda afuera).
  Corre DESPUES de la operacion.

- INSTEAD OF DELETE `trg_estado_no_borrar` (sobre EstadosElemento):
  corre EN LUGAR del borrado. Si el estado esta en uso por alguna
  tarjeta, hace `THROW 50002` y NO borra; si no, hace el DELETE real.

```
 AFTER      : pasa la operacion, despues corre el trigger.
 INSTEAD OF : el trigger reemplaza la operacion; el borrado solo
              ocurre si el trigger lo ejecuta a mano.
```

### 3.3 Procedimiento  sp_AltaElemento  (el mas importante)

INTUICION: subrutina con nombre que agrupa varios pasos en una unidad
"todo o nada". Da de alta un ejemplar + su primera tarjeta.

- Parametros: varios con `= NULL` (opcionales) y `@IdItem INT OUTPUT`.
  OUTPUT = parametro de salida: el proc escribe ahi y el valor vuelve al
  que lo llamo (pasaje por referencia).
- TRANSACCION: grupo de operaciones que el motor trata como una unidad.
  ACID = Atomicidad (todo o nada), Consistencia, Aislamiento, Durabilidad.
- SCOPE_IDENTITY(): devuelve el ultimo id autonumerado generado en este
  mismo ambito; se guarda en `@IdItem` y se reusa para la tarjeta.

```
 BEGIN TRY
   IF NOT EXISTS (... NNE ...) THROW 50010,'no existe',1;  -- valida
   BEGIN TRANSACTION
     INSERT InventarioFisico ...          -- genera IDENTITY
     SET @IdItem = SCOPE_IDENTITY()       -- captura el id nuevo
     INSERT Tarjetas (IdItem=@IdItem, EN_SERVICIO, Activa=1)
   COMMIT                            -- recien aca es permanente
 END TRY
 BEGIN CATCH
   IF @@TRANCOUNT > 0 ROLLBACK   -- si fallo, deshace TODO
   THROW;                        -- re-lanza el error al llamador
 END CATCH
```

POR QUE el TRY/CATCH envuelve la transaccion: por atomicidad. Si el
segundo INSERT (la tarjeta) falla, el CATCH hace ROLLBACK y tambien se
deshace el primero (el ejemplar). No queda un ejemplar sin tarjeta
(fila huerfana). `@@TRANCOUNT` es el contador de transacciones abiertas.

---

## 4. CRUD por tabla (un patron repetido)

Por cada tabla hay 2 procedimientos: Insert y Read (la consigna pide al
menos 2 por tabla).

- Insert: parametros = columnas; `INSERT ... VALUES`; devuelve el id
  nuevo por `OUTPUT` con `SCOPE_IDENTITY()`.
- Read: `WHERE (@p IS NULL OR col = @p)`. Si no pasas filtro (@p = NULL),
  la condicion es verdadera para toda fila -> trae TODO. Si pasas un
  valor, filtra por ese.

Variantes: el de catalogo no usa SCOPE_IDENTITY (la clave NNE la trae el
usuario); el de la N:N no tiene OUTPUT (clave compuesta).

---

## 5. Vistas

INTUICION: una vista es una CONSULTA GUARDADA (tabla virtual). No guarda
datos propios; se recalcula al consultarla.

- `vw_stock_disponible`: ejemplares EN_SERVICIO y dentro del deposito
  (`fn_EstadoActual(...) = 'EN_SERVICIO'` y `IdUbicacion IS NOT NULL`).
- `vw_historial_tarjetas`: todas las tarjetas de cada ejemplar, con su estado.

---

## 6. Consultas de demostracion (Parte 6)

| # | Tecnica | Que hace |
|---|---|---|
| 1 | GROUP BY + HAVING | cantidad por estado, solo grupos con mas de 1 |
| 2 | NOT EXISTS | ejemplares que nunca salieron |
| 3 | EXISTS | ubicaciones con al menos un ejemplar |
| 4 | UNION | lista unica de personas de 3 origenes |
| 5 | INTERSECT | NNE en inventario Y en sistemas de armas |
| 6 | EXCEPT | NNE del catalogo sin ejemplares |
| 7 | subconsulta correlacionada | cuantas tarjetas tuvo cada ejemplar |
| 8 | CASE + DATEDIFF | clasifica vencimiento (vencido/por vencer/vigente) |
| 9 | vistas | consulta las dos vistas |
| 10 | JOIN / LEFT JOIN | ejemplar + material + ubicacion (LEFT: los de afuera) |
| 11 | GROUP BY | materiales por tipo |

- WHERE filtra filas; HAVING filtra grupos (despues del GROUP BY).
- EXISTS pregunta "hay alguna fila que..."; se parece a IN pero corta al primer match.
- UNION quita duplicados; UNION ALL no (mas rapido).
- CASE WHEN ... THEN ... ELSE ... END es un if/else dentro de la consulta.

### Pruebas (operaciones invalidas que el motor rechaza, van comentadas)

| Operacion invalida | Que la frena |
|---|---|
| texto en columna numerica (INT) | error de conversion (tipo) |
| ATA = 150 (fuera de 0-99) | CHECK CHK_CatalogoMateriales_ATA |
| ATA = 'ABC' (no numerico) | el mismo CHECK |
| retorno anterior a la salida | CHECK CHK_Salidas_RetornoPosterior |
| borrar un estado en uso | trigger trg_estado_no_borrar (THROW) |

---

## Preguntas tipicas (respuesta de una linea)

- Que es una transaccion: grupo de operaciones todo-o-nada; o se confirman todas o ninguna.
- Por que TRY/CATCH con la transaccion: si un paso falla, el CATCH hace ROLLBACK y no queda trabajo a medias.
- AFTER vs INSTEAD OF: AFTER corre despues; INSTEAD OF reemplaza la operacion.
- Que son inserted/deleted: pseudo-tablas con las filas insertadas/borradas dentro del trigger.
- SCOPE_IDENTITY: el ultimo id autonumerado generado en este ambito.
- Que es OUTPUT: parametro de salida; el proc devuelve un valor por el (por referencia).
- PK natural vs surrogate: natural es una columna real unica (NNE); surrogate es un numero artificial (IDENTITY).
- Las 3 politicas ON DELETE: CASCADE borra hijos; SET NULL pone su FK en NULL; NO ACTION rechaza el borrado.
- Que es una vista: una consulta guardada; no guarda datos, se recalcula.
- EXISTS vs IN: ambos verifican pertenencia; EXISTS corta al primer match.
- UNION vs UNION ALL: UNION quita duplicados, UNION ALL no.
- Por que ATA es VARCHAR con CHECK numerico: es un codigo; el CHECK obliga a que sea numero 0-99.
- Que hace GO: separa lotes; las variables no cruzan un GO.

---

## Glosario (15 terminos)

- Tabla: filas y columnas. Fila = registro. Columna = campo.
- PK: clave primaria, identifica la fila. FK: clave foranea, apunta a otra tabla.
- UNIQUE / AK: no se repite, pero no es la PK.
- CHECK: regla de dominio validada por el motor.
- IDENTITY: columna autonumerada.
- NULL: dato ausente.
- Variable (@x): valor temporal en memoria.
- Funcion escalar: devuelve un unico valor.
- Procedimiento (sp_): subrutina con parametros; puede tener OUTPUT.
- Trigger: codigo que se dispara solo ante INSERT/UPDATE/DELETE.
- inserted / deleted: filas afectadas, vistas dentro del trigger.
- Transaccion: unidad todo-o-nada (ACID).
- COMMIT / ROLLBACK: confirmar / deshacer la transaccion.
- THROW: lanzar un error.
- Vista (vw_): consulta guardada (tabla virtual).
