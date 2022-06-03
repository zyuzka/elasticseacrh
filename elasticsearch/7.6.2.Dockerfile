FROM openjdk:8-jdk

ARG TARGETPLATFORM
ARG ELASTICSEARCH_VERSION=5.6.16

RUN apt update -y \
    && apt install -y \
    bash \
    gzip \
    curl

RUN addgroup elasticsearch && \
    useradd --shell /bin/sh --groups elasticsearch --gid elasticsearch elasticsearch && \
    chown elasticsearch:elasticsearch /usr/share

WORKDIR /usr/share

USER elasticsearch

RUN curl https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-7.6.2-linux-x86_64.tar.gz -o elasticsearch-7.6.2-linux-x86_64.tar.gz \
    && tar xf ./elasticsearch-7.6.2-linux-x86_64.tar.gz \
    && mv elasticsearch-7.6.2-linux-x86_64 elasticsearch

WORKDIR /usr/share/elasticsearch

RUN mkdir -p /usr/share/elasticsearch/data && \
    chown elasticsearch:elasticsearch /usr/share/elasticsearch/data
RUN mkdir -p /usr/share/elasticsearch/logs && \
    chown elasticsearch:elasticsearch /usr/share/elasticsearch/logs

RUN bash -c 'echo "http.host: 0.0.0.0" >> /usr/share/elasticsearch/config/elasticsearch.yml'

RUN bin/elasticsearch-plugin remove x-pack --purge || true

EXPOSE 9200 9300

CMD ["bin/elasticsearch", "-E", "xpack.ml.enabled=false"]
