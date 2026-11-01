# Build locally with docker build -t tamarin-layered-verification .
FROM ubuntu:24.04@sha256:fe81560990fae86dc4743202b2cb4d3df98d0bcf949173cecef15ce1127ef852

ARG TAMARIN_VERSION=1.12.0
ARG TAMARIN_SHA256=201be06f469e47cff554df6ca93db8366fc2c69d70c61fcbd1370a1074b469c6
ARG MAUDE_VERSION=3.5.1
ARG MAUDE_SHA256=72ed1ca87e3b3d0dfc6ee1436baf154bf04c45ff97d521bec040c5e8dfc8f92c

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl unzip git just hyperfine graphviz libgmp10 libffi8 zlib1g libtinfo6 \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL -o /tmp/tamarin.tar.gz \
        "https://github.com/tamarin-prover/tamarin-prover/releases/download/${TAMARIN_VERSION}/tamarin-prover-${TAMARIN_VERSION}-linux64-ubuntu.tar.gz" \
    && echo "${TAMARIN_SHA256}  /tmp/tamarin.tar.gz" | sha256sum -c - \
    && tar -xzf /tmp/tamarin.tar.gz -C /usr/local/bin tamarin-prover \
    && curl -fsSL -o /tmp/maude.zip \
        "https://github.com/maude-lang/Maude/releases/download/Maude${MAUDE_VERSION}/Maude-${MAUDE_VERSION}-linux-x86_64.zip" \
    && echo "${MAUDE_SHA256}  /tmp/maude.zip" | sha256sum -c - \
    && unzip -q /tmp/maude.zip -d /opt/maude \
    && chmod +x /opt/maude/maude \
    && ln -s /opt/maude/maude /usr/local/bin/maude \
    && rm /tmp/tamarin.tar.gz /tmp/maude.zip

# Tamarin prints Unicode symbols and fails on a non-UTF-8 stdout
ENV MAUDE_LIB=/opt/maude LANG=C.UTF-8 LC_ALL=C.UTF-8 OUT=/out
WORKDIR /work
COPY . .
# Interactive mode: --entrypoint tamarin-prover ... interactive --interface='*4' .
EXPOSE 3001
ENTRYPOINT ["just"]
CMD ["reproduce"]
