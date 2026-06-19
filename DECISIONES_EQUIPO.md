# Decisiones del proyecto — para completar en equipo

> ⚠️ **ESTADO:** el sistema **ya está implementado y funcionando** con las **recomendaciones por
> defecto** de cada pregunta (ver `README.md` para correrlo). Esto NO bloquea nada: revisen contra
> código que ya corre. Si quieren cambiar alguna decisión, marquen otra opción y se ajusta el SQL
> en el punto puntual. El resumen de lo aplicado está al final de este documento.

> **Cómo completar esto:** marcá la opción elegida cambiando `[ ]` por `[x]`. Si ninguna
> opción te cierra, escribí la tuya en la línea **`Otra:`**. Cada pregunta trae una
> **Recomendación** (lo que propone el que armó el modelo) y el **Tema de la materia** que
> ese punto demuestra, para que veamos que estamos cubriendo el programa.
>
> **Contexto del proyecto:** sistema de gestión de material de un depósito de aeropartes
> (I Brigada Aérea — Taller G.T.1). El modelo ya está en `gestion_material.sql` y el diagrama
> en `modelo_logico.mermaid`.
>
> **Lo más importante para la nota:** la materia evalúa sobre todo **SQL** (triggers,
> procedimientos, funciones, cursores, vistas). El diseño de tablas ya está; lo que define la
> nota es **qué de eso implementamos y cómo lo justificamos**. La estrategia recomendada es
> simple: **demostrar cada tema evaluado al menos una vez, con una justificación del dominio
> (no “puesto de adorno”)**. No hace falta llenar de triggers porque sí; hace falta que cada
> herramienta aparezca con sentido.

---

## Parte 0 — Lo que YA quedó decidido (de la conversación previa, no hace falta volver a discutir)

Esto ya está cerrado y reflejado en el `.sql`. Lo dejo escrito para que nadie lo re-discuta:

- **Catálogo vs. ejemplar físico.** `catalogo_material` es el “modelo/ficha” (NNE, designación,
  tipo). `inventario_fisico` es cada ejemplar concreto (nº de serie, vencimiento). Un NNE → muchos ejemplares.
- **Tarjeta atada al elemento, con historial.** Cada elemento tiene una `tarjeta` activa; al
  cambiar de estado, la vieja queda como historial y se crea una nueva. **Una sola activa por
  elemento** (garantizado con índice único filtrado).
- **El estado vive en la tarjeta**, no en el elemento. Tres estados semilla: `EN_SERVICIO`
  (verde), `EN_SERVICIO_TRANSITORIO` (blanca, pendiente de reparación), `BAJA`.
- **Ciclo de salidas/retornos.** Tabla `salida` + catálogo `motivo_salida` (préstamo,
  reparación, inspección, baja). `id_ubicacion = NULL` en el elemento = está fuera del depósito.
  **No puede haber dos salidas abiertas** del mismo elemento a la vez (índice único filtrado).

---

## Parte 1 — Decisiones de modelo (4 puntos puntuales)

### P1. ¿Quiénes son los “actores” (inspector, quien retira, quien registra)?
Hoy `tarjeta.inspector`, `salida.retirado_por` y `movimiento_inventario.usuario` son **texto
libre**, mientras existe una tabla `USUARIO` casi sin usar. Hay que decidir si esas personas
**son usuarios del sistema** (entonces van como FK a `USUARIO`) o son personas físicas externas
que firman en papel (entonces el texto libre está bien).

- [ ] **A.** Son usuarios del sistema → convertir `inspector`, `retirado_por` y `usuario` en **FK a `USUARIO`** (más normalizado, conecta la tabla huérfana).
- [ ] **B.** Son personas físicas externas (firman en papel, pueden no tener cuenta) → **dejar texto libre**, y `USUARIO` se usa solo para login/consulta.
- [ ] **C.** Mixto: el que registra en el sistema (`movimiento.usuario`) es FK a `USUARIO`; inspector y retirado_por quedan en texto (porque son del taller, no del sistema).

`Otra: _______________________________________________`

> **Recomendación:** **C**. Es lo más fiel a la realidad del taller y de paso conecta `USUARIO`
> con el sistema sin inventar que el inspector es un usuario logueado.
> **Tema de la materia:** Claves foráneas e integridad referencial · Normalización (evitar dato repetido como texto).

---

### P2. ¿Qué significa la relación “consulta” (USUARIO → CATALOGO)?
Hoy está modelada como `USUARIO 1 ── N CATALOGO_MATERIAL` (FK `id_usuario` en el catálogo). Eso
literalmente significa *“cada material lo cargó/consultó a lo sumo un usuario”*, que suena raro
para el verbo “consultar”.

- [ ] **A.** En realidad es **“registrado/cargado por”** → renombrar la relación a `registra` o `carga`. La cardinalidad 1:N actual queda bien.
- [ ] **B.** Es **consulta real** (muchos usuarios consultan muchos materiales) → modelar **N:N con tabla intermedia** `usuario_consulta` (usuario, NNE, fecha).
- [ ] **C.** “Consultar” no es un dato que el sistema deba guardar → **eliminar la relación**; `USUARIO` queda para login.

`Otra: _______________________________________________`

> **Recomendación:** **A** si la consigna pide pocos elementos; **B** si quieren mostrar que
> saben resolver un N:N con tabla intermedia (suma puntos de modelado, igual que `material_sist_armas`).
> **Tema de la materia:** Transformación DER→relacional (M:N genera tabla intermedia) · Cardinalidad.

---

### P3. Nº de parte y Nº de serie: ¿se guardan en la tarjeta o se derivan?
En la **tarjeta física** están escritos el Nº de parte y el Nº de serie. En la base, hoy **no se
duplican**: el nº de serie sale del elemento (`inventario_fisico.n_serie`) y el nº de
parte/referencia del catálogo (`NREF`/`NNE`). Duplicarlos invita a inconsistencias.

- [ ] **A.** **Derivar** (como está ahora): no se duplican; se obtienen con un JOIN. Más normalizado.
- [ ] **B.** **Duplicar** en `tarjeta` para que la fila sea “igual al papel”, aunque haya redundancia.

`Otra: _______________________________________________`

> **Recomendación:** **A**. Es la decisión correcta y es **justamente lo que evalúa
> normalización**: un dato vive en un solo lugar. Si nos preguntan, se defiende con “evitamos
> dependencia/redundancia, el dato se deriva del elemento”.
> **Tema de la materia:** Normalización (redundancia, “cada dato un único lugar”) · Dependencias funcionales.

---

### P4. `movimiento_inventario.id_ubicacion` es obligatorio, pero el elemento puede estar afuera
Si registramos un movimiento de un elemento que está fuera del depósito (`id_ubicacion NULL`),
la FK obligatoria nos obliga a poner una ubicación que no existe.

- [ ] **A.** Hacer `id_ubicacion` **NULL-able** en `movimiento_inventario` (NULL = el movimiento ocurrió fuera del depósito).
- [ ] **B.** Crear una ubicación especial **“EXTERIOR/EN TRÁNSITO”** y usarla cuando está afuera.
- [ ] **C.** Dejarlo obligatorio: solo se registran movimientos dentro del depósito.

`Otra: _______________________________________________`

> **Recomendación:** **A**. Es lo más honesto con el modelo (ya aceptamos NULL = afuera en el
> elemento, seamos coherentes). **B** ensucia el catálogo de ubicaciones con una ficticia.
> **Tema de la materia:** Manejo de NULL · Integridad referencial.

---

## Parte 2 — Qué SQL implementamos (ESTO es lo que más se evalúa)

La materia evalúa explícitamente: **triggers, procedimientos almacenados, funciones, cursores,
vistas, transacciones**. Acá elegimos cuáles construir. Se puede marcar **varias** en cada
pregunta. La recomendación es un set mínimo que **toca todos los temas evaluados** con
justificación del dominio.

### P5. Triggers — ¿cuáles implementamos? (marcar varios)
> **Tema de la materia:** Triggers DML (AFTER / INSTEAD OF), tablas `INSERTED`/`DELETED`, ROLLBACK.

- [ ] **T1 — Una sola tarjeta activa.** Al insertar una tarjeta nueva, desactivar (`activa=0`) la tarjeta activa anterior del mismo elemento. *(Mantiene el invariante del historial.)*
- [ ] **T2 — Sincronizar “está afuera”.** Al **abrir** una salida (`fecha_retorno NULL`) poner `id_ubicacion=NULL` en el elemento; al **cerrarla**, dejar que el retorno reasigne la ubicación. *(Elimina el riesgo de que el elemento figure “adentro” con salida abierta.)*
- [ ] **T3 — Baja automática.** Al insertar una salida con motivo `BAJA`, crear una tarjeta en estado `BAJA` (y desactivar la anterior). *(Sincroniza estado y salida en la baja.)*
- [ ] **T4 — Auditoría automática.** Ante cambios en el elemento/salida, registrar una fila en `movimiento_inventario`. *(Bitácora sin depender de que la app la escriba.)*
- [ ] **T5 — Transiciones de estado válidas.** Impedir transiciones imposibles (ej.: de `BAJA` volver a `EN_SERVICIO`). *(Integridad de transiciones.)*

`Otra: _______________________________________________`

> **Recomendación:** **T1 + T2 + T3** como núcleo (resuelven problemas reales del modelo y
> demuestran AFTER + INSERTED/DELETED + ROLLBACK). Agregar **T5** si quieren lucirse con
> “integridad de transiciones” (concepto que está en los apuntes de la materia). **T4** es lindo
> pero puede solaparse con los procedimientos; opcional.

---

### P6. Procedimientos almacenados — ¿cuáles? (marcar varios)
> **Tema de la materia:** Stored procedures, parámetros IN/OUT, control de flujo (IF), transacciones, validaciones (EXISTS).

- [ ] **SP1 — `sp_RegistrarSalida`** (`@id_item, @id_motivo, @destino, @retirado_por, @fecha_prevista`). Valida que el elemento exista, que **no tenga ya una salida abierta** y que **no esté en BAJA**; inserta la salida dentro de una transacción.
- [ ] **SP2 — `sp_RegistrarRetorno`** (`@id_salida, @id_ubicacion`). Valida que la salida esté abierta; setea `fecha_retorno`; reubica el elemento; registra el movimiento.
- [ ] **SP3 — `sp_CambiarEstado`** (`@id_item, @codigo_estado, @ot, @causas, @inspector`). En una transacción: desactiva la tarjeta activa e inserta la nueva. *(Es el mecanismo central del historial de tarjetas.)*
- [ ] **SP4 — `sp_AltaElemento`** (`@NNE, @n_serie, @id_ubicacion, …`). Crea el ejemplar + su primera tarjeta `EN_SERVICIO` de una.

`Otra: _______________________________________________`

> **Recomendación:** **SP1 + SP2 + SP3** (cubren el ciclo completo: sale → vuelve → cambia de
> estado, todos con validación y transacción). **SP4** es opcional pero hace los datos de prueba
> más prolijos.

---

### P7. Funciones — ¿cuáles? (marcar varios)
> **Tema de la materia:** Funciones escalares, funciones de fecha (DATEDIFF), subconsultas.

- [ ] **F1 — `fn_DiasFueraDeposito(@id_item)`** → días que el elemento lleva afuera (de la salida abierta).
- [ ] **F2 — `fn_EstadoActual(@id_item)`** → código del estado de la tarjeta activa.
- [ ] **F3 — `fn_DiasParaVencer(@id_item)`** → días hasta el vencimiento (negativo si ya venció).

`Otra: _______________________________________________`

> **Recomendación:** **F1 + F2** (se usan después en las vistas, así no queda “suelta”). **F3**
> si incluimos el reporte de vencimientos (P9).

---

### P8. Vistas — ¿cuáles? (marcar varios)
> **Tema de la materia:** Vistas (tabla virtual), JOINs, abstracción de consultas complejas.

- [ ] **V1 — `vw_elementos_afuera`** → elementos con salida abierta, con motivo, destino y días afuera.
- [ ] **V2 — `vw_stock_disponible`** → elementos `EN_SERVICIO` y dentro del depósito.
- [ ] **V3 — `vw_historial_tarjetas`** → todas las tarjetas de cada elemento, ordenadas por fecha.
- [ ] **V4 — `vw_elementos_vencidos`** → elementos con `vencimiento` pasado.

`Otra: _______________________________________________`

> **Recomendación:** **V1 + V2 + V3** (responden las preguntas típicas del depósito: qué está
> afuera, qué hay disponible, qué le pasó a este elemento). **V4** si trabajamos vencimientos.

---

### P9. Cursor — ¿qué reporte lo justifica? (elegir uno)
> **Tema de la materia:** Cursores (DECLARE/OPEN/FETCH/@@FETCH_STATUS/CLOSE/DEALLOCATE). *El integrador de la materia pide explícitamente “cursor para reporte de vencidos”.*

- [ ] **C1 — Reporte de vencimientos.** Recorrer elementos cuyo `vencimiento` cae dentro de N días y armar un listado de alertas.
- [ ] **C2 — Salidas vencidas.** Recorrer salidas con `fecha_prevista_retorno` pasada y sin retorno, y generar el listado de “préstamos/reparaciones atrasados”.
- [ ] **C3 — Los dos** (un cursor cada uno).
- [ ] **C4 — Sin cursor** (no lo incluimos).

`Otra: _______________________________________________`

> **Recomendación:** **C2**. Es el reporte más natural del dominio (qué debería haber vuelto y no
> volvió) y calza con el “reporte de vencidos” que pide la materia.

---

### P10. Esquemas y sinónimos — ¿los usamos? (extra, suma sofisticación)
> **Tema de la materia:** Esquemas (organización lógica) y sinónimos.

- [ ] **A.** Organizar las tablas en esquemas (ej.: `Inventario`, `Movimientos`, `Auditoria`) y crear algún sinónimo. *(Muestra prolijidad “profesional”.)*
- [ ] **B.** Dejar todo en `dbo` (un solo esquema). Más simple, menos para explicar.

`Otra: _______________________________________________`

> **Recomendación:** **B** salvo que la consigna lo pida. Agregar esquemas por agregar complica
> la defensa sin sumar a la nota si no lo piden. (Si lo piden: **A**.)

---

## Parte 3 — Entregables de soporte

### P11. Datos de ejemplo + consultas de demostración
> **Tema de la materia:** SQL avanzado (UNION/INTERSECT/EXCEPT, GROUP BY/HAVING, EXISTS/NOT EXISTS, subconsultas).

- [ ] **A.** Sí: cargar datos de prueba realistas y un set de consultas demo que muestren **set operations, GROUP BY/HAVING y EXISTS/NOT EXISTS** (ej.: “elementos que nunca salieron del depósito”, “cuántos elementos por estado”, “ubicaciones con más de N elementos”).
- [ ] **B.** Solo datos de prueba, sin consultas demo.
- [ ] **C.** Nada de esto.

`Otra: _______________________________________________`

> **Recomendación:** **A**. Es la forma barata de demostrar el bloque “SQL Avanzado” entero en
> la defensa, con consultas que de verdad responden preguntas del depósito.

---

### P12. Documento de normalización (dependencias funcionales + 1FN/2FN/3FN)
> **Tema de la materia:** Normalización, dependencias funcionales (parciales y transitivas).

- [ ] **A.** Sí: un doc corto que liste las dependencias funcionales y argumente que cada tabla está en **3FN** (con `material_sist_armas` como ejemplo de clave compuesta sin dependencia parcial, y `ubicacion` separada como ejemplo de evitar dependencia transitiva).
- [ ] **B.** No, lo explicamos de palabra en la defensa.

`Otra: _______________________________________________`

> **Recomendación:** **A**. Si la materia evalúa normalización, tener el análisis escrito es la
> diferencia entre “creemos que está en 3FN” y “demostramos que está en 3FN”.

---

### P13. Políticas de borrado (FK) y validaciones CHECK
> **Tema de la materia:** Restricciones (CHECK), políticas en FK (NO ACTION / CASCADE / SET NULL / SET DEFAULT).

- [ ] **A.** Definir políticas explícitas en las FK (ej.: borrar una ubicación → `SET NULL` en elementos; impedir borrar un catálogo con ejemplares → `NO ACTION`) **y** agregar CHECKs (ej.: `fecha_retorno >= fecha_salida`, `fecha_prevista_retorno >= fecha_salida`).
- [ ] **B.** Solo los CHECKs, dejar las FK en su comportamiento por defecto.
- [ ] **C.** Dejar todo como está.

`Otra: _______________________________________________`

> **Recomendación:** **A**. Son dos temas de la materia (políticas de FK + CHECK) que se agregan
> con pocas líneas y se defienden fácil. Mínimo hacer los CHECK de fechas: son errores obvios que
> el profesor puede testear en vivo.

---

## Parte 4 — Comentarios libres del equipo

> ¿Algo que la consigna pide y no está contemplado acá? ¿Algún requisito específico del profe
> (cantidad mínima de triggers/SP, formato de entrega, restricciones)? Escríbanlo:

```
(espacio para el equipo)



```

---

### Resumen de la estrategia recomendada (si no quieren pensar mucho)
> Cubrir **todos** los temas evaluados con el set mínimo coherente:
> **P5:** T1+T2+T3 · **P6:** SP1+SP2+SP3 · **P7:** F1+F2 · **P8:** V1+V2+V3 · **P9:** C2 ·
> **P11:** A · **P12:** A · **P13:** A. Modelo: **P1-C, P2-A, P3-A, P4-A.**
> Con eso quedan demostrados triggers, procedimientos, funciones, cursores, vistas, transacciones,
> SQL avanzado y normalización — que es exactamente lo que la materia evalúa.
