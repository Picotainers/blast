FROM ubuntu:22.04 AS builder

ARG BLAST_VERSION=2.17.0+
ARG BLAST_SRC_URL=https://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/LATEST/ncbi-blast-2.17.0+-src.tar.gz

RUN apt-get update     && apt-get install -y --no-install-recommends         build-essential         ca-certificates         liblzma-dev         libssl-dev         libxml2-dev         ncurses-dev         wget         zlib1g-dev     && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp
RUN wget -O blast-src.tar.gz "${BLAST_SRC_URL}"     && tar -xzf blast-src.tar.gz

WORKDIR /tmp/ncbi-blast-${BLAST_VERSION}-src/c++
RUN ./configure --without-debug     && make -C ReleaseMT/build -j"$(nproc)" all_r

RUN install -d /out/usr/local/ncbi/blast/bin /out/usr/local/bin     && cp -a /tmp/ncbi-blast-${BLAST_VERSION}-src/c++/ReleaseMT/bin/. /out/usr/local/ncbi/blast/bin/

RUN echo 'IyEvdXNyL2Jpbi9lbnYgYmFzaApzZXQgLWV1byBwaXBlZmFpbApleHBvcnQgUEFUSD0iL3Vzci9sb2NhbC9uY2JpL2JsYXN0L2Jpbjoke1BBVEh9IgppZiBbICIkIyIgLWd0IDAgXSAmJiBbICIkMSIgPSAiYmxhc3QiIF07IHRoZW4KICBzaGlmdApmaQppZiBbICIkIyIgLWVxIDAgXSB8fCBbICIkMSIgPSAiLS1oZWxwIiBdIHx8IFsgIiQxIiA9ICItaCIgXTsgdGhlbgogIGVjaG8gIkJMQVNUKyB0b29scyBhcmUgaW5zdGFsbGVkLiIKICBlY2hvICIiCiAgZWNobyAiVXNhZ2U6ICBibGFzdCA8dG9vbD4gW2FyZ3NdIgogIGVjaG8gIiIKICBlY2hvICJFeGFtcGxlczoiCiAgZWNobyAiICBibGFzdCBibGFzdG4gLWhlbHAiCiAgZWNobyAiICBibGFzdCBtYWtlYmxhc3RkYiAtaGVscCIKICBleGl0IDAKZmkKaWYgY29tbWFuZCAtdiAiJDEiID4vZGV2L251bGwgMj4mMTsgdGhlbgogIGV4ZWMgIiRAIgpmaQpleGVjIGJsYXN0biAiJEAiCg==' | base64 -d > /out/usr/local/bin/blast     && chmod +x /out/usr/local/bin/blast

FROM ubuntu:22.04

RUN apt-get update     && apt-get install -y --no-install-recommends         libgcc-s1         libgomp1         liblzma5         libstdc++6         libxml2         ncbi-data         zlib1g     && rm -rf /var/lib/apt/lists/*

COPY --from=builder /out/usr/local /usr/local

ENV PATH="/usr/local/ncbi/blast/bin:${PATH}"

WORKDIR /data
ENTRYPOINT ["/usr/local/bin/blast"]
