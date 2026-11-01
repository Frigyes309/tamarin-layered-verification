# Tamarin 1.12.0 and Maude 3.5.1, the versions of the paper, with the
# theories, the scaled layer-6 models and the scripts of this repository.
#
#   docker build -t tamarin-layered .
#   docker run --rm -v "$PWD/results:/work/results" tamarin-layered
#
# The default command is run_all.sh. See README.md for the other commands.
FROM ubuntu:24.04

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates curl unzip git graphviz hyperfine \
      libgmp10 libffi8 zlib1g \
 && rm -rf /var/lib/apt/lists/*

# Release binaries, checked against their SHA-256
RUN curl -fsSL -o /tmp/tamarin.tar.gz \
      https://github.com/tamarin-prover/tamarin-prover/releases/download/1.12.0/tamarin-prover-1.12.0-linux64-ubuntu.tar.gz \
 && echo "201be06f469e47cff554df6ca93db8366fc2c69d70c61fcbd1370a1074b469c6  /tmp/tamarin.tar.gz" | sha256sum -c - \
 && tar -xzf /tmp/tamarin.tar.gz -C /usr/local/bin \
 && rm /tmp/tamarin.tar.gz

RUN curl -fsSL -o /tmp/maude.zip \
      https://github.com/maude-lang/Maude/releases/download/Maude3.5.1/Maude-3.5.1-linux-x86_64.zip \
 && echo "72ed1ca87e3b3d0dfc6ee1436baf154bf04c45ff97d521bec040c5e8dfc8f92c  /tmp/maude.zip" | sha256sum -c - \
 && unzip -q /tmp/maude.zip -d /opt/maude \
 && chmod +x /opt/maude/maude \
 && ln -s /opt/maude/maude /usr/local/bin/maude \
 && rm /tmp/maude.zip

# Tamarin prints Unicode symbols and fails on a non-UTF-8 stdout
ENV MAUDE_LIB=/opt/maude \
    TAMARIN=/usr/local/bin/tamarin-prover \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

WORKDIR /work
COPY . /work

# Interactive mode: tamarin-prover interactive --interface='*4' .
EXPOSE 3001

CMD ["bash", "run_all.sh"]
