FROM ubuntu:22.04

ARG YQ_VERSION=v4.45.4
ARG YQ_BINARY=yq_linux_amd64
ARG DEFAULT_RUST_VERSION=1.88.0
ARG DEFAULT_GO_VERSION=1.24.5
ARG REPO_ROOT=/ds-course

RUN apt update &&   \
    apt install -y  \
    git             \
    make            \
    wget            \
    openjdk-21-jre  \
    graphviz        \
    gnuplot         \
    curl

RUN wget https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/${YQ_BINARY} -O /usr/bin/yq  \
    && chmod +x /usr/bin/yq

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain ${DEFAULT_RUST_VERSION}
ENV PATH="/root/.cargo/bin:${PATH}"
RUN rustc --version && cargo --version

RUN curl -LO https://go.dev/dl/go${DEFAULT_GO_VERSION}.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go${DEFAULT_GO_VERSION}.linux-amd64.tar.gz     && \
    rm go${DEFAULT_GO_VERSION}.linux-amd64.tar.gz
ENV PATH="/usr/local/go/bin:${PATH}"
RUN go version

COPY . ${REPO_ROOT}

WORKDIR ${REPO_ROOT}
