# Módulo 3 — Lógica de Negocio
> Videos 9 – 12

## Temas Clave
- `MOVE` — asignación de valores
- `COMPUTE` — expresiones aritméticas
- `IF` / `EVALUATE` — control de flujo condicional
- `PERFORM` — bucles e invocación de párrafos

---

## 1. `MOVE` — Asignación de Valores

`MOVE` copia un valor hacia uno o varios destinos.

### Sintaxis

```cobol
MOVE origen TO destino1 [destino2 ...]
```

### Tipos de MOVE

```cobol
*> Literales
move "ACTIVO"      to ws-estado
move 0             to ws-contador
move spaces        to ws-nombre
move zeros         to ws-importe

*> Variable a variable
move ws-nombre-a   to ws-nombre-b

*> Grupo completo (copia byte a byte)
move ws-empleado-origen to ws-empleado-destino

*> MOVE CORRESPONDING (campos con mismo nombre dentro de grupos)
move corresponding ws-reg-entrada to ws-reg-salida
```

### Reglas de conversión implícita

| Origen → Destino | Comportamiento |
|---|---|
| Numérico → Alfanumérico | Se convierte a texto |
| Alfanumérico → Numérico | El compilador lo permite; cuidado con datos no numéricos |
| Grupo → Grupo | Copia byte a byte (sin conversión) |

---

## 2. `COMPUTE` — Expresiones Aritméticas

`COMPUTE` evalúa expresiones matemáticas complejas en una sola instrucción.

### Sintaxis

```cobol
COMPUTE destino [ROUNDED] = expresión
    [ON SIZE ERROR instrucciones]
    [NOT ON SIZE ERROR instrucciones]
END-COMPUTE
```

### Operadores

| Operador | Operación |
|---|---|
| `+` | Suma |
| `-` | Resta |
| `*` | Multiplicación |
| `/` | División |
| `**` | Potencia |

### Ejemplos

```cobol
compute ws-total = ws-cantidad * ws-precio
compute ws-iva   = ws-subtotal * 0.16
compute ws-neto  = ws-bruto - ws-descuento - ws-iva

*> Con ROUNDED y manejo de desbordamiento
compute ws-resultado rounded = ws-a / ws-b
    on size error
        display "Desbordamiento en cálculo"
end-compute
```

### Alternativas verbales (ADD, SUBTRACT, MULTIPLY, DIVIDE)

```cobol
add 1            to ws-contador
subtract ws-desc from ws-total giving ws-neto
multiply ws-qty  by ws-precio giving ws-importe
divide 12        into ws-anual giving ws-mensual remainder ws-resto
```

---

## 3. `IF` / `EVALUATE` — Control de Flujo

### `IF`

```cobol
IF condición
    instrucciones-verdadero
[ELSE
    instrucciones-falso]
END-IF
```

#### Operadores de comparación

| Operador | Significado |
|---|---|
| `=` | Igual |
| `>` | Mayor que |
| `<` | Menor que |
| `>=` | Mayor o igual |
| `<=` | Menor o igual |
| `NOT =` | Distinto |

#### Operadores lógicos: `AND`, `OR`, `NOT`

```cobol
if ws-edad >= 18 and ws-activo = "S"
    display "Empleado adulto activo"
end-if

if not ws-codigo = spaces
    perform procesar-registro
end-if
```

#### `IF` anidados

```cobol
if ws-categoria = "A"
    if ws-sueldo > 50000
        move "SENIOR-A" to ws-nivel
    else
        move "JUNIOR-A" to ws-nivel
    end-if
else
    move "OTRO"    to ws-nivel
end-if
```

---

### `EVALUATE` — Switch / Pattern Matching

`EVALUATE` es el equivalente COBOL de un `switch`/`case` y es más legible que `IF` anidados.

#### Sintaxis básica

```cobol
EVALUATE sujeto
    WHEN valor1
        instrucciones
    WHEN valor2
        instrucciones
    WHEN OTHER
        instrucciones
END-EVALUATE
```

#### Ejemplo con un sujeto

```cobol
evaluate ws-opcion
    when "1"
        perform alta-empleado
    when "2"
        perform baja-empleado
    when "3"
        perform consulta-empleado
    when other
        display "Opción no válida"
end-evaluate
```

#### `EVALUATE TRUE` — múltiples condiciones

```cobol
evaluate true
    when ws-saldo < 0
        display "Saldo negativo"
    when ws-saldo = 0
        display "Sin saldo"
    when ws-saldo > 0 and ws-saldo < 1000
        display "Saldo bajo"
    when other
        display "Saldo normal"
end-evaluate
```

#### `EVALUATE` con dos sujetos

```cobol
evaluate ws-tipo also ws-estado
    when "C" also "A"
        perform procesar-credito-activo
    when "D" also "A"
        perform procesar-debito-activo
    when any  also "I"
        perform log-inactivo
end-evaluate
```

---

## 4. `PERFORM` — Bucles e Invocación de Párrafos

### Invocar un párrafo

```cobol
perform nombre-parrafo

*> Con rango de párrafos
perform nombre-parrafo thru nombre-parrafo-fin
```

### `PERFORM TIMES` — repetición fija

```cobol
perform 10 times
    add 1 to ws-contador
end-perform
```

### `PERFORM UNTIL` — bucle con condición de salida

```cobol
perform until ws-fin = "S"
    perform leer-registro
    perform procesar-registro
end-perform
```

#### Con `TEST AFTER` (do-while)

```cobol
perform with test after
    until ws-respuesta = "S" or ws-respuesta = "N"
    display "¿Continuar? (S/N): "
    accept ws-respuesta
end-perform
```

### `PERFORM VARYING` — bucle tipo FOR

```cobol
perform varying ws-idx from 1 by 1
    until ws-idx > ws-total-registros
    display ws-elemento(ws-idx)
end-perform
```

#### Variante con dos índices (bucle anidado)

```cobol
perform varying ws-i from 1 by 1 until ws-i > 5
    after ws-j from 1 by 1 until ws-j > 5
        compute ws-tabla(ws-i, ws-j) = ws-i * ws-j
    end-perform
end-perform
```

### `PERFORM` en línea vs. `PERFORM` de párrafo

```cobol
*> En línea (lógica embebida)
perform until fin-archivo
    read archivo-entrada into ws-registro
        at end set fin-archivo to true
    end-read
    if not fin-archivo
        perform procesar
    end-if
end-perform

*> Por referencia de párrafo
perform inicializar-contadores
perform with test after until respuesta = "FIN"
    perform leer-y-procesar
end-perform
perform generar-reporte
```

---

## Ejemplo Integrador

```cobol
procedure division.
inicio.
    move 0 to ws-total ws-contador
    perform varying ws-idx from 1 by 1 until ws-idx > 100
        compute ws-valor = ws-idx * 2
        add ws-valor to ws-total
        add 1        to ws-contador
    end-perform

    compute ws-promedio rounded = ws-total / ws-contador
        on size error
            move 0 to ws-promedio
    end-compute

    evaluate true
        when ws-promedio < 50
            display "Promedio bajo: " ws-promedio
        when ws-promedio < 100
            display "Promedio medio: " ws-promedio
        when other
            display "Promedio alto: " ws-promedio
    end-evaluate

    goback.
```
