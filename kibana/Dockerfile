FROM debian:stable-slim

ARG TARGETPLATFORM
ARG KIBANA_VERSION=5.6.16

RUN apt update -y \
    && apt install -y \
    bash \
    curl

RUN curl https://artifacts.elastic.co/downloads/kibana/kibana-${KIBANA_VERSION}-amd64.deb -o kibana-${KIBANA_VERSION}-amd64.deb && \
    dpkg -i kibana-${KIBANA_VERSION}-amd64.deb

EXPOSE 5601

WORKDIR /usr/share/kibana

CMD ["bin/kibana"]
