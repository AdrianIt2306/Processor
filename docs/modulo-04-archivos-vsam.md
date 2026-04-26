# Módulo 4 — El Corazón del Mainframe
> Videos 13 – 16

## Temas Clave
- Archivos Secuenciales
- Archivos VSAM (KSDS, ESDS, RRDS)
- `FILE STATUS`
- Operaciones de I/O (`OPEN`, `READ`, `WRITE`, `REWRITE`, `DELETE`, `CLOSE`)

---

## 1. Archivos Secuenciales

Un archivo secuencial se lee y escribe registro a registro, de principio a fin, sin acceso directo.

### Declaración completa

```cobol
environment division.
input-output section.
file-control.
    select archivo-empleados
        assign to "EMPLEADOS.DAT"
        organization is sequential
        access mode  is sequential
        file status  is ws-status-emp.

data division.
file section.
fd  archivo-empleados
    record contains 80 characters.
01 reg-empleado.
   05 emp-codigo    pic x(6).
   05 emp-nombre    pic x(30).
   05 emp-sueldo    pic 9(7)v99 comp-3.
   05 filler        pic x(29).

working-storage section.
01 ws-status-emp    pic xx value "00".
01 ws-fin-archivo   pic x  value "N".
   88 fin-archivo   value "Y".
```

### Operaciones de I/O — Lectura secuencial

```cobol
procedure division.
    open input archivo-empleados
    perform until fin-archivo
        read archivo-empleados
            at end set fin-archivo to true
            not at end perform procesar-empleado
        end-read
    end-perform
    close archivo-empleados
    goback.

procesar-empleado.
    display emp-codigo " " emp-nombre.
```

### Escritura secuencial

```cobol
    open output archivo-empleados
    move "EMP001" to emp-codigo
    move "Juan Pérez" to emp-nombre
    move 45000.00  to emp-sueldo
    write reg-empleado
    close archivo-empleados
```

### Modos de apertura

| Modo | Uso |
|---|---|
| `INPUT` | Solo lectura |
| `OUTPUT` | Solo escritura (crea o sobreescribe el archivo) |
| `EXTEND` | Agregar al final del archivo existente |
| `I-O` | Lectura y escritura (actualización) |

---

## 2. Archivos VSAM

VSAM (Virtual Storage Access Method) es el sistema de archivos nativo del mainframe IBM z/OS. Existen tres tipos:

| Tipo | Nombre completo | Acceso |
|---|---|---|
| **KSDS** | Key-Sequenced Data Set | Por clave (más común) |
| **ESDS** | Entry-Sequenced Data Set | Secuencial por posición de entrada |
| **RRDS** | Relative Record Data Set | Por número de registro relativo |

### KSDS — Acceso por clave

```cobol
environment division.
input-output section.
file-control.
    select archivo-clientes
        assign to "CLIENTES"
        organization  is indexed
        access mode   is dynamic          *> secuencial + aleatorio
        record key    is cli-codigo
        alternate record key is cli-rfc
            with duplicates
        file status   is ws-status-cli.

data division.
file section.
fd  archivo-clientes.
01 reg-cliente.
   05 cli-codigo     pic x(8).
   05 cli-nombre     pic x(40).
   05 cli-rfc        pic x(13).
   05 cli-saldo      pic s9(9)v99 comp-3.

working-storage section.
01 ws-status-cli     pic xx value "00".
```

### Lectura aleatoria (por clave)

```cobol
    move "CLI00042" to cli-codigo
    read archivo-clientes
        invalid key
            display "Cliente no encontrado"
        not invalid key
            display "Nombre: " cli-nombre
    end-read
```

### Lectura secuencial desde una clave (START)

```cobol
    move "CLI00010" to cli-codigo
    start archivo-clientes key >= cli-codigo
        invalid key display "Clave inicial no encontrada"
    end-start

    perform until fin-archivo
        read archivo-clientes next
            at end set fin-archivo to true
            not at end perform procesar-cliente
        end-read
    end-perform
```

### Escritura / Reescritura / Borrado

```cobol
*> Alta (nuevo registro)
    write reg-cliente
        invalid key display "Clave duplicada: " cli-codigo
    end-write

*> Modificación (requiere lectura previa)
    read archivo-clientes
        invalid key display "No existe"
    end-read
    add 500.00 to cli-saldo
    rewrite reg-cliente
        invalid key display "Error al reescribir"
    end-rewrite

*> Baja lógica / física
    delete archivo-clientes record
        invalid key display "Error al borrar"
    end-delete
```

### RRDS — Acceso por número relativo

```cobol
    select archivo-relativo
        assign to "RELATIVO"
        organization is relative
        access mode  is random
        relative key is ws-num-reg
        file status  is ws-status-rel.
```

---

## 3. `FILE STATUS`

El `FILE STATUS` es una variable de dos caracteres que el compilador actualiza tras cada operación de I/O.

### Valores principales

| Código | Significado |
|---|---|
| `00` | Operación exitosa |
| `02` | Lectura OK, pero existen claves duplicadas (VSAM) |
| `10` | Fin de archivo (`AT END`) |
| `21` | Error de secuencia de clave (escritura secuencial) |
| `22` | Clave duplicada (WRITE / START a clave existente) |
| `23` | Registro no encontrado (`READ` / `DELETE` / `REWRITE`) |
| `24` | Espacio de disco insuficiente |
| `30` | Error de I/O permanente |
| `35` | Archivo no encontrado al abrir (`OPEN INPUT`) |
| `39` | Atributos del archivo incompatibles |
| `41` | Archivo ya abierto |
| `42` | Archivo no abierto al intentar cerrar |
| `43` | `REWRITE` sin `READ` previo |
| `46` | `READ NEXT` sin un `START` o `READ` previo |
| `47` | `READ` en archivo no abierto como `INPUT` o `I-O` |
| `48` | `WRITE` en archivo no abierto como `OUTPUT` o `I-O` |
| `49` | `REWRITE` / `DELETE` en archivo no abierto como `I-O` |

### Patrón recomendado para validar status

```cobol
working-storage section.
01 ws-status          pic xx.
   88 io-ok           value "00" "02".
   88 io-eof          value "10".
   88 io-not-found    value "23".

procedure division.
    open input mi-archivo
    if not io-ok
        display "Error al abrir: " ws-status
        goback
    end-if

    perform until io-eof
        read mi-archivo
            at end continue
        end-read
        evaluate true
            when io-ok      perform procesar
            when io-eof     continue
            when other
                display "Error lectura: " ws-status
                perform abortar
        end-evaluate
    end-perform

    close mi-archivo.
```

---

## 4. Resumen de Verbos de I/O

| Verbo | Descripción |
|---|---|
| `OPEN` | Abre el archivo en el modo indicado |
| `CLOSE` | Cierra el archivo (libera el recurso) |
| `READ` | Lee el siguiente registro (secuencial) o por clave (aleatorio) |
| `READ ... NEXT` | Lee el siguiente registro en modo dinámico |
| `START` | Posiciona el puntero en un registro por condición de clave |
| `WRITE` | Escribe un nuevo registro |
| `REWRITE` | Sobreescribe el último registro leído |
| `DELETE` | Elimina el último registro leído (KSDS) |

---

## Ejemplo Integrador: Actualización de saldos en KSDS

```cobol
identification division.
program-id. ActualizaSaldos.

environment division.
input-output section.
file-control.
    select arch-cuentas
        assign to "CUENTAS"
        organization  is indexed
        access mode   is random
        record key    is cta-numero
        file status   is ws-fs.

data division.
file section.
fd  arch-cuentas.
01 reg-cuenta.
   05 cta-numero     pic x(10).
   05 cta-saldo      pic s9(11)v99 comp-3.

working-storage section.
01 ws-fs             pic xx.
   88 fs-ok          value "00".
   88 fs-no-existe   value "23".
01 ws-num-cuenta     pic x(10).
01 ws-monto          pic s9(9)v99 comp-3.

procedure division.
inicio.
    open i-o arch-cuentas
    if not fs-ok
        display "No se pudo abrir CUENTAS: " ws-fs
        goback
    end-if

    move "0000000001" to ws-num-cuenta
    move 500.00        to ws-monto
    perform creditar-cuenta

    close arch-cuentas
    goback.

creditar-cuenta.
    move ws-num-cuenta to cta-numero
    read arch-cuentas
        invalid key
            display "Cuenta no encontrada: " cta-numero
            exit paragraph
    end-read
    add ws-monto to cta-saldo
    rewrite reg-cuenta
        invalid key display "Error al reescribir: " ws-fs
    end-rewrite.

end program ActualizaSaldos.
```
