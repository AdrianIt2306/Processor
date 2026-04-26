# Módulo 1 — El Entorno Moderno
> Videos 1 – 4

## Temas Clave
- Instalación del Enterprise Server (ES)
- Configuración de VS Code para COBOL
- Estructura de las cuatro divisiones de un programa COBOL

---

## 1. Instalación del Enterprise Server

El Enterprise Server (Micro Focus / Rocket Visual COBOL) provee el runtime necesario para compilar y ejecutar programas COBOL en Windows.

### Pasos básicos
1. Descargar el instalador de [Rocket Software Visual Studio](https://www.rocketsoftware.com/en-us/products/cobol/visual-cobol-personal-edition/free-download). (o Micro Focus COBOL) 
2. Ejecutar el instalador y seleccionar los componentes (Asegurarte de instalar la version 2022, si instalas una mas nueva no sera compatible):
   - **Enterprise Server**
   - **COBOL Compiler**
   - **MF COBOL Runtime**
3. Verificar que el directorio `bin64` quede en el `PATH` del sistema:
   ```
   C:\Program Files (x86)\Rocket Software\Visual COBOL\bin64
   ```
4. Comprobar la instalación desde terminal:
   ```powershell
   cobc --version
   ```

---

## 2. Configuración de VS Code

### Extensiones recomendadas
| Extensión | Propósito |
|---|---|
| **Micro Focus COBOL** | Sintaxis, compilación y depuración |
| **COBOL Language Support** (Broadcom) | IntelliSense y navegación |

### Configuración del proyecto (`.cblproj`)
En este workspace el proyecto se define en `Processor.cblproj`. La tarea de compilación usa MSBuild:

```powershell
MSBuild.exe Processor.sln /p:Configuration=Debug /p:Platform=x64
```

Los binarios se generan en `bin\x64\Debug\`.

---

## 3. Estructura de las Cuatro Divisiones

Todo programa COBOL se organiza en cuatro divisiones obligatorias (en este orden):

```cobol
IDENTIFICATION DIVISION.
    PROGRAM-ID. NombrePrograma.

ENVIRONMENT DIVISION.
    CONFIGURATION SECTION.
    INPUT-OUTPUT SECTION.

DATA DIVISION.
    FILE SECTION.
    WORKING-STORAGE SECTION.
    LOCAL-STORAGE SECTION.
    LINKAGE SECTION.

PROCEDURE DIVISION.
    * Lógica del programa aquí
    GOBACK.

END PROGRAM NombrePrograma.
```

### Descripción de cada división

| División | Propósito |
|---|---|
| `IDENTIFICATION` | Identifica el programa (nombre, autor, fecha). |
| `ENVIRONMENT` | Describe el entorno de hardware y los archivos que usa el programa. |
| `DATA` | Declara todas las variables, estructuras y registros de archivos. |
| `PROCEDURE` | Contiene la lógica ejecutable del programa. |

### Ejemplo mínimo (formato libre)

```cobol
identification division.
program-id. HolaMundo.

data division.
working-storage section.
01 ws-mensaje    pic x(20) value "Hola, COBOL!".

procedure division.
    display ws-mensaje
    goback.

end program HolaMundo.
```

---

## Notas de este workspace

- El proyecto usa **formato de columna fija/libre mixto** — Visual COBOL es sensible a la indentación en la `DATA DIVISION`; un nivel `01` mal alineado puede disparar `COBCH0071`.
- Los archivos fuente se ubican en `src/` (`Main.cbl`, `Saldos.cbl`).
- Cada programa debe tener un `PROGRAM-ID` único; un duplicado entre `Main` y `Saldos` causa error en la fase de Link.
