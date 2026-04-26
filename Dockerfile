FROM debian:bookworm-slim

# Instalar dependencias base
RUN apt-get update && apt-get install -y \
    gnucobol \
    libpq-dev \
    libssl-dev \
    zlib1g-dev \
    git \
    make \
    automake \
    autoconf \
    libtool \
    pkg-config \
    gcc \
    bison \
    flex \
    && rm -rf /var/lib/apt/lists/*

# Compilar e instalar OCESQL desde fuente
RUN git clone https://github.com/opensourcecobol/Open-COBOL-ESQL.git /tmp/ocesql \
    && cd /tmp/ocesql \
    && autoreconf -fi \
    && ./configure --prefix=/usr/local \
    && make \
    && make install \
    && ldconfig \
    && rm -rf /tmp/ocesql

WORKDIR /build

# Copiar los fuentes COBOL
COPY src/ ./src/
COPY build.sh .

RUN chmod +x build.sh

ENTRYPOINT ["/bin/bash", "build.sh"]
