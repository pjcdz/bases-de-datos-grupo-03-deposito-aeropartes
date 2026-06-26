# Guia de defensa: explicacion del SQL desde cero

```
Que es esto
-----------
El motor es Microsoft SQL Server: un programa que guarda datos en
tablas y entiende el lenguaje T-SQL (la variante de SQL de
Microsoft). El TP es un unico archivo, script_completo.sql, que se
ejecuta de arriba hacia abajo en seis partes [L3]. Resuelve el
dominio de un deposito de aeropartes: usuarios, catalogo de
materiales, inventario fisico, tarjetas de estado, movimientos y
salidas. Esta seccion explica la Parte 0: las primitivas del
lenguaje que el resto de la guia da por sabidas.
```

```
Como usar esta guia
-------------------
Etiquetas de texto que vas a encontrar:
  INTUICION:    una frase para entender la idea de fondo.
  FRAME A FRAME un diagrama paso a paso de lo que ocurre.
  DE PROGRA II: el mismo concepto en Programacion II.
  TRAMPA:       un comentario del script que puede confundir.
  QUE TE PUEDEN PREGUNTAR: caja final de preguntas de oral.
Las referencias [L###] apuntan a la linea exacta del script.
```

## Parte 0 - Fundamentos de T-SQL desde cero

Esta es la base que el resto de la guia da por sabida. Cada
primitiva se ensena una sola vez y se ancla a Programacion II. Las
explicaciones son cortas a proposito.

INTUICION: una base relacional es un conjunto de tablas, y una tabla
es una grilla con columnas fijas (que dato) y filas variables (cada
registro).

Un motor relacional guarda la informacion en tablas y garantiza
reglas sobre ellas. Una tabla tiene un nombre, una lista de columnas
con su tipo de dato, y cero o mas filas. En el script, `Usuarios`
[L67] tiene cuatro columnas y cada operario es una fila. El motor es
SQL Server [L3].

```
 Tabla Usuarios
 +-----------+---------------+-----------------+------------+
 | IdUsuario | NombreUsuario | ApellidoUsuario | RolUsuario |
 +-----------+---------------+-----------------+------------+
 | 1         | Ana           | Diaz            | operario   |  <- fila
 | 2         | Luis          | Gomez           | supervisor |  <- fila
 +-----------+---------------+-----------------+------------+
```

INTUICION: el doble guion convierte el resto de la linea en texto
ignorado por el motor; sirve para anotar, no se ejecuta.

Todo lo que sigue a `--` hasta el fin de la linea es un comentario:
el motor no lo lee. El encabezado del archivo lo usa para describir
el TP [L1] y para rotular cada tabla [L66] [L75].

DE PROGRA II: es el `//` de una linea.

INTUICION: `GO` no es una instruccion SQL; es una marca que separa
el script en bloques que se mandan al motor de a uno.

`GO` divide el archivo en lotes (batches). Cada lote se envia y se
compila como una unidad; recien cuando termina uno empieza el
siguiente. Por eso los `DROP` de triggers van en un lote [L15-L17] y
los `DROP` de vistas en otro [L18-L20]: cada objeto debe existir o
no antes de pasar al grupo que depende de el. Cada `CREATE TABLE`
cierra con su `GO` [L73] [L81].

TRAMPA: `GO` lo interpreta la herramienta cliente, no el motor. No
lleva punto y coma y no es T-SQL estandar.

FRAME A FRAME
```
 archivo .sql
   |
   v
 [ lote 1 ]  DROP TRIGGER ...        -- L15 a L16
   GO  ------> se envia y compila, termina
   |
   v
 [ lote 2 ]  DROP VIEW ...           -- L18 a L19
   GO  ------> se envia y compila, termina
   |
   v
 [ lote 3 ]  CREATE TABLE Usuarios   -- L67 a L72
   GO  ------> se envia y compila, termina
```

INTUICION: el tipo de dato es el contrato de cada columna; fija que
se puede guardar y cuanto espacio ocupa.

Tipos que aparecen en el script:
- `INT`: numero entero. Es el tipo de las claves como `IdUsuario`
  [L68].
- `VARCHAR(n)`: texto de longitud variable con tope `n` caracteres.
  `NombreUsuario VARCHAR(100)` admite hasta 100 [L69].
- `DATE`: fecha sin hora (ano, mes, dia).
- `DATETIME2(0)`: fecha y hora con cero decimales de segundo (sin
  fraccion).
- `BIT`: vale 0 o 1; se usa como booleano (por ejemplo, una marca de
  activo o inactivo).

DE PROGRA II: `INT` es `int`, `VARCHAR(n)` es `String` con limite,
`BIT` es `boolean`, `DATE` y `DATETIME2` son tipos de fecha.

TRAMPA: un codigo no es un numero. `CodigoSistemaArmas` se declara
`VARCHAR(50)` y no `INT` [L86] porque puede llevar letras y ceros a
la izquierda; el comentario del script lo aclara.

INTUICION: `NULL` significa dato ausente o desconocido, no cero ni
texto vacio; al no saber el valor, el motor no puede afirmar ni
negar comparaciones sobre el.

Una columna `NULL` admite la ausencia de dato; una `NOT NULL` la
prohibe. `DescripcionEstadoElemento` permite `NULL` [L96];
`NombreUsuario` no [L69]. Las comparaciones con `NULL` siguen logica
de tres valores: el resultado puede ser verdadero, falso o
desconocido. Por eso `NULL = NULL` no da verdadero: comparar dos
valores desconocidos da desconocido. Para preguntar por ausencia se
usa `IS NULL`, no `= NULL`.

FRAME A FRAME
```
 expresion            resultado
 ----------           ---------
 5 = 5                verdadero
 5 = NULL             desconocido   (no se sabe el segundo valor)
 NULL = NULL          desconocido   (no es verdadero)
 columna IS NULL      verdadero si la columna esta ausente
```

DE PROGRA II: parecido a un objeto en `null`; preguntas `== null`,
no comparas su contenido.

INTUICION: una variable `@` es una caja con nombre que guarda un
valor temporal mientras corre el lote.

Una variable se crea con `DECLARE @nombre tipo` y se le asigna con
`SET @nombre = valor`. Vive dentro de su lote y se usa para llevar
un dato de una linea a otra. En las primeras lineas del archivo
todavia no se declaran variables; aparecen mas adelante, dentro de
procedimientos y funciones. La forma general es:

```
 DECLARE @IdItem INT;        -- reserva la caja, tipo entero
 SET     @IdItem = 5;        -- guarda 5 en la caja
 -- a partir de aca @IdItem vale 5 en este lote
```

DE PROGRA II: `DECLARE` es declarar la variable y `SET` es el `=` de
asignacion.

INTUICION: `IDENTITY(1,1)` es un contador automatico: el motor pone
el proximo numero en cada fila nueva, asi no hay que inventar el id
a mano.

`IDENTITY(semilla, paso)` arranca en el primer valor y suma el paso
en cada insercion. `IDENTITY(1,1)` empieza en 1 y avanza de a 1
[L68]. Se combina con `PRIMARY KEY` para dar a cada fila un
identificador unico y no nulo. El valor lo asigna el motor; la
insercion no lo provee.

FRAME A FRAME
```
 contador IDENTITY(1,1) de Usuarios
 estado interno: proximo = 1
   insert Ana   --> IdUsuario = 1   (proximo pasa a 2)
   insert Luis  --> IdUsuario = 2   (proximo pasa a 3)
   insert Marta --> IdUsuario = 3   (proximo pasa a 4)
```

DE PROGRA II: un contador que hace `id = contador++` por vos en cada
alta.

### Mapeo Programacion II a T-SQL

```
 Programacion II        T-SQL
 -------------------    ------------------------------------------
 variable               DECLARE @x INT
 asignacion (=)         SET @x = 5
 funcion                FUNCTION / PROCEDURE con nombre
 parametro              @param en la firma del objeto
 valor de retorno       RETURN dentro de una FUNCTION
 if / else              IF ... ELSE ...
 cast                   CAST(expr AS tipo) / CONVERT(tipo, expr)
 paso por referencia    parametro OUTPUT
```

```
QUE TE PUEDEN PREGUNTAR
-----------------------
1. Para que sirve GO?
   Separa el script en lotes; cada lote se compila y ejecuta como
   unidad antes de pasar al siguiente [L17].

2. Por que NULL = NULL no es verdadero?
   Porque NULL es un valor desconocido; comparar dos desconocidos
   da desconocido, no verdadero. Se consulta con IS NULL.

3. Que diferencia hay entre VARCHAR(50) e INT para un codigo?
   VARCHAR admite letras y ceros a la izquierda; un codigo como
   CodigoSistemaArmas se guarda como texto [L86], no como numero.

4. Que hace IDENTITY(1,1)?
   Es un contador automatico que arranca en 1 y suma 1 por fila;
   el motor asigna el id en cada insercion [L68].

5. Quien interpreta GO, el motor o la herramienta?
   La herramienta cliente. No es T-SQL estandar, no lleva punto y
   coma y el motor nunca lo recibe como instruccion.

6. Como se crea y se asigna una variable?
   Se crea con DECLARE @x tipo y se le asigna con SET @x = valor;
   vive dentro de su lote.
```

---

## Parte 1 - Esquema: dominio, limpieza y tablas de catalogo

Esta seccion explica, construccion por construccion, el bloque que crea la
base de datos: el modelo del dominio, la limpieza previa y todas las tablas
de catalogo con sus restricciones. El objetivo es que puedas defender en
oral cada linea sin haberla escrito vos.

### El modelo del dominio

INTUICION: pensa el deposito en tres niveles. Primero el catalogo dice que
clase de pieza existe (la ficha), despues el inventario dice cuantos
ejemplares fisicos hay de esa pieza, y por ultimo cada ejemplar arrastra
una pila de tarjetas que cuentan su historia de estados.

El modelo tiene una columna vertebral de tres tablas encadenadas uno a
muchos (1:N): `CatalogoMateriales` es la ficha del material (que es la
pieza); `InventarioFisico` son los ejemplares concretos de esa ficha; y
`Tarjetas` son las fichas de estado de cada ejemplar. Alrededor cuelgan
`Salidas` (registro de retiro del deposito), `MovimientosInventario`
(historial de movimientos) y la relacion muchos a muchos (N:N)
`MaterialesSistemasArmas`, que vincula cada material con los sistemas de
armas a los que sirve. El resto son catalogos de apoyo: `Usuarios`,
`TiposElemento`, `SistemasArmas`, `EstadosElemento`, `Ubicaciones` y
`MotivosSalida`.

DE PROGRA II: una relacion 1:N es como una lista. La ficha del catalogo es
un objeto, y tiene una lista de ejemplares; cada ejemplar tiene una lista de
tarjetas. La clave foranea (FK) es el puntero del hijo al padre.

Diagrama grande de cajas y flechas. La flecha apunta del lado N al lado 1
(el hijo guarda la referencia al padre):

```
            +-----------------+        +----------------+
            |  TiposElemento  |        |    Usuarios    |
            +-----------------+        +----------------+
                    ^                          ^
                    | 1:N                      | 1:N (SET NULL)
                    |                          |
   +----------------+--------------------------+
   |                                           |
+--------------------+   N:N   +----------------------+
| CatalogoMateriales |---------| MaterialesSistemas   |
|  PK natural = NNE  |---------|   Armas (puente)     |
+--------------------+         +----------------------+
   | 1:N                                |
   v                                    v
+------------------+            +----------------+
| InventarioFisico |            |  SistemasArmas |
+------------------+            +----------------+
   | 1:N         | 1:N
   v             v
+----------+  +----------------------+
| Tarjetas |  | MovimientosInventario|
+----------+  +----------------------+
   |
   | 1:N
   v
+----------+
| Salidas  |
+----------+
```

Diagrama de las tres capas (catalogo, ejemplares fisicos, pila de tarjetas
con la activa marcada):

```
 CAPA 1: CATALOGO (la ficha: que clase de pieza es)
   NNE-1  "Bomba hidraulica"

 CAPA 2: INVENTARIO FISICO (ejemplares reales de esa ficha)
   item 7   -> NNE-1
   item 8   -> NNE-1

 CAPA 3: TARJETAS (historia de estados de cada ejemplar)
   item 7:  tarjeta A  EN_RECEPCION   (vieja)
            tarjeta B  EN_SERVICIO    (vieja)
            tarjeta C  EN_DEPOSITO     [ACTIVA]
   item 8:  tarjeta D  EN_DEPOSITO     [ACTIVA]
```

### El bloque CREATE DATABASE comentado

INTUICION: el script asume que ya estas parado dentro de la base correcta,
por eso la creacion de la base esta apagada con comentarios.

Las lineas que crean y seleccionan la base estan comentadas a proposito
[L7-L11]. Si se descomenta, `CREATE DATABASE GestionMaterial;` crea la base,
y `USE GestionMaterial;` se para en ella para que todo lo que sigue se cree
adentro. Se dejan apagadas porque la catedra suele evaluar sobre una base ya
creada, y volver a crearla daria error si ya existe.

TRAMPA: el comentario "descomentar si se quiere crear la base" no significa
que el script la cree. Tal como esta, no crea ninguna base; trabaja sobre la
base activa de la sesion.

### Limpieza: DROP IF EXISTS en orden inverso

INTUICION: para que el script se pueda correr muchas veces sin romperse,
primero borra todo lo que pudiera existir de una corrida anterior, y lo
borra de afuera hacia adentro para no chocar con las dependencias.

El bloque [L15-L62] elimina objetos con `DROP ... IF EXISTS`. El `IF EXISTS`
hace que no falle si el objeto no estaba (re-ejecutabilidad: podes correr el
script sobre una base limpia o sobre una ya cargada). El orden es el inverso
de las dependencias: primero triggers [L15-L16], luego vistas [L18-L19],
procedimientos [L21-L45], funcion [L47], y al final las tablas [L50-L61]. Las
tablas se borran empezando por las hijas (`Salidas`,
`MovimientosInventario`, `Tarjetas`) y terminando por los catalogos padres
(`Usuarios`, `Ubicaciones`), porque no se puede borrar una tabla a la que
otra todavia apunta con una FK.

DE PROGRA II: es como liberar memoria de una estructura anidada. Primero
soltas los hijos, despues el padre; si soltas el padre primero, los hijos
quedan apuntando a la nada.

FRAME A FRAME
```
 se ejecuta el script otra vez
   |
   v
 DROP de triggers, vistas, procedimientos, funcion  (programabilidad)
   |
   v
 DROP de tablas hijas primero (Salidas, Movimientos, Tarjetas)
   |
   v
 DROP de tablas padre al final (catalogos, Usuarios)
   |
   v
 ahora CREATE TABLE arranca sobre una base vacia, sin choques de FK
```

Los `GO` [L17, L20, L46, L48, L62] separan lotes (batches): le indican al
motor "ejecuta hasta aca antes de seguir". Hacen falta porque ciertos
objetos deben existir o desaparecer por completo antes del siguiente paso.

### Tablas maestras: Usuarios como plantilla

INTUICION: una tabla maestra es una lista de referencia. `Usuarios` es la
plantilla mas simple: un identificador automatico y un par de campos
obligatorios.

`CREATE TABLE Usuarios` [L67-L72] define la tabla. La columna
`IdUsuario INT IDENTITY(1,1) PRIMARY KEY` [L68] es la clave primaria (PK)
surrogate: surrogate significa que es un numero inventado por el sistema, sin
sentido de negocio. `IDENTITY(1,1)` hace que el motor lo genere solo,
arrancando en 1 y subiendo de a 1 en cada insercion (semilla 1, incremento
1). `PRIMARY KEY` obliga a que sea unico y no nulo, y lo marca como la
identidad de la fila. Las columnas `NombreUsuario`, `ApellidoUsuario` y
`RolUsuario` son `VARCHAR ... NOT NULL` [L69-L71]: `NOT NULL` es una
restriccion de obligatoriedad, prohibe dejar el campo vacio.

DE PROGRA II: `IDENTITY` es un contador autoincremental, como un `static int`
que se incrementa solo cada vez que das de alta una fila. `NOT NULL` es como
un parametro obligatorio de una funcion: no podes llamarla sin pasarlo.

### UNIQUE: la clave alternativa

INTUICION: la PK no es lo unico que tiene que ser unico. UNIQUE marca otro
campo que tampoco se puede repetir, aunque no sea la identidad principal.

`TiposElemento` [L76-L80] tiene su PK surrogate `IdTipoElemento`, pero el
nombre del tipo tampoco debe repetirse. Eso lo garantiza
`CONSTRAINT UQ_TiposElemento_Nombre UNIQUE (NombreTipoElemento)` [L79]. Una
restriccion `UNIQUE` define una clave alternativa (candidata): un campo que
identifica la fila igual de bien que la PK, pero que no se eligio como
principal. El nombre `UQ_...` es una convencion para reconocer la restriccion
en los mensajes de error. La misma idea aparece en `SistemasArmas` con
`UQ_SistemasArmas_Codigo` [L88], en `EstadosElemento` con
`UQ_EstadosElemento_Codigo` [L97] y en `MotivosSalida` con
`UQ_MotivosSalida_Codigo` [L116].

Diagrama PK vs UNIQUE:

```
            PK (IdTipoElemento)        UNIQUE (NombreTipoElemento)
 fila 1     1                          "Rotable"
 fila 2     2                          "Herramienta"
 fila 3     3                          "Rotable"  <- RECHAZADO (UNIQUE)

 PK:     identidad de la fila, unica, NO NULL, una sola por tabla.
 UNIQUE: clave alternativa, unica, admite NULL, puede haber varias.
```

### CHECK de dominio: texto no vacio

INTUICION: que un campo sea `NOT NULL` no impide que le pongas una cadena
vacia. El `CHECK` de largo cierra ese agujero.

En `EstadosElemento`, la restriccion
`CONSTRAINT CHK_EstadosElemento_Codigo CHECK (LEN(CodigoEstadoElemento) > 0)`
[L98] exige que el codigo tenga al menos un caracter. `CHECK` es una
restriccion de dominio: una condicion booleana que cada fila debe cumplir
para ser aceptada. `LEN(...)` devuelve el largo del texto; si da 0 (cadena
vacia), la condicion es falsa y el motor rechaza la fila. Sin este `CHECK`,
una cadena vacia pasaria el `NOT NULL` igual. La misma proteccion esta en
`MotivosSalida` con `CHK_MotivosSalida_Codigo` [L117].

DE PROGRA II: es el `if` de validacion que pondrias al principio de una
funcion: `if (len(codigo) == 0) rechazar;`. La diferencia es que aca lo
ejecuta el motor en cada `INSERT` o `UPDATE`, no vos.

### El catalogo con clave natural NNE

INTUICION: a veces el negocio ya trae un identificador propio y unico. En vez
de inventar un numero, se usa ese.

`CatalogoMateriales` [L124-L140] no usa un `IDENTITY`. Su PK es
`NNE VARCHAR(20) NOT NULL PRIMARY KEY` [L125]: el Numero Nacional de Efecto,
un codigo que ya identifica de forma unica cada material en el dominio
aeronautico. Esto es una clave natural: una PK que tiene sentido de negocio,
a diferencia de la surrogate inventada por el sistema. El resto de columnas:
`NumeroReferenciaMaterial` y `ATAMaterial` son opcionales (`NULL`),
`DesignacionMaterial` es obligatoria (`NOT NULL`), y hay dos FK hacia
`TiposElemento` y `Usuarios` [L129-L130].

Diagrama PK natural vs surrogate:

```
 SURROGATE (Usuarios)          NATURAL (CatalogoMateriales)
   IdUsuario = 1                 NNE = "NNE-00012"
   IdUsuario = 2                 NNE = "NNE-00034"
   numero inventado por          codigo que ya existe en el
   el motor, sin significado     negocio y es unico por si solo
```

### Claves foraneas nombradas

INTUICION: la FK es el puntero del hijo al padre, y conviene ponerle nombre
para saber cual fallo cuando algo no cierra.

En `CatalogoMateriales`,
`CONSTRAINT FK_CatalogoMateriales_TiposElemento FOREIGN KEY (IdTipoElemento)
REFERENCES TiposElemento (IdTipoElemento)` [L131-L132] obliga a que cada
material apunte a un tipo que exista en `TiposElemento`. Una `FOREIGN KEY`
(FK) es una restriccion de integridad referencial: el valor del hijo debe
existir como PK en el padre. Darle nombre con `CONSTRAINT FK_...` permite que
los mensajes de error la identifiquen.

### El CHECK del capitulo ATA

INTUICION: el campo ATA se guarda como texto, pero solo vale si representa un
numero de capitulo entre 0 y 99. El `CHECK` valida eso sin romperse cuando el
campo esta vacio.

La restriccion `CHK_CatalogoMateriales_ATA` [L136-L139] dice: la fila pasa si
`ATAMaterial IS NULL`, o si `TRY_CAST(ATAMaterial AS INT) IS NOT NULL` y ese
entero esta `BETWEEN 0 AND 99`. `TRY_CAST` intenta convertir el texto a
entero y, si no puede, devuelve `NULL` en vez de cortar la operacion con un
error (un `CAST` comun explotaria). `BETWEEN 0 AND 99` exige el rango de
capitulo ATA valido.

DE PROGRA II: `TRY_CAST` es el cast defensivo que no tira excepcion. En vez de
`int x = (int)texto;` que rompe, es como un `int.TryParse` que devuelve si
pudo o no.

Diagrama de embudo (tres caminos):

```
 valor de ATAMaterial
        |
        v
   +---------------------+
   | es NULL?            |---- si --> PASA (campo opcional)
   +---------------------+
        | no
        v
   +---------------------+
   | TRY_CAST a INT      |---- falla (NULL) --> RECHAZA ("12A", "abc")
   +---------------------+
        | convierte
        v
   +---------------------+
   | entre 0 y 99?       |---- no  --> RECHAZA (150, -3)
   +---------------------+
        | si
        v
       PASA (24, 0, 99)
```

### ON DELETE SET NULL en el usuario

INTUICION: si se borra el usuario que cargo una ficha, no queremos perder la
ficha. La dejamos sin autor en vez de borrarla.

La FK `FK_CatalogoMateriales_Usuarios` [L133-L135] referencia a `Usuarios` y
agrega `ON DELETE SET NULL`. Esto es una accion referencial: define que pasa
con el hijo cuando se borra el padre. `SET NULL` pone la columna `IdUsuario`
en `NULL`, dejando la ficha del material viva pero sin usuario asociado. Por
eso `IdUsuario` se declara `NULL` [L130]: tiene que admitir el vacio para
que esta accion sea posible.

Diagrama ANTES / DESPUES:

```
 ANTES                          DESPUES de borrar el Usuario 5
 Usuarios                       Usuarios
   5  "Perez"                     (vacio)
 CatalogoMateriales             CatalogoMateriales
   NNE-12 cargado por 5           NNE-12 cargado por NULL
   (la ficha sobrevive, solo pierde el autor: SET NULL)
```

### La relacion N:N con clave compuesta

INTUICION: un material sirve a varios sistemas de armas, y un sistema usa
varios materiales. Eso no entra en una sola tabla; hace falta una tabla
puente cuya identidad sea el par.

`MaterialesSistemasArmas` [L145-L155] es la tabla puente de la relacion
muchos a muchos (N:N). Tiene dos columnas, `IdSistemaArmas` y `NNE`, y su PK
es `CONSTRAINT PK_MaterialesSistemasArmas PRIMARY KEY (IdSistemaArmas, NNE)`
[L148]: una PK compuesta, formada por las dos columnas juntas. Esto garantiza
que el mismo par material-sistema no se repita, y como toda la fila es clave
no hay dependencias parciales (cumple la segunda forma normal, 2FN). Las dos
FK referencian a `SistemasArmas` [L149-L151] y a `CatalogoMateriales`
[L152-L155], ambas con `ON DELETE CASCADE`: si se borra el padre, la fila del
puente se borra sola. Aca `CASCADE` es correcto porque la fila puente no tiene
valor sin sus dos padres; no es informacion propia, solo un vinculo.

DE PROGRA II: la PK compuesta es como una clave de diccionario formada por una
tupla `(idSistema, nne)`: la combinacion identifica la entrada, no cada parte
por separado.

Diagrama ANTES / DESPUES (CASCADE):

```
 ANTES                          DESPUES de borrar el SistemaArmas 3
 SistemasArmas                  SistemasArmas
   3  "A-4AR"                     (vacio)
 MaterialesSistemasArmas        MaterialesSistemasArmas
   (3, NNE-12)                    (la fila se borro con el padre:
   (3, NNE-34)                     CASCADE; el vinculo no tiene
                                   sentido sin el sistema)
```

---

QUE TE PUEDEN PREGUNTAR

- Por que el catalogo usa NNE como PK y Usuarios usa IDENTITY?
  Porque NNE ya es un codigo unico del negocio (clave natural), mientras que
  el usuario no trae un identificador propio y se le inventa uno (surrogate).

- Para que sirve el DROP IF EXISTS en orden inverso?
  Para que el script se pueda re-ejecutar sin error; borra hijos antes que
  padres para no violar las FK.

- Si una columna ya es NOT NULL, para que el CHECK(LEN > 0)?
  Porque NOT NULL solo prohibe el nulo, no la cadena vacia; el CHECK exige al
  menos un caracter.

- Por que TRY_CAST y no CAST en la validacion de ATA?
  Porque CAST sobre un texto no numerico lanza error y corta la operacion;
  TRY_CAST devuelve NULL y deja que el CHECK decida rechazar la fila.

- Por que ON DELETE SET NULL en el usuario y ON DELETE CASCADE en la N:N?
  La ficha del material tiene valor propio aunque se borre su autor, asi que
  se conserva con autor NULL. La fila puente no tiene valor sin sus padres,
  asi que se borra en cascada.

- Por que la PK de la tabla puente es compuesta?
  Para impedir pares material-sistema repetidos y porque la fila no tiene mas
  datos que el vinculo; toda la fila es la clave (2FN).

---

## Parte 1 (continuacion) - Inventario, tarjetas, movimientos y salidas

Esta seccion explica las cuatro tablas que registran el movimiento real
de los elementos: que ejemplar fisico existe, que tarjeta tiene, que
pasos da dentro del deposito y cuando sale. El eje conceptual de toda la
guia esta aca: las tres politicas `ON DELETE` y por que se elige una u
otra segun la relacion padre-hijo.

### InventarioFisico y la FK ON DELETE SET NULL

INTUICION: cada fila de InventarioFisico es un ejemplar fisico concreto
que existe en el mundo, no la definicion de catalogo. El catalogo dice
"existe el material Bomba"; el inventario dice "tengo esta bomba puntual,
con este numero de serie, en esta ubicacion".

La tabla declara `IdItem` como `INT IDENTITY(1,1) PRIMARY KEY`, una
clave numerica autogenerada por el motor [L162]. La columna `NNE` es la
clave foranea hacia CatalogoMateriales: relaciona el ejemplar con su tipo
de material, relacion uno a muchos (un material del catalogo, muchos
ejemplares en inventario) [L163][L169][L170].

DE PROGRA II: una clave foranea es como guardar el identificador de otro
objeto en vez de copiar todos sus datos. InventarioFisico guarda el `NNE`
y "apunta" a la fila del catalogo, igual que una referencia.

La columna `IdUbicacion` es `INT NULL` y tiene una FK a Ubicaciones con
`ON DELETE SET NULL` [L168][L171][L172][L173]. Aca aparece un concepto
del dominio que reaparece en la vista y en el trigger:

INTUICION: `IdUbicacion = NULL` significa que el ejemplar esta fuera del
deposito. No esta en ningun estante porque, fisicamente, no esta en el
edificio (prestado, en reparacion, en inspeccion). El NULL no es un dato
faltante por descuido: es informacion, quiere decir "afuera".

Por eso la politica `ON DELETE SET NULL` es coherente: si se borra una
ubicacion del deposito, los ejemplares que estaban ahi no se borran (el
ejemplar fisico sigue existiendo), simplemente quedan sin ubicar, con
`IdUbicacion` en NULL.

```
 ANTES                        DESPUES de borrar la Ubicacion 4
 Ubicaciones                  Ubicaciones
   4  Estante A3                (vacio)
 InventarioFisico             InventarioFisico
   item 7  IdUbicacion=4        item 7  IdUbicacion=NULL
   (en Estante A3)              (sin ubicar, sigue existiendo)
```

### Tarjetas: DEFAULT de fecha, BIT y ON DELETE CASCADE

INTUICION: la tarjeta es el papel fisico pegado al elemento que dice en
que estado esta. El estado del elemento no se guarda en el elemento: es
el estado de su tarjeta activa. Cambiar de estado es emitir una tarjeta
nueva y activarla.

`Tarjetas` tiene `IdItem` como FK a InventarioFisico e `IdEstadoElemento`
como FK a EstadosElemento [L181][L182]. Tres construcciones a defender:

1. `FechaEmisionTarjeta DATE NOT NULL DEFAULT CAST(SYSDATETIME() AS DATE)`
   [L186]. Si al insertar no se da fecha, el motor rellena con la fecha
   actual. `SYSDATETIME()` devuelve fecha y hora; el `CAST(... AS DATE)`
   la recorta a solo fecha (sin hora), porque la emision de tarjeta se
   maneja por dia, no por segundo.

2. `ActivaTarjeta BIT NOT NULL DEFAULT 1` [L189]. `BIT` es el tipo
   booleano de T-SQL (0 o 1). El `DEFAULT 1` hace que toda tarjeta nueva
   nazca activa salvo que se diga lo contrario.

DE PROGRA II: un `DEFAULT` es el valor por omision de un parametro. Si la
funcion se llama sin ese argumento, toma el valor por defecto. Aca el
"argumento" es el valor de la columna en el INSERT.

3. `FK_Tarjetas_InventarioFisico ... ON DELETE CASCADE` [L190][L191]
   [L192]. Si se borra el ejemplar, se borran en cascada todas sus
   tarjetas. La tarjeta no tiene sentido sin el elemento al que esta
   pegada: es historial dependiente.

FRAME A FRAME (DEFAULT al insertar sin fecha)
```
 INSERT INTO Tarjetas (IdItem, IdEstadoElemento)
 VALUES (7, 1)            -- no se pasa FechaEmisionTarjeta
   |
   v
 el motor ve que falta la columna y tiene DEFAULT
   |
   v
 evalua CAST(SYSDATETIME() AS DATE)  =>  2026-06-26
   |
   v
 fila guardada: FechaEmisionTarjeta = 2026-06-26, ActivaTarjeta = 1
```

### MovimientosInventario: DATETIME2(0) y tres FK con politicas distintas

INTUICION: es la bitacora de trazabilidad. Cada vez que un elemento se
mueve, entra, sale o cambia de mano, se anota una fila. Es un registro
historico: se agrega, no se reescribe.

`FechaRegistroMovimiento DATETIME2(0) NOT NULL DEFAULT SYSDATETIME()`
[L203]. Aca si interesa la hora exacta del movimiento, por eso es
`DATETIME2(0)` y no `DATE`. El `(0)` indica cero decimales de segundo:
precision de un segundo, sin fracciones. El `DEFAULT SYSDATETIME()`
estampa fecha y hora actuales si no se pasa valor.

Esta tabla es el mejor ejemplo de las tres politicas conviviendo, una
por cada FK [L207 a L215]:

- `IdItem` FK a InventarioFisico con `ON DELETE CASCADE` [L207-L209]: si
  se borra el ejemplar, su bitacora se va con el. Sin elemento, los
  movimientos de ese elemento no tienen referente.
- `IdUbicacion` FK a Ubicaciones con `ON DELETE SET NULL` [L210-L212]: si
  se borra la ubicacion, el movimiento historico se conserva pero queda
  con `IdUbicacion` NULL. Igual que en inventario, NULL = afuera.
- `IdUsuarioRegistra` FK a Usuarios con `ON DELETE SET NULL` [L213-L215]:
  si se borra el usuario que registro, el movimiento no se pierde; solo
  queda sin saber quien lo cargo. El hecho historico vale mas que el
  autor.

### El diagrama central: las tres politicas ON DELETE frame a frame

INTUICION: `ON DELETE` define que le pasa al hijo cuando se borra el
padre. Son tres respuestas posibles a una misma pregunta.

- CASCADE: borra al hijo tambien (el hijo no vive sin el padre).
- SET NULL: deja al hijo vivo pero le pone la FK en NULL (la relacion se
  corta, el hijo sigue).
- NO ACTION: rechaza el borrado del padre si tiene hijos (es el
  comportamiento por defecto si no se escribe nada).

FRAME A FRAME (mismo borrado del padre, tres politicas, lado a lado)
```
 Padre: fila P (id=4).  Hijo H apunta a P por su FK.
 Se ejecuta: DELETE del padre P.

 CASCADE              SET NULL             NO ACTION
 ANTES                ANTES                ANTES
  P: 4                 P: 4                 P: 4
  H -> 4               H -> 4               H -> 4
 DESPUES              DESPUES              DESPUES
  P: (borrado)         P: (borrado)         P: 4 (sigue)
  H: (borrado)         H -> NULL            H -> 4
  el hijo se va        el hijo queda,       el DELETE se
  con el padre         FK en NULL           rechaza, todo
                                            queda igual
```

Como elegir, regla practica de este TP: si el hijo es historial o
detalle que no existe sin el padre, CASCADE (tarjetas, movimientos y
salidas dependen del ejemplar). Si el hijo es un hecho que sobrevive
aunque se pierda la referencia, SET NULL (ubicacion borrada, usuario
borrado). NO ACTION protege catalogos que no deben borrarse si estan en
uso.

### Salidas: dos CHECK de coherencia de fechas

INTUICION: una salida es el registro de cuando un elemento sale del
deposito y, si vuelve, cuando vuelve. `FechaRetornoSalida` en NULL
significa que el elemento sigue afuera; una baja nunca retorna.

La tabla tiene `FechaSalida DATETIME2(0) NOT NULL DEFAULT SYSDATETIME()`,
`FechaPrevistaRetornoSalida DATE NULL` y `FechaRetornoSalida
DATETIME2(0) NULL` [L226][L227][L228]. Las FK siguen el patron ya visto:
`IdItem` con `ON DELETE CASCADE` y `IdMotivoSalida` con la politica por
defecto (NO ACTION, no se borra un motivo en uso) [L231-L235].

Lo nuevo son dos restricciones `CHECK`, reglas que el motor valida en
cada INSERT o UPDATE y rechaza la fila si dan falso:

- `CHK_Salidas_RetornoPosterior`: `CHECK (FechaRetornoSalida IS NULL OR
  FechaRetornoSalida >= FechaSalida)` [L237][L238]. Un retorno no puede
  ser anterior a la salida. Se permite NULL (todavia no volvio).
- `CHK_Salidas_PrevistaPosterior`: `CHECK (FechaPrevistaRetornoSalida IS
  NULL OR FechaPrevistaRetornoSalida >= CAST(FechaSalida AS DATE))`
  [L239][L240]. La fecha prevista de retorno no puede ser anterior a la
  salida. El `CAST(FechaSalida AS DATE)` recorta la salida a solo fecha
  para comparar contra `FechaPrevistaRetornoSalida`, que es `DATE`. Se
  comparan dos valores del mismo tipo.

DE PROGRA II: cada `CHECK` es un `if` que protege la insercion. Si la
condicion es falsa, la fila se rechaza, como una validacion al inicio de
una funcion que aborta con datos invalidos. El `IS NULL OR ...` es el
patron "si no hay dato, no valido; si hay, exijo coherencia".

```
 INSERT con FechaSalida=2026-06-01, FechaRetornoSalida=2026-05-30
   |
   v
 CHK_Salidas_RetornoPosterior evalua:
   2026-05-30 >= 2026-06-01  =>  FALSO
   |
   v
 el motor RECHAZA el INSERT (retorno anterior a la salida)
```

### DATE vs DATETIME2(0): cuando usar cada uno

INTUICION: usa `DATE` cuando solo importa el dia; usa `DATETIME2(0)`
cuando importa la hora exacta al segundo.

- `DATE`: solo fecha, sin hora. Se usa en `FechaEmisionTarjeta`,
  `FechaVencimientoItem` y `FechaPrevistaRetornoSalida`. La emision o el
  vencimiento se manejan por dia.
- `DATETIME2(0)`: fecha y hora con precision de un segundo (el `0` es la
  cantidad de decimales de segundo: ninguno). Se usa en
  `FechaRegistroMovimiento`, `FechaSalida` y `FechaRetornoSalida`, donde
  el momento exacto del evento es trazabilidad.

### Datos semilla: EstadosElemento y MotivosSalida

INTUICION: hay tablas de catalogo que necesitan valores fijos desde el
arranque, los codigos contra los que el resto del sistema valida. Cargar
esos valores se llama sembrar datos (datos semilla).

`EstadosElemento` se siembra con tres estados [L246-L249]: `EN_SERVICIO`
(operativo, tarjeta verde), `EN_SERVICIO_TRANSITORIO` (pendiente de envio
a reparacion, tarjeta blanca) y `BAJA` (fuera de circulacion). Estos son
los estados que puede tomar la tarjeta activa de un elemento.

`MotivosSalida` se siembra con cuatro motivos [L252-L256]: `PRESTAMO`,
`REPARACIO`, `INSPECCIO` (los tres retornan al deposito) y `BAJA`
(definitiva, no retorna). El motivo de salida determina si se espera o no
un retorno.

TRAMPA: el script tiene comentarios de linea (`-- ...`) que rotulan cada
tabla con un numero (9, 10, 11, 12). Ese numero es solo orden de lectura
del script, no es parte del esquema ni una columna; no lo cites como si
fuera codigo ejecutable.

QUE TE PUEDEN PREGUNTAR
- Por que `IdUbicacion` puede ser NULL? Porque NULL significa que el
  ejemplar esta fuera del deposito (prestado, en reparacion); es un dato,
  no un faltante.
- Por que las tarjetas usan `ON DELETE CASCADE` y la ubicacion `SET
  NULL`? La tarjeta es historial que no existe sin el elemento (CASCADE);
  el movimiento o ejemplar sobrevive aunque su ubicacion se borre (SET
  NULL).
- Que pasa si se borra el padre con `NO ACTION` y hay hijos? El motor
  rechaza el DELETE; el padre no se puede borrar mientras tenga hijos. Es
  el comportamiento por defecto cuando no se escribe `ON DELETE`.
- Diferencia entre `DATE` y `DATETIME2(0)`? `DATE` guarda solo el dia;
  `DATETIME2(0)` guarda fecha y hora con precision de un segundo (cero
  decimales de segundo).
- Que hace `DEFAULT CAST(SYSDATETIME() AS DATE)`? Si el INSERT no trae
  fecha, el motor toma la fecha y hora actuales y las recorta a solo
  fecha. Es el valor por omision de la columna.
- Para que sirven los dos `CHECK` de Salidas? Garantizan coherencia de
  fechas: ni el retorno real ni el previsto pueden ser anteriores a la
  fecha de salida (admitiendo NULL si todavia no hay retorno).

---

## Parte 2 - Programabilidad: funcion, triggers y procedimiento

Esta seccion explica los objetos programables del script: una funcion
escalar, dos triggers y un procedimiento almacenado con transaccion.
Es la parte de mayor peso del oral. Se trata cada construccion linea
por linea, con diagramas FRAME A FRAME.

### 1. Funcion escalar fn_EstadoActual [L262-L273]

INTUICION: una funcion escalar es una cuenta con nombre que recibe
datos y devuelve un unico valor, igual que una funcion en Programacion
II que recibe parametros y hace return de un dato.

DE PROGRA II: `@IdItem` es el parametro de entrada, `RETURNS
VARCHAR(30)` es el tipo del valor de retorno, `@cod` es una variable
local y `RETURN @cod` es el return.

Tratamiento por linea:

- `CREATE FUNCTION fn_EstadoActual (@IdItem INT)` [L262]: declara la
  funcion y su unico parametro de entrada, el identificador de un
  ejemplar fisico (un INT).
- `RETURNS VARCHAR(30)` [L263]: el valor de retorno es una cadena de
  hasta 30 caracteres. Por ser escalar devuelve un solo valor, no una
  tabla.
- `BEGIN ... END` [L265, L272]: delimita el cuerpo, como las llaves de
  un bloque.
- `DECLARE @cod VARCHAR(30);` [L266]: crea una variable local donde se
  guardara el resultado. Arranca en NULL.
- `SELECT @cod = EstadosElemento.CodigoEstadoElemento` [L267]: asigna
  a la variable el codigo de estado leido. La forma `SELECT @x = col`
  vuelca el valor de la columna dentro de la variable.
- `FROM Tarjetas JOIN EstadosElemento ON ...` [L268-L269]: combina la
  tarjeta del ejemplar con la tabla de catalogo de estados para
  traducir el identificador interno del estado a su codigo legible.
- `WHERE Tarjetas.IdItem = @IdItem AND Tarjetas.ActivaTarjeta = 1`
  [L270]: filtra por el ejemplar pedido y, ademas, exige que la
  tarjeta este activa (`ActivaTarjeta = 1`). Un ejemplar puede tener
  varias tarjetas a lo largo del tiempo; solo una esta activa.
- `RETURN @cod;` [L271]: devuelve el valor. Punto clave: si el `WHERE`
  no encuentra ninguna fila, `@cod` nunca se asigna y queda en NULL,
  por lo que la funcion devuelve NULL. Asi, un ejemplar sin tarjeta
  activa devuelve NULL en lugar de error.

FRAME A FRAME
```
 entra @IdItem = 5
   |
   v
 @cod = NULL  (valor inicial de la variable)
   |
   v
 busca en Tarjetas la fila con IdItem = 5 y ActivaTarjeta = 1
   |
   +-- si la encuentra: JOIN a EstadosElemento, lee el codigo
   |     |
   |     v
   |   @cod = 'EN_SERVICIO'
   |
   +-- si no hay tarjeta activa: @cod sigue en NULL
   |
   v
 RETURN @cod   (EN_SERVICIO o NULL)
```

Al invocarla se antepone el prefijo `dbo.`, el esquema por defecto:
`SELECT dbo.fn_EstadoActual(5);`. Las funciones escalares se llaman
con el esquema adelante; sin el, el motor no las resuelve.

### 2. Trigger AFTER INSERT trg_salida_abre_saca_del_deposito [L278-L289]

INTUICION: un trigger es codigo que el motor dispara solo cuando algo
cambia una tabla. No se llama a mano. Este reacciona despues de
insertar una salida y sincroniza el inventario.

Que es y cuando dispara: es un disparador definido `ON Salidas AFTER
INSERT` [L279-L280]. Se ejecuta automaticamente despues de que se
inserta una o varias filas en la tabla Salidas. Regla de negocio: al
abrir una salida sin fecha de retorno, el ejemplar deja de estar en el
deposito, asi que su ubicacion fisica pasa a NULL.

La pseudo-tabla inserted: dentro de un trigger de INSERT existe una
tabla temporal llamada `inserted` que contiene exactamente las filas
recien insertadas. El trigger la usa para saber a que ejemplares
afectar.

Tratamiento por linea:

- `UPDATE InventarioFisico SET InventarioFisico.IdUbicacion = NULL`
  [L283-L284]: blanquea la ubicacion del ejemplar.
- `FROM InventarioFisico JOIN inserted ON inserted.IdItem =
  InventarioFisico.IdItem` [L285-L286]: liga cada salida recien
  insertada con su fila de inventario por el identificador de
  ejemplar. El `UPDATE ... FROM ... JOIN` actualiza solo las filas de
  inventario que matchean con `inserted`.
- `WHERE inserted.FechaRetornoSalida IS NULL` [L287]: condicion clave.
  Solo saca del deposito si la salida no tiene fecha de retorno
  cargada, es decir, es una salida abierta. Si la salida ya viene con
  retorno, no se toca la ubicacion.

FRAME A FRAME (pseudo-tabla y ANTES / DESPUES)
```
 se inserta en Salidas: IdItem=7, FechaRetornoSalida=NULL

 inserted (pseudo-tabla)
   IdItem | FechaRetornoSalida
      7   | NULL          <- retorno nulo: salida abierta

 ANTES                         DESPUES
 InventarioFisico              InventarioFisico
   item 7  IdUbicacion = 3       item 7  IdUbicacion = NULL
```

### 3. Trigger INSTEAD OF DELETE trg_estado_no_borrar [L292-L307]

INTUICION: un trigger INSTEAD OF reemplaza la operacion: en lugar de
borrar, el motor ejecuta el cuerpo del trigger, que decide si permite
el borrado o lo rechaza.

Que es y cuando dispara: definido `ON EstadosElemento INSTEAD OF
DELETE` [L293-L294]. Los estados son un catalogo de referencia. Se
permite borrar un estado solo si ninguna tarjeta lo usa; si esta en
uso, se rechaza.

La pseudo-tabla deleted: en un trigger de DELETE existe la tabla
temporal `deleted` con las filas que se intentaron borrar.

Tratamiento por linea:

- `IF EXISTS (SELECT 1 FROM Tarjetas JOIN deleted ON
  deleted.IdEstadoElemento = Tarjetas.IdEstadoElemento)` [L298]:
  pregunta si alguna tarjeta usa alguno de los estados que se quieren
  borrar. `IF EXISTS` devuelve verdadero apenas hay al menos una fila.
- `THROW 50002, 'No se puede borrar un estado en uso...', 1;` [L300]:
  si el estado esta en uso, lanza un error con codigo 50002 y aborta.
  Como es INSTEAD OF y nunca se llega al DELETE, la fila no se borra.
- `DELETE EstadosElemento FROM EstadosElemento JOIN deleted ON
  deleted.IdEstadoElemento = EstadosElemento.IdEstadoElemento;`
  [L303-L305]: rama permitida. Si ninguna tarjeta usa el estado, el
  trigger ejecuta a mano el borrado real que originalmente se pidio.
  En un INSTEAD OF, si se quiere que la operacion ocurra, hay que
  escribirla explicitamente.

FRAME A FRAME (dos caminos)
```
 DELETE FROM EstadosElemento WHERE IdEstadoElemento = X
   |
   v
 deleted (pseudo-tabla) contiene el estado X
   |
   v
 IF EXISTS: alguna Tarjeta usa X ?
   |                         |
   si                        no
   |                         |
   v                         v
 THROW 50002              DELETE manual de X
 (no se borra)            (se borra de verdad)
```

Diferencia AFTER vs INSTEAD OF
```
 AFTER INSERT (trigger 2)
   1) el motor YA inserto la fila
   2) DESPUES corre el cuerpo del trigger (sincroniza inventario)

 INSTEAD OF DELETE (trigger 3)
   1) el motor NO borra nada por su cuenta
   2) EN LUGAR de borrar, corre el cuerpo del trigger
   3) el cuerpo decide: rechazar (THROW) o borrar a mano (DELETE)
```

DE PROGRA II: AFTER es como codigo que corre despues de que ocurrio el
evento; INSTEAD OF es como interceptar la llamada y decidir vos si se
ejecuta o no, igual que envolver una funcion para validar antes de
dejarla pasar.

### 4. Procedimiento sp_AltaElemento [L312-L342]

INTUICION: un procedimiento almacenado es una subrutina con nombre que
agrupa varios pasos en una sola unidad. Este da de alta un ejemplar
fisico y su primera tarjeta en un solo bloque que se hace todo o nada.

DE PROGRA II: los `@parametros` son los argumentos de la subrutina;
los `= NULL` son valores por defecto (si no se pasa el argumento, vale
NULL); `@IdItem ... OUTPUT` es un parametro de salida, es decir, pasaje
por referencia.

Parametros [L313-L320]:

- `@NNE VARCHAR(20)`: obligatorio, no tiene default. Es el codigo de
  catalogo del material.
- `@NumeroSerie`, `@IdUbicacion`, `@FechaVencimiento`, `@Tamano`,
  `@Observaciones`, `@Inspector`: todos con `= NULL`, opcionales. Si el
  llamador no los pasa, entran como NULL.
- `@IdItem INT OUTPUT` [L320]: parametro de salida. El procedimiento
  escribe en el y el valor vuelve al llamador.

Que es una transaccion y que permite: una transaccion es un grupo de
operaciones que el motor trata como una unidad indivisible. Permite
que, si algo falla a mitad de camino, no quede medio trabajo hecho: o
se confirman todos los pasos o no se aplica ninguno.

ACID son las cuatro garantias de una transaccion:
- Atomicidad: todo o nada; o se aplican todos los pasos o ninguno.
- Consistencia: la base pasa de un estado valido a otro valido,
  respetando las restricciones.
- Aislamiento (Isolation): las transacciones concurrentes no se pisan
  entre si.
- Durabilidad: una vez confirmada (COMMIT), el cambio persiste aunque
  se corte la energia.

Tratamiento por linea del cuerpo:

- `BEGIN TRY` [L323]: abre el bloque protegido. Si cualquier
  instruccion adentro falla, el control salta al `BEGIN CATCH`.
- `IF NOT EXISTS (SELECT 1 FROM CatalogoMateriales WHERE NNE = @NNE)
  THROW 50010, 'El NNE no existe en el catalogo.', 1;` [L324-L325]:
  validacion previa. Si el NNE recibido no existe en el catalogo,
  lanza error 50010 y no se inserta nada. Se valida antes de abrir la
  transaccion.
- `BEGIN TRANSACTION;` [L327]: arranca la transaccion. A partir de
  aca, los cambios son provisorios hasta el COMMIT.
- `INSERT INTO InventarioFisico (...) VALUES (...)` [L328-L329]:
  inserta el ejemplar fisico. La tabla genera un identificador
  automatico (IDENTITY).
- `SET @IdItem = CAST(SCOPE_IDENTITY() AS INT);` [L331]: captura el
  identificador recien generado y lo guarda en el parametro de salida.
  `SCOPE_IDENTITY()` devuelve el ultimo IDENTITY generado en el mismo
  ambito (este procedimiento).
- `INSERT INTO Tarjetas (...) SELECT @IdItem, IdEstadoElemento,
  @Inspector, 1 FROM EstadosElemento WHERE CodigoEstadoElemento =
  'EN_SERVICIO';` [L333-L335]: inserta la primera tarjeta del ejemplar,
  apuntada al `@IdItem` recien creado, en estado EN_SERVICIO y con
  `ActivaTarjeta = 1`.
- `COMMIT TRANSACTION;` [L336]: confirma. Recien aca los dos INSERT se
  vuelven permanentes y visibles para todos.
- `BEGIN CATCH` [L338]: bloque de manejo de error. Solo se ejecuta si
  algo dentro del TRY fallo.
- `IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;` [L339]: `@@TRANCOUNT` es
  el contador de transacciones abiertas. Si hay una abierta (vale mas
  de 0), la revierte: deshace todo lo que la transaccion hizo.
- `THROW;` [L340]: re-lanza el mismo error que se capturo, sin
  argumentos, para que el llamador se entere de la falla.

Por que el TRY/CATCH envuelve la transaccion: por atomicidad. Si la
segunda insercion (la tarjeta) falla, el CATCH hace ROLLBACK y la
primera insercion (el ejemplar) tambien se deshace. No queda un
ejemplar en InventarioFisico sin su tarjeta, es decir, sin una fila
huerfana.

FRAME A FRAME (camino feliz)
```
 llamador: EXEC sp_AltaElemento @NNE='NNE-1', @IdItem=@x OUTPUT
   |
   v
 @@TRANCOUNT = 0      @IdItem = (sin valor util)
   |
   v
 valida NNE en catalogo -> existe, sigue
   |
   v
 BEGIN TRANSACTION    @@TRANCOUNT = 1
   |
   v
 INSERT InventarioFisico  -> genera IDENTITY = 42
   |
   v
 SET @IdItem = SCOPE_IDENTITY()   @IdItem = 42
   |
   v
 INSERT Tarjetas (IdItem=42, EN_SERVICIO, Activa=1)
   |
   v
 COMMIT               @@TRANCOUNT = 0
   |
   v
 el parametro OUTPUT lleva @IdItem = 42 de vuelta al llamador
```

FRAME A FRAME (camino de error: falla el segundo INSERT)
```
 BEGIN TRANSACTION    @@TRANCOUNT = 1
   |
   v
 INSERT InventarioFisico  -> fila item 42 (provisoria)
   |
   v
 INSERT Tarjetas  -> FALLA (lanza error)
   |
   v
 salta a BEGIN CATCH
   |
   v
 @@TRANCOUNT > 0  ->  ROLLBACK
   |
   v
 ANTES del rollback           DESPUES del rollback
 InventarioFisico             InventarioFisico
   item 42 (provisorio)         (vacio: no quedo huerfano)
   |
   v
 THROW  ->  el error sube al llamador
```

Transaccion = todo o nada
```
 BEGIN TRANSACTION
   INSERT A   ok
   INSERT B   ok    --> COMMIT  : quedan A y B
 ---------------------------------------------------
 BEGIN TRANSACTION
   INSERT A   ok
   INSERT B   falla --> ROLLBACK: no queda ni A ni B
```

SCOPE_IDENTITY vs @@IDENTITY: ambos devuelven el ultimo valor IDENTITY
generado, pero `@@IDENTITY` ve cualquier insercion de la sesion,
incluyendo las que dispare un trigger en otra tabla. `SCOPE_IDENTITY()`
se limita al ambito actual (este procedimiento), por lo que devuelve el
identificador del INSERT propio aunque haya triggers de por medio. Por
eso se usa `SCOPE_IDENTITY()`: es la opcion correcta cuando hay
triggers.

El procedimiento se invoca con `EXEC` pasando los argumentos y
recibiendo `@IdItem` con la palabra `OUTPUT` tambien del lado del
llamador, para que el valor de retorno se copie de vuelta.

QUE TE PUEDEN PREGUNTAR
- Que es una transaccion y que te permite? Un grupo de operaciones
  tratadas como una unidad indivisible; permite que, si algo falla, no
  quede trabajo a medias (todo o nada).
- Que significan A-C-I-D? Atomicidad (todo o nada), Consistencia
  (estados validos), Aislamiento (no se pisan entre si) y Durabilidad
  (lo confirmado persiste).
- Por que el TRY/CATCH envuelve la transaccion? Para garantizar
  atomicidad: si falla el segundo INSERT, el CATCH hace ROLLBACK y se
  deshace tambien el primero.
- Que pasa si no hubiera ROLLBACK? La transaccion quedaria abierta o
  se confirmaria parcialmente, dejando un ejemplar sin tarjeta, una
  fila huerfana e inconsistente.
- SCOPE_IDENTITY vs @@IDENTITY? Los dos dan el ultimo IDENTITY, pero
  `@@IDENTITY` puede traer el de un trigger en otra tabla;
  `SCOPE_IDENTITY()` se limita al ambito actual y es lo seguro.
- Que es un parametro OUTPUT? Un parametro de salida: pasaje por
  referencia, el procedimiento escribe en el y el valor vuelve al
  llamador.
- Que hace THROW sin argumentos? Re-lanza el mismo error que se
  capturo en el CATCH, conservando codigo y mensaje originales.
- Que es @@TRANCOUNT? La cantidad de transacciones abiertas; si es
  mayor que 0 hay una transaccion activa que conviene revertir antes de
  re-lanzar el error.

---

## Parte 3 - CRUD por tabla: un patron repetido

La Parte 3 del script define, para cada una de las 12 tablas, dos
procedimientos almacenados: uno de alta (Insert) y uno de consulta
(Read). Son 24 procedimientos, pero no hay 24 ideas distintas. Hay
dos plantillas y un punado de variantes. Quien defiende esta seccion
no debe recitar 24 procedimientos: debe mostrar las dos plantillas y
explicar que cambia en cada caso particular.

INTUICION: el CRUD por tabla es un molde. Aprendes el molde una vez
y despues solo miras que pieza concreta entra en cada vaciado.

DE PROGRA II: un procedimiento almacenado es como una funcion con
nombre que recibe parametros. El Insert es una funcion que ademas
devuelve algo por un parametro `OUTPUT` (pasaje por referencia). El
Read es una funcion que recibe un filtro opcional con valor por
defecto, como un parametro con valor predeterminado.

### Plantilla 1: el Insert (alta)

INTUICION: el Insert recibe un valor por cada columna que el usuario
debe cargar, inserta la fila, y devuelve por referencia el
identificador que la base genero.

Se toma como modelo `sp_Usuarios_Insert` [L348-L356]. La estructura
tiene cuatro partes fijas:

1. Parametros de entrada, uno por columna que se carga a mano:
   `@NombreUsuario`, `@ApellidoUsuario`, `@RolUsuario` [L349].
2. Un parametro extra marcado `OUTPUT`: `@IdUsuario INT OUTPUT`
   [L350]. Es el canal de salida.
3. El `INSERT INTO ... VALUES (...)` que escribe la fila [L353-L354].
4. `SET @IdUsuario = CAST(SCOPE_IDENTITY() AS INT)` [L355], que
   coloca en el parametro de salida el identificador recien generado.

DE PROGRA II: `SCOPE_IDENTITY()` es una funcion del motor que
devuelve el ultimo valor de identidad (autoincremental) generado en
el mismo ambito. Devuelve un tipo numerico amplio, por eso se hace
`CAST(... AS INT)` para guardarlo como entero. El parametro `OUTPUT`
es el valor de retorno: quien llama al procedimiento lee ahi el
`IdUsuario` sin tener que hacer otra consulta.

FRAME A FRAME
```
 entra @NombreUsuario, @ApellidoUsuario, @RolUsuario
   |
   v
 INSERT INTO Usuarios (...) VALUES (...)   inserta la fila
   |
   v
 la base genera IdUsuario automaticamente (identidad)
   |
   v
 SCOPE_IDENTITY() lee ese numero --> CAST a INT
   |
   v
 SET @IdUsuario = ese numero    (sale por referencia al que llamo)
```

Por que devolver el id por `OUTPUT` y no con un `SELECT`: porque
quien dio el alta casi siempre necesita ese identificador para el
paso siguiente (por ejemplo, insertar una fila hija que apunta al
padre). Devolverlo por parametro lo deja disponible de inmediato.

### Plantilla 2: el Read (consulta con filtro opcional)

INTUICION: el Read recibe un identificador opcional. Si no se pasa,
trae todas las filas; si se pasa, trae solo la fila de ese
identificador. Un mismo procedimiento sirve para listar todo y para
buscar uno.

Se toma como modelo `sp_Usuarios_Read` [L358-L365]. La clave es el
parametro con valor por defecto y la condicion del `WHERE`:

- `@IdUsuario INT = NULL` [L359]: el `= NULL` lo vuelve opcional.
  Quien llama puede omitirlo.
- `WHERE (@IdUsuario IS NULL OR IdUsuario = @IdUsuario)` [L364].

DE PROGRA II: ese `WHERE` es un `if/else` escrito como una sola
expresion booleana. La condicion tiene dos ramas unidas por `OR`:
si `@IdUsuario` vale `NULL`, la primera rama es verdadera y se
cumple para toda fila (no filtra nada); si `@IdUsuario` trae un
numero, la primera rama es falsa y manda la segunda, `IdUsuario =
@IdUsuario`, que deja pasar solo la fila con ese identificador.

FRAME A FRAME
```
 entra @IdUsuario
   |
   v
 @IdUsuario IS NULL ?
   |                \
  si                 no
   |                  \
 toda fila pasa     pasa solo IdUsuario = @IdUsuario
   |                  /
   v                 v
 SELECT de las filas que pasaron
```

Tabla de verdad del filtro opcional. La condicion por fila es
`(@IdUsuario IS NULL OR IdUsuario = @IdUsuario)`.

```
 caso A: @IdUsuario = NULL   (no se paso filtro)
 fila IdUsuario   IS NULL?   col = @p?   pasa?
   1                V          -           SI
   2                V          -           SI
   3                V          -           SI
 resultado: trae TODAS las filas

 caso B: @IdUsuario = 3      (se paso filtro)
 fila IdUsuario   IS NULL?   col = @p?   pasa?
   1                F          F           NO
   2                F          F           NO
   3                F          V           SI
 resultado: trae SOLO la fila 3
```

La N:N `sp_MaterialesSistemasArmas_Read` [L494-L501] extiende la
misma idea a dos columnas: encadena dos condiciones opcionales con
`AND`, una por `@IdSistemaArmas` y otra por `@NNE`. Cada parametro
puede ir o no de forma independiente.

### Variantes del Insert

INTUICION: las 12 tablas usan el mismo molde de Insert; lo unico que
cambia es si protegen el alta con `TRY/CATCH`, si la clave la genera
la base o la trae el usuario, y si la clave es simple o compuesta.

Variante TRY/CATCH con THROW. Las tablas con claves foraneas o
restricciones que pueden fallar envuelven el `INSERT` en
`BEGIN TRY ... END TRY BEGIN CATCH THROW; END CATCH`. Ejemplos:
`sp_CatalogoMateriales_Insert` [L466-L470],
`sp_InventarioFisico_Insert` [L511-L516],
`sp_Tarjetas_Insert` [L538-L543].

DE PROGRA II: `TRY/CATCH` es manejo de excepciones, igual que en
Programacion II. `THROW` sin argumentos re-lanza el mismo error que
ocurrio, sin enmascararlo. El alta o se hace entera o falla con su
error original; no deja un estado a medias.

Variante sin `SCOPE_IDENTITY`: el catalogo. En
`sp_CatalogoMateriales_Insert` [L461-L471] la clave primaria es
`@NNE`, un codigo que aporta el usuario (clave natural), no un
autoincremental. Como la clave no la genera la base, no hay nada que
devolver: el procedimiento no tiene parametro `OUTPUT` ni usa
`SCOPE_IDENTITY()`. Quien llamo ya conoce el `NNE` que paso.

Variante N:N sin `OUTPUT`: la relacion. En
`sp_MaterialesSistemasArmas_Insert` [L484-L492] la tabla es toda
clave: la clave primaria es la combinacion (`@IdSistemaArmas`,
`@NNE`). No hay columna de identidad, asi que tampoco hay
`SCOPE_IDENTITY()` ni `OUTPUT`. Solo inserta el par dentro de
`TRY/CATCH`.

```
 ANTES de mirar el codigo            DESPUES de mirarlo
 "son 24 procedimientos"            son 2 plantillas + 3 ajustes
                                     - protege con TRY/CATCH o no
                                     - id por OUTPUT o clave natural
                                     - clave simple o compuesta
```

### Las 12 tablas, plantilla por plantilla

INTUICION: esta tabla es el mapa. Cada fila es una tabla del
modelo; las columnas dicen que variante usa su Insert y confirman
que su Read es siempre la misma plantilla del filtro opcional.

```
TRY = el Insert envuelve en TRY/CATCH con THROW
OUT = el Insert devuelve el id por parametro OUTPUT (SCOPE_IDENTITY)
```

| Tabla | Insert: variante | Read: filtro opcional |
|---|---|---|
| Usuarios [L348] | OUT, sin TRY | por @IdUsuario [L358] |
| TiposElemento [L369] | OUT, sin TRY | por @IdTipoElemento [L377] |
| SistemasArmas [L387] | OUT, sin TRY | por @IdSistemaArmas [L395] |
| EstadosElemento [L405] | OUT, sin TRY | por @IdEstadoElemento [L413] |
| Ubicaciones [L423] | OUT, sin TRY | por @IdUbicacion [L433] |
| MotivosSalida [L443] | OUT, sin TRY | por @IdMotivoSalida [L451] |
| CatalogoMateriales [L461] | TRY, clave natural NNE, sin OUT | por @NNE [L473] |
| MaterialesSistemasArmas [L484] | TRY, clave compuesta, sin OUT | por @IdSistemaArmas y @NNE [L494] |
| InventarioFisico [L505] | TRY + OUT | por @IdItem [L519] |
| Tarjetas [L530] | TRY + OUT | por @IdTarjeta [L546] |
| MovimientosInventario [L558] | TRY + OUT | por @IdMovimiento [L572] |
| Salidas [L583] | TRY + OUT | por @IdSalida [L598] |

Lectura del mapa: las seis tablas de arriba son catalogos simples
con identidad autoincremental, sin claves foraneas riesgosas, por
eso usan OUT y omiten el `TRY/CATCH`. Las dos del medio rompen el
molde del id: el catalogo usa clave natural y la N:N usa clave
compuesta, asi que ninguna devuelve OUT. Las cuatro de abajo son
tablas con claves foraneas, por eso combinan `TRY/CATCH` con OUT.

TRAMPA: en `sp_Tarjetas_Insert` [L537] y en `sp_Salidas_Insert`
[L589] hay comentarios sobre tarjeta activa y sobre el trigger
`trg_salida_abre`. Esos comentarios describen efectos que ocurren
alrededor del alta (logica de negocio y un trigger), no algo que el
Insert haga por si mismo. El procedimiento solo inserta la fila.

QUE TE PUEDEN PREGUNTAR

- Por que el Read trae todo cuando no se pasa filtro?
  Porque el `WHERE (@p IS NULL OR col = @p)`: con `@p` en `NULL` la
  primera rama es verdadera para toda fila, asi que no filtra nada.

- Que hace `SCOPE_IDENTITY()` y por que el `CAST`?
  Devuelve el ultimo id autoincremental generado en el mismo ambito;
  el `CAST(... AS INT)` lo guarda como entero en el parametro
  `OUTPUT` [L355].

- Por que `sp_CatalogoMateriales_Insert` no tiene `OUTPUT`?
  Porque su clave primaria es el `NNE`, un codigo natural que aporta
  el usuario; la base no genera nada que devolver [L461-L471].

- Por que la N:N `MaterialesSistemasArmas` no usa `SCOPE_IDENTITY`?
  Porque la tabla es toda clave (clave compuesta `IdSistemaArmas` +
  `NNE`), no tiene columna de identidad [L484-L492].

- Para que sirve el `TRY/CATCH` con `THROW` en algunos Insert?
  Para no enmascarar errores: si el `INSERT` falla (por ejemplo, una
  clave foranea invalida), `THROW` re-lanza el error original al que
  llamo [L466-L470].

- Como filtra el Read de la N:N por dos campos?
  Encadena dos condiciones opcionales con `AND`, una por
  `@IdSistemaArmas` y otra por `@NNE`; cada una es independiente
  [L499-L500].

---

## Parte 4 - Vistas

INTUICION: una vista es una consulta guardada con nombre; no almacena datos propios, se recalcula cada vez que la consultas, como una funcion que devuelve una tabla en lugar de un unico valor.

Una vista (`VIEW`) es una consulta `SELECT` a la que se le da un nombre y se guarda en la base. Cuando se la consulta (por ejemplo `SELECT * FROM vw_stock_disponible`), el motor ejecuta el `SELECT` interno en ese momento contra las tablas reales. No hay copia de datos: lo que se ve siempre refleja el estado actual de las tablas base. Se comporta como una tabla virtual; se la puede usar dentro de otro `SELECT`, con `JOIN`, con `WHERE`, igual que a una tabla.

DE PROGRA II: pensa la vista como una funcion sin parametros que retorna una tabla. El cuerpo es el `SELECT`; el valor de retorno es el conjunto de filas. Como no guarda estado, cada llamada recalcula el resultado.

INTUICION: vw_stock_disponible responde una sola pregunta operativa: que ejemplares estan listos para usar y dentro del deposito, ahora.

La vista `vw_stock_disponible` se define con `CREATE VIEW ... AS` seguido de un `SELECT` [L612-L624]. Ese `SELECT` arma una fila por ejemplar disponible combinando tres tablas:

- `InventarioFisico`: el ejemplar fisico (su `IdItem`, numero de serie, tamano) [L613, L616-L617].
- `CatalogoMateriales`: el dato de catalogo (codigo `NNE` y designacion) [L614-L615], unido con `JOIN ... ON CatalogoMateriales.NNE = InventarioFisico.NNE` [L621].
- `Ubicaciones`: deposito y sector fisico [L618-L619], unido con `JOIN ... ON Ubicaciones.IdUbicacion = InventarioFisico.IdUbicacion` [L622].

El filtro vive en el `WHERE` [L623-L624] y tiene dos condiciones unidas con `AND`:

- `dbo.fn_EstadoActual(InventarioFisico.IdItem) = 'EN_SERVICIO'`: para cada ejemplar se invoca la funcion escalar que devuelve el estado de su tarjeta activa, y se conservan solo los que estan en servicio.
- `InventarioFisico.IdUbicacion IS NOT NULL`: se descartan los ejemplares sin ubicacion asignada, es decir, los que estan fuera del deposito.

DE PROGRA II: el `WHERE` es un if que decide fila por fila si pasa o no. La llamada `dbo.fn_EstadoActual(IdItem)` es exactamente una llamada a funcion: recibe un parametro y devuelve un valor que se compara con `'EN_SERVICIO'`.

FRAME A FRAME (embudo de filtrado)
```
 InventarioFisico completo
   |   (todos los ejemplares registrados)
   v
 JOIN CatalogoMateriales y JOIN Ubicaciones
   |   (se agregan datos de catalogo y de deposito)
   v
 WHERE fn_EstadoActual(IdItem) = 'EN_SERVICIO'
   |   quita los que NO estan en servicio
   v
 AND IdUbicacion IS NOT NULL
   |   quita los que estan afuera (sin ubicacion)
   v
 stock realmente disponible
```

Nota: la vista no guarda este resultado. Cada vez que se la consulta, el embudo se recalcula desde cero contra las tablas actuales. Si una tarjeta cambia de estado o un ejemplar pierde su ubicacion, la proxima consulta ya lo refleja sin tener que actualizar nada.

INTUICION: la vista de stock reusa la funcion escalar para no repetir la logica de cual es la tarjeta activa.

Saber si un ejemplar esta en servicio no es trivial: hay que encontrar su tarjeta activa (`ActivaTarjeta = 1`) y leer el codigo de estado. Esa logica ya esta encapsulada en `dbo.fn_EstadoActual`. La vista la llama en su `WHERE` [L623] en lugar de reescribir ese `JOIN` y ese filtro. Beneficio: una sola definicion de estado actual. Si manana cambia la regla de cual tarjeta es la vigente, se corrige la funcion y la vista queda corregida sin tocarla.

DE PROGRA II: es el principio de no repetir codigo. La vista llama a una funcion ya escrita en vez de copiar su cuerpo; un solo lugar para mantener.

INTUICION: vw_historial_tarjetas no filtra nada; muestra todas las tarjetas de cada ejemplar, las viejas y la activa.

La vista `vw_historial_tarjetas` se define en [L628-L638]. Su `SELECT` toma `Tarjetas` y la une a `EstadosElemento` con `JOIN ... ON EstadosElemento.IdEstadoElemento = Tarjetas.IdEstadoElemento` [L637-L638]. Ese `JOIN` traduce el identificador interno de estado (`IdEstadoElemento`) a su codigo legible.

Columnas devueltas: `IdItem`, `IdTarjeta`, el codigo de estado, fecha de emision, orden de trabajo, causas, inspector y `ActivaTarjeta` [L629-L636]. La columna del estado usa un alias con `AS`: `EstadosElemento.CodigoEstadoElemento AS Estado` [L631]. El alias renombra la columna en el resultado, de modo que en la salida aparece como `Estado` y no con el nombre largo original.

DE PROGRA II: el alias `AS` es como asignar a una variable con nombre mas corto el valor de una expresion; el dato es el mismo, cambia la etiqueta con que se lo nombra en el resultado.

Diferencia clave con la vista anterior: `vw_historial_tarjetas` no tiene `WHERE`. Al no filtrar, devuelve todas las tarjetas de todos los ejemplares. La columna `ActivaTarjeta` permite distinguir, dentro de ese historial, cual es la tarjeta vigente (`ActivaTarjeta = 1`) y cuales son antecedentes.

FRAME A FRAME (sin filtro = historial completo)
```
 Tarjetas (todas las filas, activas e inactivas)
   |
   v
 JOIN EstadosElemento  (traduce IdEstadoElemento a su codigo)
   |
   v
 (no hay WHERE: no se descarta ninguna fila)
   |
   v
 historial completo; ActivaTarjeta marca la vigente con 1
```

QUE TE PUEDEN PREGUNTAR
- Una vista guarda datos? No. Guarda la consulta; los datos se leen de las tablas base cada vez que se la consulta y reflejan el estado actual.
- Por que vw_stock_disponible llama a fn_EstadoActual en vez de escribir el filtro a mano? Para no repetir la logica de cual es la tarjeta activa; queda en un solo lugar y se mantiene una sola vez [L623].
- Que hacen las dos condiciones del WHERE de vw_stock_disponible? La primera deja solo ejemplares en servicio; la segunda descarta los que no tienen ubicacion (estan fuera del deposito) [L623-L624].
- Por que vw_historial_tarjetas muestra tarjetas viejas? Porque no tiene clausula `WHERE`; al no filtrar, devuelve el historial completo y `ActivaTarjeta` indica cual es la vigente.
- Para que sirve el AS en la columna del estado? Es un alias: renombra `CodigoEstadoElemento` como `Estado` en el resultado, sin cambiar el dato [L631].
- Que pasa si cambian los datos de las tablas despues de crear la vista? La proxima consulta a la vista ya muestra los datos nuevos, porque se recalcula al consultarla; no hay que actualizar la vista.

---

## Parte 5 - Carga de datos de ejemplo

INTUICION: esta parte no crea estructura ni logica nueva, solo mete datos
de prueba en las tablas que ya existen, y los mete en un orden que respeta
las dependencias entre ellas. La idea: cargar primero lo que nadie necesita
(las tablas maestras) y dejar para el final lo que apunta a varias tablas a
la vez.

La carga arranca con un comentario que rotula la seccion [L641]. A partir de
ahi, cada bloque es un INSERT que llena una tabla.

### INSERT multi-fila (varias filas en un VALUES)

INTUICION: en vez de escribir un INSERT por cada fila, se escribe uno solo y
se listan todas las filas separadas por comas. Es la misma operacion repetida,
agrupada para escribir menos.

Un INSERT multi-fila tiene esta forma: la palabra `INSERT INTO`, el nombre de
la tabla, la lista de columnas entre parentesis, la palabra `VALUES`, y luego
una fila por cada juego de valores, separadas por coma. La tabla Usuarios se
carga asi con 12 filas en un solo `INSERT` [L644-L656]. Cada renglon entre
parentesis es una fila: `('Pablo', 'Cardozo', 'Encargado de deposito')` es la
primera [L645].

DE PROGRA II: pensalo como una sola llamada a una funcion que recibe una lista
de tuplas, en lugar de doce llamadas iguales con una tupla cada una. El
resultado es el mismo, el codigo es mas corto.

FRAME A FRAME
```
 INSERT INTO Usuarios (NombreUsuario, ApellidoUsuario, RolUsuario)
 VALUES
   ('Pablo','Cardozo','Encargado de deposito'),  <- fila 1
   ('Ana','Gomez','Cargador de datos'),          <- fila 2
   ...                                            <- ... hasta 12
   ('Valeria','Castro','Control de calidad');     <- fila 12
   |
   v
 el motor inserta las 12 filas en una sola operacion
```

Solo se nombran las columnas que se cargan a mano. Las que no aparecen las
completa la base: la clave primaria autonumerada y los valores por defecto.
Por eso en Usuarios no se escribe el IdUsuario, lo pone la tabla.

### Orden de carga segun dependencias

INTUICION: una tabla que apunta a otra (clave foranea) no se puede cargar
antes que la tabla a la que apunta, porque el valor al que apunta todavia no
existe. Entonces se cargan primero las tablas independientes y al final las
que dependen de varias.

Una clave foranea es una columna que guarda el identificador de una fila de
otra tabla. Si InventarioFisico guarda un NNE que tiene que existir en
CatalogoMateriales, primero hay que cargar CatalogoMateriales. El script
respeta ese orden:

```
 1. Usuarios            [L644]   tabla maestra, no depende de nadie
 2. TiposElemento       [L660]   tabla maestra
 3. SistemasArmas       [L667]   tabla maestra
 4. Ubicaciones         [L675]   tabla maestra
       |
       v
 5. CatalogoMateriales  [L689]   apunta a TiposElemento y Usuarios
       |
       v
 6. MaterialesSistemasArmas [L705] cruza Catalogo y SistemasArmas (n:n)
       |
       v
 7. InventarioFisico    [L715]   apunta a Catalogo y Ubicaciones
       |
       v
 8. Tarjetas (activas) [L734] apuntan a InventarioFisico y EstadosElem.
 9. Tarjetas (segundas) [L753]   mismas tablas, generan historial
       |
       v
 10. Salidas            [L762]   apuntan a InventarioFisico y motivos
 11. MovimientosInventario [L778] apuntan a Item, Ubicacion y Usuario
```

CatalogoMateriales se carga recien en el quinto bloque porque cada fila usa
un IdTipoElemento y un IdUsuario que tienen que existir antes [L689-L701].
Por ejemplo `('1560-AR-001', 'PN-7788', 'Bomba hidraulica', '29', 7, 1)` usa
el tipo 7 y el usuario 1, que ya se cargaron en los pasos 1 y 2 [L690].

TRAMPA: el comentario de la linea [L688] aclara que el ATA es un codigo
numerico que valida un `CHECK`. No confundir: el dato se guarda como texto
(`'29'`), pero la restriccion `CHECK` definida antes obliga a que sean digitos.
El INSERT no define el `CHECK`, solo aporta valores que lo cumplen.

### IDENTITY autonumera IdItem de 1 a 15

INTUICION: la columna IdItem no se carga a mano. La tabla tiene la propiedad
IDENTITY, que es un contador automatico: cada fila nueva recibe el siguiente
numero sin que nadie se lo pase.

InventarioFisico se carga con 15 filas y el INSERT solo nombra NNE,
NumeroSerieItem, FechaVencimientoItem, TamanoItem e IdUbicacion [L715]. El
IdItem no aparece en la lista de columnas: lo asigna la base. Como es la
primera carga, la primera fila queda con IdItem = 1 y la decimoquinta con
IdItem = 15.

DE PROGRA II: es como un contador global que arranca en 1 y hace mas mas en
cada insercion. El programador no lo toca, solo lee el valor que quedo.

FRAME A FRAME
```
 fila cargada                          IdItem que asigna IDENTITY
 ('1560-AR-001','SN-BH-001',...)  -->  1
 ('1560-AR-001','SN-BH-002',...)  -->  2
 ('2620-AR-014','SN-VC-010',...)  -->  3
 ...                                    ...
 ('5340-AR-077','SN-JB-401',...)  -->  15
```

Este punto importa porque los bloques que siguen (Tarjetas, Salidas,
Movimientos) referencian a los ejemplares por ese IdItem 1 a 15. La fila de
Tarjetas `(1, 1, 'Luis Perez', 1)` apunta al ejemplar que IDENTITY numero 1
[L735]. Por eso el orden de carga y el autonumerado tienen que coincidir: el
script sabe de antemano que el primer ejemplar es el 1 porque controla el
orden de insercion.

### Dos tandas de Tarjetas (activas e historial)

INTUICION: una tarjeta es el registro del estado de un ejemplar en un momento.
Un ejemplar puede tener varias tarjetas a lo largo del tiempo, pero solo una
vigente. La columna ActivaTarjeta marca cual es la vigente con 1, y las
viejas con 0.

La primera tanda inserta una tarjeta por cada uno de los 15 ejemplares
[L734-L749]. El comentario aclara el significado del estado: 1 en servicio,
2 transitorio, 3 baja [L733]. Casi todas entran con ActivaTarjeta = 1, pero
cuatro entran con ActivaTarjeta = 0: los items 5, 6, 10 y 14
[L739, L740, L744, L748]. Esas cuatro quedan apagadas a proposito, porque la
segunda tanda les va a poner una tarjeta nueva activa.

La segunda tanda inserta cuatro tarjetas mas, justamente para esos mismos
items 5, 14, 6 y 10, ahora con ActivaTarjeta = 1 y un estado distinto
[L753-L757]. Asi cada uno de esos ejemplares termina con dos tarjetas: la
vieja (Activa 0) y la nueva (Activa 1). Eso genera historial: se ve de donde
viene y donde esta ahora.

FRAME A FRAME
```
 ejemplar 5
   primera tanda:  tarjeta estado 1 (en servicio)  Activa = 0  <- vieja
   segunda tanda: tarjeta estado 2 (transitorio) Activa=1 <- vigente

 ejemplar 6
   primera tanda:  tarjeta estado 1  Activa = 0  <- vieja
   segunda tanda:  tarjeta estado 3 (baja)  Activa = 1  <- vigente
```

Los items que en la primera tanda ya entraron con Activa = 1 (por ejemplo el
1, el 2, el 3) no reciben segunda tarjeta: su unica tarjeta es la vigente.

### Salidas con y sin FechaRetornoSalida y el trigger trg_salida_abre

INTUICION: registrar una salida es anotar que un ejemplar se fue del deposito.
Si tiene fecha de retorno, ya volvio. Si no la tiene, sigue afuera, y el
ejemplar no puede figurar en una ubicacion fisica del deposito.

El bloque de Salidas carga 12 filas [L762-L774]. Cada fila trae FechaSalida
y, en la ultima columna, FechaRetornoSalida, que puede ser una fecha o `NULL`.
`NULL` es el valor que representa ausencia de dato. Hay dos grupos:

- Salidas abiertas (sin retorno): FechaRetornoSalida en `NULL`. Son los items
  3, 8, 11, 13 [L763-L766] y las dos bajas a Rezago, items 6 y 10
  [L771, L772]. Estos ejemplares estan afuera.
- Salidas cerradas (con retorno): traen fecha real en la ultima columna. Son
  los items 4, 7, 9, 15, 1 y 12 [L767-L770, L773, L774]. Ya volvieron.

Aca se cierra el lazo con la Parte 2. El comentario lo dice [L761]: las
salidas sin fecha de retorno disparan el trigger trg_salida_abre, que les
pone IdUbicacion en `NULL`. Un trigger es codigo que la base ejecuta sola
cuando ocurre un INSERT, sin que el script lo llame.

FRAME A FRAME
```
 INSERT en Salidas, item 3, FechaRetornoSalida = NULL  [L763]
   |
   v
 trg_salida_abre detecta que la salida esta abierta (sin retorno)
   |
   v
 UPDATE InventarioFisico: el item 3 queda con IdUbicacion = NULL
   |
   v
 resultado: el ejemplar 3 ya no apunta a ninguna estanteria
```

ANTES / DESPUES del INSERT de una salida abierta:
```
 ANTES (cargado en el paso 7)        DESPUES del INSERT en Salidas
 InventarioFisico                    InventarioFisico
   item 3 --> IdUbicacion 2            item 3 --> IdUbicacion NULL
                                 (lo cambio el trigger, no el INSERT)
```

Las salidas cerradas no tocan la ubicacion: el ejemplar volvio, sigue en su
estanteria. El INSERT de Salidas es siempre el mismo, pero el efecto depende
de si la fila trae retorno o no, porque quien decide es el trigger.

### Por que carga directa y no procedimientos

INTUICION: los datos de ejemplo se meten con INSERT directo porque es la forma
mas simple y controlada de poblar tablas. Los procedimientos sirven para la
operacion real del sistema, no para sembrar datos de prueba.

Todo el bloque de carga usa INSERT directo, incluido InventarioFisico [L714].
Esto da control total: se elige a mano cada IdUbicacion, cada estado, cuales
tarjetas quedan activas y cuales salidas quedan abiertas. Un procedimiento
como sp_AltaElemento aplica su propia logica fija (crea ejemplar mas tarjeta
en servicio) y no permite armar a mano los casos de prueba variados que la
demostracion necesita, como un ejemplar dado de baja o uno con dos tarjetas.

### MovimientosInventario

El ultimo INSERT carga 10 movimientos de inventario: recuentos,
reubicaciones y controles [L778-L788]. Cada fila apunta a un IdItem (1 a 15),
una IdUbicacion, una accion en texto y el IdUsuarioRegistra que la hizo. Es la
bitacora de lo que paso con cada ejemplar dentro del deposito.

### Demo de sp_AltaElemento con DECLARE @nuevo y @IdItem OUTPUT

INTUICION: despues de la carga directa, el script muestra una vez como se
usaria el procedimiento en la operacion real. Lo importante es como recupera
el identificador del ejemplar que el procedimiento acaba de crear.

Un parametro OUTPUT es un parametro de salida: el procedimiento escribe un
valor en una variable que le pasa quien lo llama, y al volver esa variable
queda con el valor. (Analogia tecnica: es pasar por referencia, como en
Programacion II.)

El bloque hace dos cosas [L792-L794]. Primero `DECLARE @nuevo INT` crea una
variable vacia que va a recibir el id [L792]. Despues `EXEC sp_AltaElemento`
llama al procedimiento con los datos del ejemplar nuevo, y en el ultimo
argumento pasa `@IdItem = @nuevo OUTPUT` [L793-L794]. La palabra `OUTPUT`
indica que ese argumento no entra dato, sale dato: el procedimiento va a
escribir el IdItem recien creado dentro de @nuevo.

DE PROGRA II: es exactamente una funcion que en vez de devolver con return,
recibe una variable por referencia y la deja modificada. Antes de la llamada
@nuevo esta en NULL; despues de la llamada @nuevo tiene el numero.

FRAME A FRAME
```
 DECLARE @nuevo INT;          @nuevo = NULL  (vacia)
   |
   v
 EXEC sp_AltaElemento ..., @IdItem = @nuevo OUTPUT;
   |
   v
 dentro del procedimiento: INSERT en InventarioFisico
   IDENTITY asigna el id 16 (siguiente al 15)
   el procedimiento copia 16 en el parametro OUTPUT
   |
   v
 al volver:                   @nuevo = 16
```

Asi se cierra el lazo del OUTPUT: el ejemplar nuevo recibe su IdItem por
IDENTITY adentro del procedimiento, y ese numero viaja de vuelta a @nuevo por
el parametro de salida. Quien llamo al procedimiento ahora sabe que id se
genero sin tener que consultar la tabla.

QUE TE PUEDEN PREGUNTAR
- Por que se cargan las tablas en ese orden y no en cualquiera?
  Porque las claves foraneas obligan: una tabla que apunta a otra se carga
  despues de la tabla a la que apunta. Maestras primero, dependientes despues.
- Por que el INSERT de InventarioFisico no incluye la columna IdItem?
  Porque IdItem es IDENTITY: la base lo autonumera sola, del 1 al 15 en esta
  carga. Si se intentara cargar a mano, normalmente fallaria.
- Para que sirven las segundas tarjetas?
  Para generar historial: dejan al ejemplar con una tarjeta vieja (Activa 0) y
  una nueva vigente (Activa 1) con otro estado. Afectan a los items 5,14,6,10.
- Que pasa con una salida sin FechaRetornoSalida?
  El trigger trg_salida_abre se dispara y pone IdUbicacion en NULL en
  InventarioFisico: el ejemplar queda registrado como fuera del deposito.
- Por que usar INSERT directo y no sp_AltaElemento para toda la carga?
  Porque el INSERT directo permite armar casos de prueba variados (bajas, dos
  tarjetas, salidas abiertas) que la logica fija del procedimiento no arma.
- Como recupera el script el id del ejemplar creado por sp_AltaElemento?
  Con un parametro OUTPUT: declara @nuevo, lo pasa como @IdItem OUTPUT, y al
  volver @nuevo contiene el IdItem que IDENTITY genero dentro del procedimiento.

---

## Parte 6 - Consultas (1 de 2): agregacion y conjuntos

Esta seccion explica seis consultas de demostracion del script
[L796-L846]. Cada una muestra una construccion distinta: agrupar y
filtrar grupos, probar existencia, y operar sobre conjuntos de filas.

### Q1 - GROUP BY mas HAVING con COUNT

INTUICION: agrupar es repartir las filas en baldes segun una clave y
contar cuantas cayeron en cada balde; HAVING descarta baldes enteros.

La consulta [L800-L804] cuenta cuantos ejemplares hay por estado
actual, y deja solo los estados con mas de un ejemplar.

Paso a paso de las clausulas:

- `SELECT dbo.fn_EstadoActual(InventarioFisico.IdItem) AS Estado,
  COUNT(*) AS Cantidad` [L800]: por cada grupo devuelve la clave (el
  estado) y la cantidad de filas del grupo. `COUNT(*)` es una funcion
  de agregacion: recibe todas las filas del grupo y devuelve un numero.
- `fn_EstadoActual` es la funcion escalar definida antes en el script.
  DE PROGRA II: es una funcion comun, recibe un `IdItem` y devuelve un
  valor unico (el codigo de estado). Aca se la usa como si fuera una
  columna calculada.
- `FROM InventarioFisico` [L801]: la tabla de la que salen las filas.
- `GROUP BY dbo.fn_EstadoActual(InventarioFisico.IdItem)` [L802]:
  define la clave de agrupamiento. Filas con el mismo estado caen en el
  mismo balde. La expresion de agrupamiento es la misma funcion que en
  el `SELECT`; por eso aparece repetida.
- `HAVING COUNT(*) > 1` [L803]: filtra grupos ya formados. Conserva
  solo los baldes con mas de una fila.
- `ORDER BY Cantidad DESC` [L804]: ordena el resultado final por la
  columna `Cantidad` de mayor a menor. Se puede usar el alias porque
  `ORDER BY` se evalua despues del `SELECT`.

FRAME A FRAME
```
 filas de InventarioFisico
   |
   v
 GROUP BY estado  (reparte en baldes por clave)
   EN_SERVICIO : item1 item4 item9
   EN_REPARACION: item2
   BAJA         : item3 item7
   |
   v
 COUNT(*) por balde
   EN_SERVICIO  = 3
   EN_REPARACION= 1
   BAJA         = 2
   |
   v
 HAVING COUNT(*) > 1  (descarta baldes chicos)
   EN_SERVICIO = 3   queda
   EN_REPARACION=1   se descarta
   BAJA        = 2   queda
   |
   v
 ORDER BY Cantidad DESC
   EN_SERVICIO 3
   BAJA        2
```

WHERE vs HAVING: `WHERE` filtra filas individuales ANTES de agrupar;
`HAVING` filtra grupos DESPUES de agrupar y por eso puede usar
funciones de agregacion como `COUNT(*)`. No se puede poner
`COUNT(*) > 1` en un `WHERE` porque en ese momento todavia no existen
los grupos.

### Q2 - NOT EXISTS

INTUICION: por cada fila candidata se manda una sonda a otra tabla;
`NOT EXISTS` deja pasar la fila solo si la sonda no encontro nada.

La consulta [L809-L812] lista los ejemplares que nunca salieron del
deposito.

- `SELECT InventarioFisico.IdItem,
  CatalogoMateriales.DesignacionMaterial,
  InventarioFisico.NumeroSerieItem` [L809] con
  `JOIN CatalogoMateriales ON CatalogoMateriales.NNE =
  InventarioFisico.NNE` [L811]: arma la fila candidata con datos del
  ejemplar y su designacion del catalogo.
- `WHERE NOT EXISTS (SELECT 1 FROM Salidas WHERE Salidas.IdItem =
  InventarioFisico.IdItem)` [L812]: por cada ejemplar revisa si hay
  alguna fila en `Salidas` con ese `IdItem`. Si no hay ninguna, la
  condicion es verdadera y el ejemplar entra al resultado.

La subconsulta es correlacionada: usa `InventarioFisico.IdItem`, un
valor de la fila externa. El `SELECT 1` no devuelve datos utiles;
`EXISTS` solo mira si hay al menos una fila, no le importa que columnas.

FRAME A FRAME
```
 item 7  --> sonda: hay salida con IdItem=7 ?  no  --> entra
 item 4  --> sonda: hay salida con IdItem=4 ?  si  --> se descarta
 item 9  --> sonda: hay salida con IdItem=9 ?  no  --> entra
```

### Q3 - EXISTS

INTUICION: misma sonda fila por fila que Q2, pero al reves: `EXISTS`
deja pasar la fila cuando la sonda SI encuentra algo.

La consulta [L817-L819] lista las ubicaciones que guardan al menos un
elemento.

- `SELECT Ubicaciones.IdUbicacion, Ubicaciones.DepositoUbicacion,
  Ubicaciones.SectorUbicacion FROM Ubicaciones` [L817-L818]: las filas
  candidatas son las ubicaciones.
- `WHERE EXISTS (SELECT 1 FROM InventarioFisico WHERE
  InventarioFisico.IdUbicacion = Ubicaciones.IdUbicacion)` [L819]: por
  cada ubicacion revisa si hay algun ejemplar guardado ahi. Si hay al
  menos uno, la ubicacion entra.

FRAME A FRAME
```
 ubic A  --> sonda: hay item con IdUbicacion=A ?  si --> entra
 ubic B  --> sonda: hay item con IdUbicacion=B ?  no --> se descarta
 ubic C  --> sonda: hay item con IdUbicacion=C ?  si --> entra
```

Diferencia EXISTS vs IN: `EXISTS` evalua una subconsulta correlacionada
y corta apenas encuentra una fila. `IN` compara una columna contra una
lista de valores. Con valores `NULL` en la lista, `NOT IN` puede dar
resultados inesperados (toda comparacion contra `NULL` es desconocida),
mientras que `NOT EXISTS` se mantiene predecible. Por eso, para filtrar
por existencia conviene `EXISTS` / `NOT EXISTS`.

### Q4 - UNION de tres SELECT

INTUICION: apilar tres listas una abajo de la otra y, como es `UNION`,
quitar las filas repetidas del resultado combinado.

La consulta [L824-L832] arma una lista unica de personas que aparecen
en el sistema, tomadas de tres origenes.

- Primer `SELECT` [L824-L825]: `CONCAT(NombreUsuario, ' ',
  ApellidoUsuario) AS Persona, 'Usuario del sistema' AS Origen`.
  `CONCAT` pega textos en uno solo; trata los `NULL` como cadena vacia.
  La columna `Origen` es un texto fijo que marca de donde salio la fila.
- `UNION` [L826] apila el siguiente `SELECT`.
- Segundo `SELECT DISTINCT InspectorTarjeta, ... FROM Tarjetas WHERE
  InspectorTarjeta IS NOT NULL` [L827-L828]: inspectores de tarjetas,
  descartando los nulos.
- `UNION` [L829] y tercer `SELECT DISTINCT RetiradoPorSalida, ... FROM
  Salidas WHERE RetiradoPorSalida IS NOT NULL` [L830-L831]: quien
  retiro material.
- `ORDER BY Persona` [L832]: ordena el resultado combinado. El
  `ORDER BY` se aplica una sola vez, al final de todo el `UNION`.

Las tres consultas deben devolver la misma cantidad de columnas y tipos
compatibles, porque se apilan en columnas. Los nombres de columna del
resultado los fija el primer `SELECT` (`Persona`, `Origen`).

FRAME A FRAME
```
 lista 1 (Usuarios)        lista 2 (Tarjetas)   lista 3 (Salidas)
   Ana Perez                 Ana Perez            Luis Gomez
   Luis Gomez                Sara Diaz            Ana Perez
   |                         |                    |
   +----------- se apilan todas -------------------+
                       |
                       v
            UNION quita duplicados
              Ana Perez   (estaba 3 veces, queda 1)
              Luis Gomez  (estaba 2 veces, queda 1)
              Sara Diaz
```

Diferencia UNION vs UNION ALL: `UNION` elimina filas duplicadas (hace
un trabajo extra de ordenar y comparar). `UNION ALL` apila todo sin
quitar nada, es mas rapido. Aca se usa `UNION` porque se busca una
lista de personas sin repetir. El `DISTINCT` interno de cada `SELECT`
quita duplicados dentro de su propia lista; el `UNION` los quita entre
las tres.

### Q5 - INTERSECT

INTUICION: `INTERSECT` devuelve solo las filas que estan en las dos
listas a la vez, sin repetir.

La consulta [L837-L839] devuelve los `NNE` (numero de nomenclatura) que
estan en inventario y ademas estan asociados a un sistema de armas.

- `SELECT NNE FROM InventarioFisico` [L837]: primera lista.
- `INTERSECT` [L838].
- `SELECT NNE FROM MaterialesSistemasArmas` [L839]: segunda lista.

El resultado son los `NNE` presentes en ambas. Igual que `UNION`,
exige misma cantidad de columnas y tipos compatibles, y devuelve filas
sin duplicados.

### Q6 - EXCEPT

INTUICION: `EXCEPT` devuelve las filas de la primera lista que no estan
en la segunda; es una resta de conjuntos.

La consulta [L844-L846] devuelve los `NNE` del catalogo que no tienen
ningun ejemplar en inventario.

- `SELECT NNE FROM CatalogoMateriales` [L844]: lista de la que se resta.
- `EXCEPT` [L845].
- `SELECT NNE FROM InventarioFisico` [L846]: lo que se quita.

Diagrama de conjuntos de los tres operadores juntos (A es la lista de
arriba, B la de abajo):
```
        A                 B
   +---------+       +---------+
   | a1  a2  |  a3   | a3  b1  |
   |     a3  |  b1   | b1  b2  |
   +---------+       +---------+

 INTERSECT (A y B):  a3            (lo que esta en ambas)
 UNION (A o B):      a1 a2 a3 b1 b2 (todo, sin repetir)
 EXCEPT (A menos B): a1 a2         (lo de A que no esta en B)
```

QUE TE PUEDEN PREGUNTAR

- Por que `HAVING` y no `WHERE` en Q1? Porque `COUNT(*) > 1` es una
  condicion sobre el grupo ya formado; `WHERE` filtra filas antes de
  agrupar y ahi todavia no hay conteo.
- Por que la funcion `fn_EstadoActual` aparece en `SELECT` y en
  `GROUP BY`? Porque la columna calculada que se muestra tiene que ser
  la misma expresion por la que se agrupa; si no, el motor no sabe a
  que grupo pertenece.
- Diferencia entre `EXISTS` e `IN`? `EXISTS` prueba existencia con una
  subconsulta correlacionada y es seguro con `NULL`; `IN` compara
  contra una lista y `NOT IN` puede fallar si la lista tiene `NULL`.
- Por que `SELECT 1` adentro de `EXISTS`? Porque a `EXISTS` solo le
  importa si hay al menos una fila, no que columnas devuelve; el `1` es
  un valor cualquiera.
- Diferencia entre `UNION` y `UNION ALL`? `UNION` quita duplicados (mas
  trabajo); `UNION ALL` apila todo tal cual (mas rapido).
- Que pide `INTERSECT` y `EXCEPT` de los `SELECT`? Misma cantidad de
  columnas y tipos compatibles, igual que `UNION`; ambos devuelven
  filas sin duplicados.

---

## Parte 6 (continuacion) - Subconsultas, CASE, joins y pruebas

### Q7 - Subconsulta correlacionada

INTUICION: una subconsulta correlacionada es una consulta interna que se
vuelve a ejecutar una vez por cada fila de la consulta externa, porque la
interna depende de un dato de esa fila.

La consulta lista cada ejemplar del inventario junto con su material y, en
una columna calculada, la cantidad de tarjetas que tuvo en su historial
[L851-L855]. La columna `TarjetasHistoricas` es una subconsulta escalar
(devuelve un unico valor) que cuenta filas en `Tarjetas` cuyo `IdItem`
coincide con el `IdItem` de la fila externa que se esta procesando
[L852]. Esa referencia `Tarjetas.IdItem = InventarioFisico.IdItem` es lo
que la hace correlacionada: la interna usa un valor que viene de la
externa, asi que no se puede ejecutar sola.

DE PROGRA II: pensalo como un bucle. La consulta externa es el `for` que
recorre filas; por cada vuelta llama a una funcion `contarTarjetas(idItem)`
pasandole el `IdItem` de esa fila. El valor de retorno es un solo numero
que se pega como columna.

FRAME A FRAME
```
 recorre InventarioFisico fila por fila
   |
   v
 fila externa: IdItem = 5
   |
   v
 ejecuta la interna con ese valor:
   SELECT COUNT(*) FROM Tarjetas WHERE IdItem = 5  --> 3
   |
   v
 arma la fila de salida: IdItem 5 | material | 3
   |
   v
 pasa a la fila externa: IdItem = 6
   |
   v
 ejecuta la interna otra vez con IdItem = 6 --> 1
   (se repite una corrida interna por cada fila externa)
```

Contraste con una subconsulta NO correlacionada: esa no menciona ninguna
columna de la externa, se calcula una sola vez y su resultado se reutiliza
para todas las filas. Ejemplo de no correlacionada aparece en Q9, donde la
lista de `IdItem` con `IN (... GROUP BY ...)` se resuelve una vez
[L875]. La correlacionada de Q7 depende de la fila y por eso se reevalua.

El `ORDER BY TarjetasHistoricas DESC` ordena de mayor a menor historial
[L855].

### Q8 - CASE con funcion de fecha

INTUICION: `CASE WHEN ... THEN ...` es un if/else dentro de la consulta:
evalua condiciones en orden y devuelve el valor de la primera que se
cumple.

La consulta clasifica el vencimiento de cada ejemplar en una etiqueta de
texto `Situacion` [L860-L866]. Tres piezas se combinan:

- `CAST(SYSDATETIME() AS DATE)`: `SYSDATETIME()` devuelve la fecha y hora
  actual con su parte horaria; el `CAST(... AS DATE)` la convierte a solo
  fecha, descartando la hora [L863]. Asi la comparacion es dia contra dia
  y no se contamina con horas y minutos.
- `DATEDIFF(DAY, fechaInicio, fechaFin)`: devuelve cuantos dias hay entre
  dos fechas. Aca mide los dias entre hoy y la fecha de vencimiento
  [L864]; si el vencimiento esta adelante, el resultado es positivo.
- El `CASE`: la escalera de decision que combina todo.

DE PROGRA II: el `CASE` es literalmente una cadena `if / else if / else`.
El orden importa: se queda con el primer `WHEN` verdadero y no sigue
evaluando. El `ELSE` es el `else` final.

FRAME A FRAME (escalera de decision, se evalua de arriba hacia abajo)
```
 toma FechaVencimientoItem de la fila
   |
   v
 es NULL?
   si --> 'sin vencimiento'   (no tiene fecha cargada)
   no |
      v
 es menor que hoy?
   si --> 'vencido'           (la fecha ya paso)
   no |
      v
 faltan 180 dias o menos?  (DATEDIFF DAY <= 180)
   si --> 'por vencer'
   no |
      v
 ELSE --> 'vigente'          (falta mas de 180 dias)
```

El orden no es casual: primero descarta el `NULL` (sin `IS NULL` antes, las
comparaciones con `NULL` darian desconocido y caerian al `ELSE` mal
clasificadas), despues lo ya vencido, despues lo proximo, y lo que queda es
vigente. El `ORDER BY FechaVencimientoItem` muestra primero lo mas urgente
[L869].

### Q9 - Consultas sobre las dos vistas

INTUICION: una vista es una consulta guardada con nombre; se la trata como
si fuera una tabla (analogia: una variable que guarda el resultado de una
formula).

La primera linea consulta la vista `vw_stock_disponible` y la ordena por
designacion [L873]. La segunda consulta la vista `vw_historial_tarjetas`
pero filtra solo los ejemplares que tuvieron mas de una tarjeta
[L874-L876].

El filtro es una subconsulta con `IN`: `IdItem IN (SELECT IdItem FROM
Tarjetas GROUP BY IdItem HAVING COUNT(*) > 1)` [L875]. Por dentro:

- `GROUP BY IdItem`: agrupa todas las tarjetas por ejemplar, una fila por
  `IdItem`.
- `HAVING COUNT(*) > 1`: descarta los grupos con una sola tarjeta y deja
  los que tienen dos o mas. `HAVING` filtra grupos; `WHERE` filtraria
  filas antes de agrupar.
- `IN (...)`: la fila externa pasa si su `IdItem` esta en esa lista.

Esta subconsulta es NO correlacionada: la lista de `IdItem` con mas de una
tarjeta se calcula una sola vez y luego se usa para filtrar toda la vista.

### Q10 - JOIN frente a LEFT JOIN

INTUICION: un `JOIN` comun se queda solo con las filas que tienen pareja en
la otra tabla; un `LEFT JOIN` conserva todas las de la izquierda aunque no
tengan pareja, rellenando con `NULL`.

La consulta muestra cada ejemplar con su material y su ubicacion
[L880-L885]. Usa dos uniones distintas a proposito:

- `JOIN CatalogoMateriales` por `NNE` [L883]: todo ejemplar tiene material,
  asi que un `JOIN` comun (inner) alcanza.
- `LEFT JOIN Ubicaciones` por `IdUbicacion` [L884]: un ejemplar que esta
  fuera del deposito no tiene ubicacion (`IdUbicacion` en `NULL`). Con un
  `JOIN` comun esas filas desaparecerian; el `LEFT JOIN` las conserva y
  deja `DepositoUbicacion` y `SectorUbicacion` en `NULL`.

DIAGRAMA (JOIN comun frente a LEFT JOIN)
```
 InventarioFisico       Ubicaciones
   item 1 -> Ubic 10      Ubic 10  Dep A Sector 1
   item 2 -> Ubic 11      Ubic 11  Dep A Sector 2
   item 3 -> NULL (afuera)

 con JOIN comun (inner):
   item 1  Dep A  Sector 1
   item 2  Dep A  Sector 2
   (item 3 se pierde: no tiene ubicacion)

 con LEFT JOIN:
   item 1  Dep A  Sector 1
   item 2  Dep A  Sector 2
   item 3  NULL   NULL      (se conserva, sin pareja)
```

La razon practica: si se quiere el inventario completo, incluidos los que
estan fuera del deposito, hace falta `LEFT JOIN`; con `JOIN` comun el
listado mentiria por omision.

### Q11 - Cantidad de materiales por tipo

INTUICION: `GROUP BY` junta filas que comparten un valor y permite contar o
sumar por grupo.

La consulta cuenta cuantos materiales del catalogo hay por cada tipo de
elemento [L889-L893]. El `JOIN TiposElemento` enlaza cada material con el
nombre de su tipo via `IdTipoElemento` [L891]. El `GROUP BY
NombreTipoElemento` arma un grupo por tipo y `COUNT(*)` cuenta los
materiales de cada grupo [L889, L892]. El `ORDER BY CantidadMateriales
DESC` deja arriba los tipos con mas materiales [L893].

Regla: en una consulta con `GROUP BY`, en el `SELECT` solo pueden ir las
columnas agrupadas o funciones de agregacion (`COUNT`, `SUM`). Aca va
`NombreTipoElemento` (agrupada) y `COUNT(*)` (agregacion), y eso es valido.

### Las cinco pruebas comentadas

INTUICION: estas cinco lineas estan comentadas a proposito; son
operaciones que la base rechaza, y cada una sirve para demostrar una
defensa distinta del modelo [L896-L897].

TRAMPA: los comentarios del script dicen "fallan a proposito". No es que el
script este roto: estan comentadas justamente para que NO se ejecuten al
correr todo de una; se descomentan de a una para ver el error.

FRAME A FRAME (que defiende cada prueba)
```
 operacion invalida        mecanismo que la frena      error esperado
 -------------------------  --------------------------  ----------------
 insertar 'DIEZ' en una     tipo de dato de la columna  no convierte
 columna numerica           (int) [L900]                'DIEZ' a int
 -------------------------  --------------------------  ----------------
 ATAMaterial = 150          CHECK                        viola el CHECK
 (fuera de 0 a 99)          CHK_CatalogoMateriales_ATA   [L903]
                            [L902]
 -------------------------  --------------------------  ----------------
 ATAMaterial = 'ABC'        el mismo CHECK               viola el CHECK
 (letras, no numero)        CHK_CatalogoMateriales_ATA   [L906]
                            [L905]
 -------------------------  --------------------------  ----------------
 FechaRetorno anterior a    CHECK                        viola el CHECK
 FechaSalida                CHK_Salidas_RetornoPosterior [L909]
                            [L908]
 -------------------------  --------------------------  ----------------
 borrar un estado que       trigger trg_estado_no_borrar el trigger
 esta en uso (EN_SERVICIO) [L911]            bloquea el DELETE
                                                         [L912]
```

Detalle por prueba:

- Texto en columna numerica [L899-L900]: `IdSistemaArmas` espera un entero;
  pasar `'DIEZ'` falla en la conversion implicita. Lo frena el tipo de dato
  de la columna, antes de cualquier regla de negocio.
- ATA fuera de rango [L902-L903]: el `CHECK CHK_CatalogoMateriales_ATA`
  exige que el ATA este entre 0 y 99; `150` no entra y la restriccion
  rechaza el `INSERT`.
- ATA no numerico [L905-L906]: la misma restriccion `CHECK` valida que el
  contenido sea numerico; `'ABC'` la viola.
- Fecha incoherente [L908-L909]: el `CHECK CHK_Salidas_RetornoPosterior`
  obliga a que la fecha de retorno no sea anterior a la de salida; una
  salida con retorno antes es rechazada.
- Borrar estado en uso [L911-L912]: el `trigger trg_estado_no_borrar`
  intercepta el `DELETE` sobre `EstadosElemento` y lo bloquea si el estado
  esta siendo usado, evitando dejar tarjetas apuntando a un estado
  inexistente.

QUE TE PUEDEN PREGUNTAR

- Correlacionada frente a no correlacionada: la correlacionada (Q7) usa una
  columna de la fila externa y se reevalua por fila; la no correlacionada
  (Q9, el `IN`) se calcula una vez y se reutiliza.
- EXISTS frente a IN: `IN` compara contra una lista de valores; `EXISTS`
  solo verifica si la subconsulta devuelve al menos una fila. Con muchos
  datos `EXISTS` suele cortar antes; con `NULL` en la lista, `IN` puede dar
  resultados confusos y `EXISTS` no.
- WHERE frente a HAVING: `WHERE` filtra filas antes de agrupar; `HAVING`
  filtra grupos despues del `GROUP BY`. Por eso `COUNT(*) > 1` va en
  `HAVING` (Q9), no en `WHERE`.
- INNER JOIN frente a LEFT JOIN: el inner deja solo filas con pareja; el
  `LEFT JOIN` conserva todas las de la izquierda y rellena con `NULL` las
  sin pareja. En Q10 se usa `LEFT JOIN` para no perder los ejemplares que
  estan fuera del deposito.
- UNION frente a UNION ALL: `UNION` combina dos resultados y elimina filas
  duplicadas (cuesta mas, ordena para deduplicar); `UNION ALL` las pega tal
  cual sin quitar duplicados (mas rapido). En este script no se usa UNION;
  la diferencia es conceptual.
- Que defensa frena cada prueba: tipo de dato (texto en numerica), `CHECK
  CHK_CatalogoMateriales_ATA` (ATA fuera de rango y ATA con letras),
  `CHECK CHK_Salidas_RetornoPosterior` (fecha incoherente) y el `trigger
  trg_estado_no_borrar` (borrar estado en uso).
- Por que `CAST(SYSDATETIME() AS DATE)` y no `SYSDATETIME()` solo: para
  comparar solo la fecha; con la hora incluida, una fila que vence hoy
  podria clasificarse mal segun la hora del momento.

---

## Chuleta de una pantalla

INTUICION: leer esta hoja el dia de la defensa alcanza para ubicar cada construccion del script, su sintaxis minima y la linea donde vive.

Esta seccion comprime las demas. No define en profundidad: ancla concepto a sintaxis a linea y deja una respuesta de una linea por pregunta probable.

Mapa rapido (concepto, sintaxis minima, donde vive):

```
 IDENTITY + PK surrogate  INT IDENTITY(1,1) PRIMARY KEY      [L68]
 PK natural               NNE VARCHAR(20) PRIMARY KEY        [L125]
 PK compuesta             PRIMARY KEY (IdSistemaArmas, NNE)  [L148]
 UNIQUE                   CONSTRAINT UQ_... UNIQUE (col)     [L79]
 CHECK no vacio           CHECK (LEN(col) > 0)               [L98]
 CHECK rango ATA          CHECK (... BETWEEN 0 AND 99)       [L136]
 CHECK fechas             CHECK (FechaRetorno >= FechaSalida)[L238]
 FK simple                FOREIGN KEY (col) REFERENCES T(c)  [L131]
 FK ON DELETE CASCADE     ... ON DELETE CASCADE              [L151]
 FK ON DELETE SET NULL    ... ON DELETE SET NULL             [L135]
 FK NO ACTION (default)   FK sin clausula ON DELETE          [L170]
 DEFAULT                  DEFAULT SYSDATETIME()              [L203]
 INSERT semilla           INSERT ... VALUES (...)            [L246]
 funcion escalar          CREATE FUNCTION ... RETURNS ...    [L262]
 trigger AFTER INSERT     CREATE TRIGGER ... AFTER INSERT    [L278]
 trigger INSTEAD OF DEL   CREATE TRIGGER ... INSTEAD OF DEL  [L292]
 EXISTS en trigger        IF EXISTS (SELECT 1 ...)           [L298]
 THROW                    THROW 50002, 'msg', 1;            [L300]
 transaccion + TRY/CATCH  BEGIN TRAN / COMMIT / ROLLBACK     [L327]
 SCOPE_IDENTITY           SET @x = SCOPE_IDENTITY()          [L331]
 OUTPUT param             @IdItem INT OUTPUT                 [L320]
 SP patron Read           WHERE (@p IS NULL OR col = @p)     [L364]
 vista                    CREATE VIEW ... AS SELECT ...      [L612]
 GROUP BY + HAVING        GROUP BY ... HAVING COUNT(*) > 1   [L802]
 NOT EXISTS               WHERE NOT EXISTS (SELECT 1 ...)    [L812]
 UNION                    SELECT ... UNION SELECT ...        [L826]
 INTERSECT                SELECT ... INTERSECT SELECT ...    [L838]
 EXCEPT                   SELECT ... EXCEPT SELECT ...       [L845]
 subconsulta correlac.    (SELECT COUNT(*) ... WHERE = ext)  [L852]
 CASE + fecha             CASE WHEN ... THEN ... END         [L861]
 LEFT JOIN                LEFT JOIN Ubicaciones ON ...       [L884]
```

INTUICION: una PK surrogate es un numero que inventa el motor; una PK natural es un dato del negocio que ya identifica la fila.

Surrogate: `IdUsuario INT IDENTITY(1,1) PRIMARY KEY` [L68], el motor numera solo. Natural: el NNE (numero nacional de efecto) ya identifica al material, asi que es la PK directa [L125]. La PK compuesta de MaterialesSistemasArmas usa las dos FK juntas porque la fila ES la relacion [L148].

INTUICION: la politica ON DELETE decide que le pasa al hijo cuando se borra el padre.

```
 CASCADE    borra el padre -> se borran los hijos        [L151,L192]
 SET NULL   borra el padre -> el hijo queda con FK NULL  [L135,L173]
 NO ACTION  borra el padre con hijos -> el motor rechaza [L170]
```

CASCADE para datos que no viven sin el padre (tarjetas de un ejemplar [L192]). SET NULL para vinculos opcionales (usuario que cargo la ficha [L135], ubicacion de un item [L173]). NO ACTION (el default, sin clausula) protege el catalogo: no se borra un material si tiene ejemplares [L170].

INTUICION: una funcion escalar recibe datos y devuelve un unico valor, como una funcion de Programacion II.

`fn_EstadoActual(@IdItem)` [L262] busca la tarjeta activa del ejemplar y devuelve el codigo de su estado; NULL si no hay tarjeta activa [L271]. Se usa en la vista [L623] y en consultas [L800].

INTUICION: un trigger AFTER corre despues de que la fila ya entro; ve lo recien insertado en la pseudo-tabla inserted.

`trg_salida_abre_saca_del_deposito` [L278]: tras insertar una salida sin fecha de retorno, pone `IdUbicacion = NULL` en el item (sale del deposito) [L284]. Lee `inserted` para saber que items entraron [L286].

INTUICION: un trigger INSTEAD OF reemplaza la operacion; la accion original no ocurre salvo que el trigger la ejecute a mano.

`trg_estado_no_borrar` [L292]: si algun estado a borrar esta en uso por tarjetas (`IF EXISTS` sobre `deleted` [L298]), lanza `THROW 50002` y nada se borra [L300]; si no, ejecuta el DELETE real [L303]. `deleted` contiene las filas que se iban a borrar.

INTUICION: una transaccion agrupa varios INSERT en un todo-o-nada.

`sp_AltaElemento` [L312] inserta el ejemplar y su primera tarjeta dentro de `BEGIN TRANSACTION` / `COMMIT` [L327,L336]. Si algo falla, `CATCH` hace `ROLLBACK` y `THROW` [L339]. `SCOPE_IDENTITY()` recupera el Id recien generado en este alcance [L331] y lo devuelve por el parametro `OUTPUT` [L320] (un parametro por referencia: el valor sale hacia quien llamo).

```
 valida NNE -> BEGIN TRAN -> INSERT item -> @IdItem=SCOPE_IDENTITY
   -> INSERT tarjeta EN_SERVICIO -> COMMIT
 si error en cualquier paso -> ROLLBACK -> THROW (nada queda a medias)
```

INTUICION: un solo SP de lectura sirve para "uno" y para "todos" segun si el parametro viene NULL.

Patron `WHERE (@p IS NULL OR col = @p)` [L364]: si `@p` es NULL devuelve todo; si trae valor, filtra esa fila. Es un if/else escrito como condicion.

INTUICION: una vista es una consulta guardada con nombre (analogia: una consulta que se reutiliza como si fuera tabla).

`vw_stock_disponible` [L612]: stock en servicio y dentro del deposito (usa la funcion y filtra `IdUbicacion IS NOT NULL`) [L623]. `vw_historial_tarjetas` [L628]: todas las tarjetas por item con su estado.

INTUICION: un CHECK rechaza filas que no cumplen una regla de dominio.

ATA: acepta NULL o un entero 0 a 99; usa `TRY_CAST` para no romper con texto [L136]. Si el valor no es numero, `TRY_CAST` da NULL y el CHECK falla [L138]. Fechas de salida: el retorno no puede ser anterior a la salida [L238].

INTUICION: EXISTS pregunta si hay al menos una fila; IN compara contra una lista de valores.

```
 EXISTS / NOT EXISTS  hay/no hay fila relacionada   [L812,L819]
 UNION                une y elimina duplicados      [L826]
 INTERSECT            solo lo que esta en ambos     [L838]
 EXCEPT               lo del primero que no esta en el segundo [L845]
 correlacionada       subconsulta que usa col externa [L852]
```

QUE TE PUEDEN PREGUNTAR

- Que es una transaccion: un bloque todo-o-nada; o se confirman todos sus INSERT con `COMMIT` o se deshacen con `ROLLBACK` [L327].
- AFTER vs INSTEAD OF: AFTER corre tras la operacion ya aplicada (sincroniza, [L278]); INSTEAD OF la reemplaza y decide si ejecutarla (valida/bloquea, [L292]).
- Para que SCOPE_IDENTITY y no @@IDENTITY: SCOPE_IDENTITY devuelve el Id generado en el mismo alcance, sin contaminarse con triggers; aca se usa en [L331].
- Las tres politicas ON DELETE: CASCADE borra los hijos [L151], SET NULL deja la FK del hijo en NULL [L135], NO ACTION (default) rechaza si hay hijos [L170].
- PK natural vs surrogate: surrogate es un Id que inventa el motor [L68]; natural es un dato del negocio que ya identifica la fila, como el NNE [L125].
- EXISTS vs IN: EXISTS verifica si la subconsulta trae al menos una fila y corta al primer match [L819]; IN compara una columna contra una lista de valores; con NULL en la lista, IN puede dar resultados inesperados.
- Diferencia inserted vs deleted: inserted tiene las filas nuevas (INSERT/UPDATE), deleted las que se borran o el valor viejo (DELETE/UPDATE); usadas en [L286] y [L298].
- Por que NNE es PK natural y no un Id: el NNE ya identifica univocamente el material en el negocio [L125], evita una columna extra y se propaga como FK [L153].
- UNION vs UNION ALL: UNION elimina duplicados (mas costoso), UNION ALL no; el script usa UNION para una lista unica de personas [L826].
- Que es una vista: una consulta guardada con nombre que se consulta como si fuera una tabla; no almacena datos, los calcula al leerla [L612].
- Que hace el CHECK de ATA con 'ABC': TRY_CAST a INT da NULL, el CHECK no se cumple y el INSERT se rechaza [L136].
- Que pasa si borro un estado en uso: el trigger INSTEAD OF lanza THROW 50002 y no borra nada [L300].

Mini-glosario:

- IDENTITY: autonumerado de columna [L68].
- PK surrogate: clave artificial (un Id) [L68].
- PK natural: clave que es un dato del negocio (NNE) [L125].
- PK compuesta: clave de mas de una columna [L148].
- UNIQUE: prohibe valores repetidos [L79].
- CHECK: regla de dominio sobre la fila [L98].
- FK: referencia a la PK de otra tabla [L131].
- CASCADE: borrar padre borra hijos [L151].
- SET NULL: borrar padre deja FK del hijo en NULL [L135].
- NO ACTION: borrar padre con hijos se rechaza (default) [L170].
- DEFAULT: valor por omision si no se especifica [L203].
- TRY_CAST: cast que devuelve NULL si no puede convertir [L138].
- funcion escalar: devuelve un unico valor [L262].
- trigger: codigo que dispara un evento de tabla [L278].
- inserted / deleted: pseudo-tablas con filas nuevas / borradas [L286,L298].
- THROW: lanza un error y corta [L300].
- transaccion: bloque todo-o-nada [L327].
- SCOPE_IDENTITY: ultimo Id generado en el alcance [L331].
- OUTPUT: parametro que devuelve valor a quien llama [L320].
- vista: consulta guardada con nombre [L612].
- EXISTS: verdadero si la subconsulta trae al menos una fila [L812].
- INTERSECT / EXCEPT: comun a ambos / resta de conjuntos [L838,L845].

TRAMPA: el comentario "el IdItem se autonumera del 1 al 15" [L714] describe el INSERT directo de ejemplo; el alta formal pasa por `sp_AltaElemento` con transaccion [L312]. No confundir el INSERT de carga con el procedimiento.
