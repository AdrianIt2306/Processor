# COBOL + PostgreSQL — Build con Docker para LPAR

Entorno de compilación COBOL con acceso a **PostgreSQL** usando **GnuCOBOL + OCESQL**.

Los programas se compilan en un contenedor Docker y producen **binarios Linux portables** que se copian y ejecutan directamente en un LPAR — sin instalar nada en el destino.

---

## Cómo funciona

```
┌─────────────────────────────────────┐
│  Windows (desarrollo)               │
│                                     │
│  src/MiPrograma.cbl  ─────────┐     │
│                               ▼     │
│  Docker (debian:bookworm-slim)       │
│  ├─ GnuCOBOL                  │     │
│  ├─ OCESQL (precompilador SQL) │     │
│  └─ build.sh                  │     │
│       1. inyecta CONNECT/DISC  │     │
│       2. ocesql (EXEC SQL→CALL)│     │
│       3. cobc (compila)        │     │
│       4. empaqueta .so         │     │
│                               ▼     │
│  dist/MiPrograma + dist/lib/  ─────►│
└─────────────────────────────────────┘
               │
               ▼
  LPAR Linux — ejecuta ./MiPrograma
  (lee PG* env vars automáticamente)
```

**El programador solo escribe SQL de negocio.** La conexión a la base de datos es transparente: `build.sh` la inyecta en el binario durante la compilación.

---

## Requisitos (solo en Windows)

- Docker Desktop
- VS Code (opcional)

No se necesita GnuCOBOL instalado localmente.

---

## Estructura del proyecto

```
src/          ← Programas COBOL (.cbl) — solo lógica de negocio
dist/         ← Binarios Linux generados (copiar al LPAR)
  lib/        ← Librerías .so empaquetadas (sin instalar en LPAR)
Dockerfile    ← Imagen con GnuCOBOL + OCESQL + libpq
build.sh      ← Script de compilación (inyección + ocesql + cobc)
docker-compose.yml
```

---

## Escribir un programa COBOL con SQL

El programador **no gestiona conexiones**. Solo declara las host variables que necesita y escribe los `EXEC SQL`:

```cobol
       identification division.
       program-id. clientes.

       data division.
       working-storage section.

           exec sql include sqlca end-exec.

           EXEC SQL BEGIN DECLARE SECTION END-EXEC.
       01 hv-total    pic 9(9) value 0.
           EXEC SQL END DECLARE SECTION END-EXEC.

       procedure division.
       inicio.
           EXEC SQL
               SELECT COUNT(*) INTO :hv-total FROM customers
           END-EXEC

           if sqlcode not = 0
               display "Error: " sqlcode
           else
               display "Total clientes: " hv-total
           end-if

           goback.

       end program clientes.
```

`build.sh` inyecta automáticamente:
- Variables de conexión `W-DB / W-USR / W-PWD` (en blanco → libpq usa `PG*`)
- `CONNECT` al inicio, con `DISPLAY` de las variables de entorno detectadas
- `DISCONNECT` antes de cada `GOBACK`

---

## Compilar

```bash
docker compose build   # solo la primera vez o si cambia Dockerfile
docker compose run --rm cobol-build
```

Los binarios quedan en `dist/`.

---

## Ejecutar en el LPAR

Copia la carpeta `dist/` completa al LPAR (binario + `lib/`):

```bash
scp -r dist/ usuario@lpar:/store/programs/MIAPP/
```

Luego en el LPAR:

```bash
export PGHOST=mi-servidor
export PGDATABASE=mi-base
export PGUSER=mi-usuario
export PGPASSWORD=mi-clave
export PGPORT=5432          # opcional, default 5432

/store/programs/MIAPP/clientes
```

Salida esperada:
```
DB PGHOST=mi-servidor
DB PGDATABASE=mi-base
DB PGUSER=mi-usuario
DB PGPORT=5432
DB PGPASSWORD=<definida>
DB Conectando...
DB Conexion exitosa.
Total clientes: 000000042
```

> Los binarios incluyen todas las `.so` necesarias en `dist/lib/` con RPATH relativo.
> **No se necesita instalar GnuCOBOL, libpq ni ninguna otra librería en el LPAR.**

---

## Agregar un nuevo programa

1. Crear `src/NuevoPrograma.cbl` con la estructura de arriba
2. Ejecutar `docker compose run --rm cobol-build`
3. Copiar `dist/NuevoPrograma` y `dist/lib/` al LPAR

---

## Diagnóstico de errores comunes

| Error | Causa | Solución |
|-------|-------|----------|
| `SQLSTATE=08001` | No puede conectar al servidor | Verificar `PGHOST`, `PGPORT`, red/firewall |
| `SQLSTATE=08003` | `PGPASSWORD` no definida o vacía | `export PGPASSWORD=tu-clave` |
| `SQLSTATE=28000` | Usuario/contraseña incorrectos | Verificar `PGUSER` y `PGPASSWORD` |
| `SQLSTATE=3D000` | Base de datos no existe | Verificar `PGDATABASE` |
| `libcob.so.4: not found` | Falta `dist/lib/` en el destino | Copiar `dist/lib/` junto al binario |
