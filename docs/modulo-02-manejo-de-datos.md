# Módulo 2 — Manejo de Datos
> Videos 5 – 8

## Temas Clave
- Variables y tipos de datos (`PIC`)
- Niveles numéricos (01 – 88)
- `REDEFINES`
- `OCCURS` (tablas / arrays)

---

## 1. Variables y Tipos de Datos (`PIC`)

En COBOL cada variable se declara con una **cláusula `PICTURE` (PIC)** que describe su tipo y tamaño.

### Símbolos comunes

| Símbolo | Significado | Ejemplo |
|---|---|---|
| `X` | Carácter alfanumérico | `PIC X(10)` → 10 caracteres |
| `9` | Dígito numérico | `PIC 9(5)` → 5 dígitos enteros |
| `V` | Punto decimal implícito | `PIC 9(5)V99` → 5 enteros + 2 decimales |
| `S` | Signo (numérico con signo) | `PIC S9(4)` |
| `A` | Solo letras | `PIC A(10)` |

### Ejemplos

```cobol
01 ws-nombre         pic x(30) value spaces.
01 ws-edad           pic 9(3)  value 0.
01 ws-salario        pic 9(7)v99 value 0.
01 ws-saldo-con-signo pic s9(7)v99 comp-3.
```

### Cláusula `VALUE`
Permite asignar un valor inicial al momento de la declaración:

```cobol
01 ws-pi   pic 9v9999 value 3.1416.
01 ws-flag pic x      value "N".
```

---

## 2. Niveles Numéricos (01 – 88)

Los niveles definen la jerarquía y el tipo de los ítems de datos.

| Nivel | Uso |
|---|---|
| `01` | Ítem de grupo raíz o ítem elemental independiente |
| `02`–`49` | Sub-ítems dentro de un grupo |
| `66` | `RENAMES` (renombrar rangos) |
| `77` | Ítem elemental independiente (sin estructura de grupo) |
| `88` | Nombre de condición (valores booleanos) |

### Ejemplo de estructura jerárquica

```cobol
01 ws-empleado.
   05 ws-emp-nombre    pic x(30).
   05 ws-emp-apellido  pic x(30).
   05 ws-emp-sueldo    pic 9(7)v99 comp-3.
   05 ws-emp-activo    pic x.
      88 emp-activo    value "S".
      88 emp-inactivo  value "N".
```

### Niveles 88 — Condiciones booleanas

Los ítems de nivel `88` no ocupan almacenamiento propio; se evalúan como verdaderos cuando su ítem padre tiene el valor declarado.

```cobol
01 ws-estado         pic x.
   88 estado-ok      value "O".
   88 estado-error   value "E".
   88 estado-proceso value "P".

procedure division.
    move "O" to ws-estado
    if estado-ok
        display "Todo en orden"
    end-if
    set estado-error to true    *> equivale a MOVE "E" TO ws-estado
```

---

## 3. `REDEFINES`

`REDEFINES` permite que dos ítems compartan la misma área de memoria, interpretando los bytes de manera diferente.

### Sintaxis

```cobol
01 ws-fecha-num    pic 9(8).
01 ws-fecha-str    redefines ws-fecha-num.
   05 ws-anio      pic 9(4).
   05 ws-mes       pic 9(2).
   05 ws-dia       pic 9(2).
```

Al mover `20260412` a `ws-fecha-num`, los campos `ws-anio`, `ws-mes` y `ws-dia` se pueden leer como `2026`, `04`, `12` respectivamente, sin ninguna conversión adicional.

### Reglas importantes
- El ítem que redefine debe declararse **inmediatamente después** del ítem redefinido.
- El ítem redefinido **no puede tener cláusula `VALUE`** (salvo espacios/ceros en algunas implementaciones).
- Ambos ítems deben tener el **mismo tamaño en bytes**.

---

## 4. `OCCURS` — Tablas y Arrays

La cláusula `OCCURS` define una tabla (arreglo) de ítems repetidos.

### Sintaxis básica

```cobol
01 ws-tabla.
   05 ws-elemento  occurs 10 times
                   pic 9(5).
```

Acceso: `ws-elemento(índice)` — el índice es **base 1**.

### `OCCURS` con `INDEXED BY`

```cobol
01 ws-productos.
   05 ws-prod      occurs 100 times
                   indexed by idx-prod.
      10 ws-prod-codigo  pic x(10).
      10 ws-prod-precio  pic 9(7)v99 comp-3.

procedure division.
    set idx-prod to 1
    move "PROD001" to ws-prod-codigo(idx-prod)
    move 1999.99   to ws-prod-precio(idx-prod)
```

### `OCCURS DEPENDING ON` — tamaño variable

```cobol
01 ws-cant-empleados  pic 9(3).
01 ws-lista-emp.
   05 ws-emp-nombre   occurs 1 to 200 times
                      depending on ws-cant-empleados
                      pic x(30).
```

### `SEARCH` — búsqueda en tablas

```cobol
search ws-prod
    at end display "No encontrado"
    when ws-prod-codigo(idx-prod) = "PROD001"
        display "Precio: " ws-prod-precio(idx-prod)
end-search
```

---

## Resumen de cláusulas de almacenamiento

| Cláusula | Efecto |
|---|---|
| `COMP` / `BINARY` | Entero binario nativo (2/4/8 bytes) |
| `COMP-3` / `PACKED-DECIMAL` | Decimal empaquetado (eficiente para cálculos) |
| `COMP-5` | Binario nativo con truncado |
| *(ninguna)* | Display (formato carácter, por defecto) |
