FROM ubuntu:22.04

RUN apt update && \
    apt install -y \
    wget \
    openjdk-17-jre \
    graphviz \
    gnuplot

ARG YQ_VERSION=v4.45.4
ARG YQ_BINARY=yq_linux_amd64
RUN wget https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/${YQ_BINARY} -O /usr/bin/yq \
    && chmod +x /usr/bin/yq


ARG REPO_ROOT=/ds-course

COPY . ${REPO_ROOT}

WORKDIR ${REPO_ROOT}
