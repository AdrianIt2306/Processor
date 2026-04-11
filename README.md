# COBOL Learning Environment

Entorno de desarrollo COBOL usando **Rocket Visual COBOL** y **VS Code**.

---

## Requisitos

- [Rocket Visual COBOL](https://www.rocketsoftware.com) instalado
- Visual Studio 2022 Build Tools
- VS Code con la extensión de Rocket COBOL

---

## Estructura del proyecto

```
src/          ← Escribe todo tu código COBOL aquí
data/         ← Archivos de datos (.dat, .txt, etc.)
.vscode/      ← Configuración del editor (no tocar)
bin/          ← Generado automáticamente al compilar
obj/          ← Generado automáticamente al compilar
```

---

## Cómo trabajar

### 1. Escribir código

Todos los programas COBOL van en la carpeta `src/`. El archivo con el marcador `*> MAIN` al inicio es el punto de entrada del ejecutable:

```cobol
      *> MAIN
       identification division.
       program-id. MiPrograma.
       ...
```

Solo un archivo puede tener `*> MAIN`. Si querés cambiar el programa principal, movés el marcador.

### 2. Compilar y ejecutar

Presioná `Ctrl+Shift+B` — esto:
1. Detecta automáticamente el programa principal (`*> MAIN`)
2. Compila todos los `.cbl` de `src/`
3. Ejecuta el resultado

### 3. Generar datos de prueba

El script `generar-empleados.ps1` crea un archivo de datos aleatorio en `data/`:

```powershell
# 20 registros (por defecto)
.\generar-empleados.ps1

# Cantidad personalizada
.\generar-empleados.ps1 -Cantidad 500
```

---

## Agregar un nuevo programa

1. Crear un archivo `.cbl` en `src/`
2. Si debe ser el punto de entrada, agregar `*> MAIN` en la primera línea
3. `Ctrl+Shift+B` lo detecta y compila automáticamente

---

## Estructura de un programa COBOL básico

```cobol
      *> MAIN
       identification division.
       program-id. NombrePrograma.

       environment division.

       data division.
       working-storage section.
       01 ws-variable   pic x(20) value spaces.

       procedure division.
       inicio.
           display "Hola COBOL"
           goback.

       end program NombrePrograma.
```

---

## Leer un archivo de texto

```cobol
       environment division.
       input-output section.
       file-control.
           select mi-archivo
               assign to "data/archivo.dat"
               organization is line sequential.

       data division.
       file section.
       fd mi-archivo.
       01 registro   pic x(80).

       procedure division.
           open input mi-archivo
           read mi-archivo
           close mi-archivo
           goback.
```
