#!/bin/bash
set -e

SRC_DIR="./src"
OUT_DIR="./dist"

mkdir -p "$OUT_DIR"

echo "=== Compilando programas COBOL ==="

for cbl_file in "$SRC_DIR"/*.cbl; do
    program=$(basename "$cbl_file" .cbl)
    cob_file="$OUT_DIR/${program}.cob"
    exe_file="$OUT_DIR/${program}"

    echo ">>> Procesando: $program"

    # Paso 1: precompilar con OCESQL (EXEC SQL -> CALL statements)
    ocesql "$cbl_file" "$cob_file"

    # Paso 2: compilar con GnuCOBOL, linkeo estático para que corra en el LPAR
    cobc -x -static "$cob_file" \
        -locesql \
        -lpq \
        -lssl \
        -lcrypto \
        -lz \
        -o "$exe_file"

    chmod +x "$exe_file"
    echo "    OK: $exe_file"
done

echo ""
echo "=== Binarios generados en $OUT_DIR ==="
ls -lh "$OUT_DIR"/*.* 2>/dev/null || true
ls -lh "$OUT_DIR"/* 2>/dev/null | grep -v '\.' || true
