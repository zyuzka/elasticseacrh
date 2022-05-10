FROM openjdk:8-jdk

ARG TARGETPLATFORM
ARG ELASTICSEARCH_VERSION=5.6.16

ENV JAVA_OPTS='-Xms512m -Xmx512m'

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

RUN curl https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-${ELASTICSEARCH_VERSION}.tar.gz -o elasticsearch-${ELASTICSEARCH_VERSION}.tar.gz \
    && tar xf ./elasticsearch-${ELASTICSEARCH_VERSION}.tar.gz \
    && mv elasticsearch-${ELASTICSEARCH_VERSION} elasticsearch \
    && cd elasticsearch

WORKDIR /usr/share/elasticsearch

RUN mkdir -p /usr/share/elasticsearch/data && \
    chown elasticsearch:elasticsearch /usr/share/elasticsearch/data
RUN mkdir -p /usr/share/elasticsearch/logs && \
    chown elasticsearch:elasticsearch /usr/share/elasticsearch/logs

RUN bash -c 'echo "http.host: 0.0.0.0" >> /usr/share/elasticsearch/config/elasticsearch.yml'

EXPOSE 9200 9300

CMD ["bin/elasticsearch"]
