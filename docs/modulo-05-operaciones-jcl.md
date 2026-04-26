# Módulo 5 — Operaciones y JCL
> Videos 17 – 20

## Temas Clave
- JCL (Job Control Language)
- `LINKAGE SECTION` — paso de parámetros entre programas
- Debugging y técnicas de prueba
- Proyecto Final

---

## 1. JCL — Job Control Language

JCL es el lenguaje que le indica al sistema operativo z/OS cómo ejecutar un programa COBOL: qué recursos necesita, qué archivos usa y cómo encadenar pasos.

### Estructura básica de un JOB

```jcl
//MYJOB    JOB  (ACCT),'Descripcion',CLASS=A,MSGCLASS=X,
//              NOTIFY=&SYSUID
//*
//STEP01   EXEC PGM=MIPROGRAMA
//STEPLIB  DD   DSN=MY.LOAD.LIBRARY,DISP=SHR
//SYSOUT   DD   SYSOUT=*
//ENTRADA  DD   DSN=MY.INPUT.FILE,DISP=SHR
//SALIDA   DD   DSN=MY.OUTPUT.FILE,
//              DISP=(NEW,CATLG,DELETE),
//              SPACE=(TRK,(10,5),RLSE),
//              DCB=(RECFM=FB,LRECL=80,BLKSIZE=3200)
```

### Statements principales

| Statement | Propósito |
|---|---|
| `JOB` | Define el trabajo (nombre, cuenta, clase) |
| `EXEC` | Ejecuta un programa (`PGM=`) o un procedure (`PROC=`) |
| `DD` | Define un Data Definition (archivo / dataset) |
| `//*` | Comentario |
| `//` (vacío) | Separador / fin de JCL |

### Parámetros DD comunes

| Parámetro | Significado |
|---|---|
| `DSN=` | Nombre del dataset |
| `DISP=(estado,normal,anormal)` | Estado del dataset y qué hacer al terminar |
| `SYSOUT=*` | Salida al spool (consola / impresora) |
| `SPACE=(unidad,(primario,secundario))` | Espacio a asignar |
| `DCB=` | Descripción de control de bloque (RECFM, LRECL, BLKSIZE) |

### Valores de `DISP`

| Valor | Descripción |
|---|---|
| `SHR` | Compartido; el dataset ya existe |
| `OLD` | Exclusivo; el dataset ya existe |
| `NEW` | Se creará un nuevo dataset |
| `MOD` | Se extiende al final de un dataset existente o se crea |
| `CATLG` | Catalogar en caso de fin normal |
| `DELETE` | Borrar en caso de terminación anormal |
| `PASS` | Pasar al siguiente paso del JOB |

### Encadenamiento de pasos

```jcl
//JOB1     JOB  ...
//*-------------- PASO 1: Ordenar
//PASO1    EXEC PGM=SORT
//SORTIN   DD   DSN=RAW.DATA,DISP=SHR
//SORTOUT  DD   DSN=&&TEMP,DISP=(NEW,PASS),SPACE=(TRK,(5,2))
//SYSIN    DD   *
  SORT FIELDS=(1,8,CH,A)
/*
//*-------------- PASO 2: Procesar
//PASO2    EXEC PGM=MIPROGRAMA,COND=(0,NE,PASO1)
//INPUT    DD   DSN=&&TEMP,DISP=(OLD,DELETE)
//OUTPUT   DD   DSN=RESULTADO.FILE,DISP=(NEW,CATLG)
//SYSOUT   DD   SYSOUT=*
```

### PROC (Procedure) JCL

Los PROCs son JCL reutilizable almacenado en catálogo:

```jcl
//* Catalogued PROC
//MIPROC   PROC PARAM1=DEFAULT
//STEP1    EXEC PGM=MIPROG
//DD1      DD   DSN=&PARAM1,DISP=SHR
//         PEND

//* Invocar el PROC
//MYJOB    JOB  ...
//S1       EXEC MIPROC,PARAM1=MY.REAL.DSN
```

---

## 2. `LINKAGE SECTION` — Comunicación entre Programas

La `LINKAGE SECTION` define los parámetros que un subprograma recibe del programa llamador.

### Llamador (`CALL`)

```cobol
working-storage section.
01 ws-codigo-empl    pic x(6).
01 ws-sueldo         pic s9(9)v99 comp-3.
01 ws-codigo-retorno pic 9(2).

procedure division.
    move "EMP001" to ws-codigo-empl
    call "CALCNOM" using
        by reference ws-codigo-empl
        by reference ws-sueldo
        by reference ws-codigo-retorno
    end-call

    if ws-codigo-retorno = 0
        display "Nómina calculada: " ws-sueldo
    else
        display "Error en cálculo: " ws-codigo-retorno
    end-if
```

### Subprograma (`CALCNOM`)

```cobol
identification division.
program-id. CALCNOM.

data division.
working-storage section.
01 ws-factor         pic 9(3)v99 comp-3 value 1.35.

linkage section.
01 ls-codigo         pic x(6).
01 ls-sueldo         pic s9(9)v99 comp-3.
01 ls-retorno        pic 9(2).

procedure division using ls-codigo ls-sueldo ls-retorno.
inicio.
    move 0 to ls-retorno
    evaluate ls-codigo
        when "EMP001"
            compute ls-sueldo = 40000 * ws-factor
        when other
            move 99 to ls-retorno
    end-evaluate
    goback.

end program CALCNOM.
```

### Modos de paso de parámetros

| Modo | Descripción |
|---|---|
| `BY REFERENCE` | El subprograma accede directamente a la variable original (cambios se reflejan en el llamador) |
| `BY CONTENT` | Se pasa una copia; el llamador no ve los cambios |
| `BY VALUE` | Similar a `BY CONTENT` pero para tipos escalares; común en COBOL moderno |

### `CALL` dinámico vs. estático

```cobol
*> Estático: enlazado en tiempo de compilación
call "SUBPROG" using ws-parametro

*> Dinámico: nombre del programa en una variable
move "CALCNOM" to ws-nombre-prog
call ws-nombre-prog using ws-parametro
```

---

## 3. Debugging y Técnicas de Prueba

### `DISPLAY` para tracing

La técnica más simple y universal: insertar `DISPLAY` estratégicos.

```cobol
display ">>> INICIO leer-registro"
display "    ws-clave = " ws-clave
display "    file-status = " ws-fs
```

### Compiler directives de depuración

```cobol
*> Activar modo DEBUG (Visual COBOL)
>>D display "Valor debug: " ws-valor
```

El bloque `>>D` solo se compila si el switch `WITH DEBUGGING MODE` está activo en la `CONFIGURATION SECTION`.

### Rutina de manejo de errores centralizada

```cobol
working-storage section.
01 ws-mensaje-error   pic x(80).
01 ws-codigo-error    pic 9(4).

procedure division.
    ...
    if not fs-ok
        string "Error I/O en archivo X, status=" ws-fs
               delimited size into ws-mensaje-error
        move 1001 to ws-codigo-error
        perform abortar-proceso
    end-if

abortar-proceso.
    display "*** ERROR: " ws-mensaje-error
    display "*** CODIGO: " ws-codigo-error
    stop run.
```

### Verificación de datos de entrada

```cobol
*> Validar que un campo es numérico
if ws-importe is not numeric
    display "Importe no numérico: >" ws-importe "<"
    add 1 to ws-cnt-errores
end-if

*> Validar rango
if ws-edad < 18 or ws-edad > 99
    display "Edad fuera de rango: " ws-edad
end-if
```

### Uso del debugger de Visual COBOL / VS Code

1. Establecer un **breakpoint** en la línea de interés (clic en el margen izquierdo del editor).
2. Lanzar la tarea **Run (Debug x64)** (`.vscode/tasks.json`).
3. En el panel **Variables** inspeccionar `ws-*` y los registros de archivo.
4. Usar **Step Over** (`F10`) y **Step Into** (`F11`) para avanzar línea a línea.
5. El **Watch** permite evaluar expresiones COBOL durante la ejecución.

---

## 4. Proyecto Final — Guía de Integración

El proyecto final integra todos los módulos. A continuación se describe una arquitectura típica de sistema batch mainframe.

### Estructura del sistema

```
JCL (orquestación)
  └── PASO1: SORT de entrada
  └── PASO2: VALIDACION (COBOL)
        ├── Lee archivo secuencial de transacciones
        ├── Valida cada registro
        └── Genera archivo de rechazos y archivo validado
  └── PASO3: PROCESO PRINCIPAL (COBOL)
        ├── Lee archivo validado (secuencial)
        ├── Actualiza VSAM KSDS de cuentas
        ├── Utiliza CALL a subprogramas (cálculos)
        └── Genera reporte de resultados (SYSOUT)
  └── PASO4: GENERACION DE REPORTES (COBOL)
```

### Checklist del proyecto final

- [ ] **Identificación**: `PROGRAM-ID` único por módulo.
- [ ] **Datos**: Uso correcto de niveles `01`–`88`, `REDEFINES` y `OCCURS`.
- [ ] **Lógica**: `EVALUATE` en lugar de `IF` anidados para mejorar legibilidad.
- [ ] **Archivos**: `FILE STATUS` comprobado tras cada operación de I/O.
- [ ] **VSAM**: `OPEN I-O` para actualizaciones, `READ` antes de `REWRITE`/`DELETE`.
- [ ] **Subprogramas**: `LINKAGE SECTION` con tipos compatibles entre llamador y subprograma.
- [ ] **JCL**: `COND CODE` para no ejecutar pasos siguientes si un paso falla.
- [ ] **Calidad**: Sin literales en columna fija que excedan la columna 72.
- [ ] **Pruebas**: Casos de prueba para registro válido, inválido, fin de archivo y error de I/O.

### Plantilla base de un programa batch completo

```cobol
identification division.
program-id. ProcesoFinal.

environment division.
input-output section.
file-control.
    select arch-entrada assign to "ENTRADA"
        organization sequential file status ws-fs-ent.
    select arch-vsam    assign to "VSAM-KSDS"
        organization indexed access dynamic
        record key reg-clave file status ws-fs-vsam.

data division.
file section.
fd arch-entrada record contains 100 characters.
01 reg-entrada pic x(100).

fd arch-vsam.
01 reg-vsam.
   05 reg-clave   pic x(10).
   05 reg-datos   pic x(90).

working-storage section.
01 ws-fs-ent      pic xx.
01 ws-fs-vsam     pic xx.
   88 vsam-ok     value "00".
   88 vsam-eof    value "10".
   88 vsam-nof    value "23".
01 ws-fin-ent     pic x value "N".
   88 fin-entrada value "Y".
01 ws-cnt-proc    pic 9(7) value 0.
01 ws-cnt-err     pic 9(7) value 0.

procedure division.
0000-principal.
    perform 1000-abrir-archivos
    perform 2000-procesar until fin-entrada
    perform 3000-cerrar-archivos
    goback.

1000-abrir-archivos.
    open input arch-entrada
    if ws-fs-ent not = "00"
        display "Error abriendo ENTRADA: " ws-fs-ent
        stop run
    end-if
    open i-o arch-vsam
    if ws-fs-vsam not = "00"
        display "Error abriendo VSAM: " ws-fs-vsam
        stop run
    end-if.

2000-procesar.
    read arch-entrada
        at end set fin-entrada to true
        not at end perform 2100-actualizar
    end-read.

2100-actualizar.
    move reg-entrada(1:10) to reg-clave
    read arch-vsam invalid key
        perform 2110-alta
        not invalid key perform 2120-modificar
    end-read.

2110-alta.
    move reg-entrada to reg-vsam
    write reg-vsam
        invalid key
            add 1 to ws-cnt-err
            display "Alta duplicada: " reg-clave
    end-write.

2120-modificar.
    move reg-entrada(11:90) to reg-datos
    rewrite reg-vsam
        invalid key
            add 1 to ws-cnt-err
    end-rewrite
    add 1 to ws-cnt-proc.

3000-cerrar-archivos.
    close arch-entrada arch-vsam
    display "Procesados: " ws-cnt-proc
    display "Errores:    " ws-cnt-err.

end program ProcesoFinal.
```
