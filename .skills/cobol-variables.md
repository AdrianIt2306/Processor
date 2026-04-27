# Declaración de Variables COBOL para OCESQL

Hallazgos documentados durante la integración de GnuCOBOL + OCESQL 1.4.0 con PostgreSQL.

---

## Bug crítico: OCESQL 1.4.0 es case-sensitive en declaraciones PIC

OCESQL 1.4.0 **solo reconoce como tipo alfanumérico** la cláusula `PIC X` en **MAYÚSCULAS**.
Con `pic x` (minúsculas) el precompilador omite las llamadas `OCESQLSetResultParams` para esas
variables en los bloques FETCH/SELECT INTO, lo que provoca SQLCODE = -212 en tiempo de ejecución.

| Declaración | `SetResultParams` generado | Resultado en runtime |
|---|---|---|
| `PIC X(100)` | ✅ Sí (tipo 16) | Funciona |
| `pic x(100)` | ❌ No | SQLCODE = -212 |
| `PIC 9(9)` | ✅ Sí (tipo 1) | Funciona |
| `pic 9(9)` | ✅ Sí (tipo 1) | Funciona (numéricos no tienen el bug) |

**Regla práctica:** Escribe siempre `PIC X` y `VALUE SPACES` en mayúsculas para variables
alfanuméricas que se usen como host variables en EXEC SQL.

---

## Tipos de datos PostgreSQL → declaración COBOL correcta

| Tipo PostgreSQL | Ejemplo columna | Declaración COBOL | Tipo OCESQL |
|---|---|---|---|
| `numeric(10,0)` | `cust_id numeric(10,0)` | `PIC 9(10) VALUE 0.` | 1 |
| `numeric(p,s)` con decimales | `precio numeric(12,2)` | `PIC 9(10)V99 VALUE 0.` | 1 |
| `character(n)` / `char(n)` | `cust_name character(100)` | `PIC X(100) VALUE SPACES.` | 16 |
| `character varying(n)` / `varchar(n)` | `email varchar(200)` | `PIC X(200) VALUE SPACES.` | 16 |
| `integer` / `int4` | `edad integer` | `PIC 9(9) VALUE 0.` | 1 |
| `bigint` / `int8` | `id bigint` | `PIC 9(18) VALUE 0.` | 1 |
| `smallint` / `int2` | `codigo smallint` | `PIC 9(4) VALUE 0.` | 1 |
| `boolean` | `activo boolean` | `PIC X(1) VALUE SPACES.` ('T'/'F') | 16 |
| `date` | `fecha date` | `PIC X(10) VALUE SPACES.` (YYYY-MM-DD) | 16 |
| `timestamp` | `creado timestamp` | `PIC X(26) VALUE SPACES.` | 16 |

> **Nota:** PostgreSQL `character(n)` devuelve la cadena con padding de espacios hasta longitud `n`.
> Declara el host variable con exactamente el mismo largo para evitar truncamiento.

---

## Estructura correcta del DECLARE SECTION

```cobol
EXEC SQL BEGIN DECLARE SECTION END-EXEC.
01 hv-id         PIC 9(10)  VALUE 0.        *> numérico
01 hv-nombre     PIC X(100) VALUE SPACES.   *> alfanumérico — MAYÚSCULAS obligatorio
01 hv-fecha      PIC X(10)  VALUE SPACES.   *> fecha como string
EXEC SQL END DECLARE SECTION END-EXEC.
```

**Lo que NO funciona:**
```cobol
01 hv-nombre     pic x(100) value spaces.   *> minúsculas — OCESQL 1.4.0 ignora el tipo X
```

---

## Variables inyectadas por build.py (no declararlas en el fuente)

`build.py` inyecta automáticamente las siguientes variables. **No las declares en tu `.cbl`**,
el build lo hace por ti:

```cobol
*> Fuera del DECLARE SECTION (WORKING-STORAGE normal):
01 PG-HOST       PIC X(64) VALUE SPACES.
01 PG-DB         PIC X(64) VALUE SPACES.
01 PG-USER       PIC X(64) VALUE SPACES.
01 PG-PORT       PIC X(10) VALUE SPACES.
01 PG-PASS       PIC X(64) VALUE SPACES.

*> Dentro del DECLARE SECTION (host variables para OCESQL CONNECT):
01 W-DB          PIC X(1) VALUE SPACES.
01 W-USR         PIC X(1) VALUE SPACES.
01 W-PWD         PIC X(1) VALUE SPACES.
```

La conexión usa `EXEC SQL CONNECT :W-USR IDENTIFIED BY :W-PWD USING :W-DB` con variables
de un solo byte porque libpq resuelve el servidor, usuario y contraseña mediante las variables
de entorno `PGHOST`, `PGDATABASE`, `PGUSER`, `PGPORT` y `PGPASSWORD`.

---

## Orden de inyección en el DECLARE SECTION

Las variables `W-DB/W-USR/W-PWD` deben ir **al final** del DECLARE SECTION, después de
las variables del usuario. Ponerlas al inicio también causa SQLCODE = -212 en OCESQL 1.4.0
(otro síntoma del mismo bug de sensibilidad de tipo).

```
DECLARE SECTION:
  ├── hv-customers  PIC 9(9)    ← variables del usuario primero
  ├── hv-cust-id    PIC 9(10)
  ├── hv-cust-name  PIC X(100)
  ├── hv-cust-last  PIC X(100)
  ├── W-DB          PIC X(1)    ← inyectadas por build.py al final
  ├── W-USR         PIC X(1)
  └── W-PWD         PIC X(1)
END DECLARE SECTION
```

---

## Patrón correcto para FETCH con cursor

```cobol
*> Declarar cursor
EXEC SQL
    DECLARE c1 CURSOR FOR
        SELECT col1, col2, col3 FROM tabla
END-EXEC

*> Abrir y verificar
EXEC SQL OPEN c1 END-EXEC
IF SQLCODE NOT = 0
    DISPLAY "OPEN ERROR SQLCODE=" SQLCODE
    DISPLAY "SQLSTATE=" SQLSTATE
    STOP RUN
END-IF

*> Primer FETCH fuera del ciclo
EXEC SQL
    FETCH c1 INTO :hv-col1, :hv-col2, :hv-col3
END-EXEC

*> Ciclo: repite mientras SQLCODE = 0
PERFORM UNTIL SQLCODE NOT = 0
    IF SQLCODE = 0
        DISPLAY hv-col1 " " hv-col2
        EXEC SQL
            FETCH c1 INTO :hv-col1, :hv-col2, :hv-col3
        END-EXEC
    END-IF
END-PERFORM

*> Cerrar cursor
EXEC SQL CLOSE c1 END-EXEC
```

> SQLCODE = +100 al final del ciclo es **normal**: significa "no more rows" (fin del cursor).

---

## SQLCODE de referencia (OCESQL / PostgreSQL)

| SQLCODE | Significado |
|---|---|
| 0 | Éxito |
| +100 | No more rows (fin de cursor, SELECT INTO sin resultado) |
| -212 | Cursor no encontrado — causas: `pic x` en minúsculas, orden de vars en DECLARE, OPEN no ejecutado |
| -400 | Error de base de datos — revisar SQLSTATE para detalle |
| Negativo | Error genérico — siempre mostrar SQLSTATE |
