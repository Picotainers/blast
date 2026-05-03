FROM ubuntu:22.04 AS builder

ARG BLAST_VERSION=2.17.0+
ARG BLAST_SRC_URL=https://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/LATEST/ncbi-blast-2.17.0+-src.tar.gz

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        liblzma-dev \
        libssl-dev \
        libxml2-dev \
        ncurses-dev \
        wget \
        zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp
RUN wget -O blast-src.tar.gz "${BLAST_SRC_URL}" \
    && tar -xzf blast-src.tar.gz

WORKDIR /tmp/ncbi-blast-${BLAST_VERSION}-src/c++
RUN ./configure --without-debug \
    && make -C ReleaseMT/build -j"$(nproc)" all_r

RUN install -d /out/usr/local/ncbi/blast/bin \
    && cp -a /tmp/ncbi-blast-${BLAST_VERSION}-src/c++/ReleaseMT/bin/. /out/usr/local/ncbi/blast/bin/

RUN printf '%s\n' \
    '#!/usr/bin/env bash' \
    'set -euo pipefail' \
    'export PATH="/usr/local/ncbi/blast/bin:${PATH}"' \
    'if [ "$#" -gt 0 ] && [ "$1" = "blast" ]; then' \
    '  shift' \
    'fi' \
    'if [ "$#" -eq 0 ] || [ "$1" = "--help" ] || [ "$1" = "-h" ]; then' \
    '  cat <<'"'"'EOF'"'"'' \
    'BLAST+ tools are installed.' \
    '' \
    'Usage:' \
    '  blast <tool> [args]' \
    '' \
    'Examples:' \
    '  blast blastn -help' \
    '  blast makeblastdb -help' \
    'EOF' \
    '  exit 0' \
    'fi' \
    'if command -v "$1" >/dev/null 2>&1; then' \
    '  exec "$@"' \
    'fi' \
    'exec blastn "$@"' \
    > /out/usr/local/bin/blast \
    && chmod +x /out/usr/local/bin/blast

FROM ubuntu:22.04

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libgcc-s1 \
        libgomp1 \
        liblzma5 \
        libstdc++6 \
        libxml2 \
        ncbi-data \
        zlib1g \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /out/usr/local /usr/local

ENV PATH="/usr/local/ncbi/blast/bin:${PATH}"

WORKDIR /data
ENTRYPOINT ["/usr/local/bin/blast"]
