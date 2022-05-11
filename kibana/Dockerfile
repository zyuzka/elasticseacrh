FROM node:slim

ARG TARGETPLATFORM
ARG KIBANA_VERSION=5.6.16

RUN apt update -y \
    && apt install -y \
    bash \
    curl

RUN addgroup kibana && \
    useradd --shell /bin/sh --groups kibana --gid kibana kibana && \
    chown kibana:kibana /usr/share

WORKDIR /usr/share

USER kibana

RUN curl https://artifacts.elastic.co/downloads/kibana/kibana-${KIBANA_VERSION}-linux-x86_64.tar.gz -o kibana-${KIBANA_VERSION}-linux-x86_64.tar.gz \
    && tar xf ./kibana-${KIBANA_VERSION}-linux-x86_64.tar.gz \
    && mv kibana-${KIBANA_VERSION}-linux-x86_64 kibana

WORKDIR /usr/share/elasticsearch

RUN mkdir -p /usr/share/kibana/data && \
    chown kibana:kibana /usr/share/kibana/data
RUN mkdir -p /usr/share/kibana/config && \
    chown kibana:kibana /usr/share/kibana/config

EXPOSE 5601

WORKDIR /usr/share/kibana

CMD ["bin/kibana"]
