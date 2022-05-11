FROM nginx:1.17-alpine

ARG TARGETPLATFORM
ARG SWAGGER_UI_VERSION='v3.24.3'

RUN apk --no-cache add \
    nodejs \
    bash \
    gzip \
    curl

WORKDIR /data

RUN curl -L https://github.com/swagger-api/swagger-ui/archive/refs/tags/v3.24.3.tar.gz -o swagger-ui-3.24.3.tar.gz \
    && tar xf ./swagger-ui-3.24.3.tar.gz

ENV API_KEY "**None**"
ENV SWAGGER_JSON "/app/swagger.json"
ENV PORT 8080
ENV BASE_URL ""

WORKDIR /data/swagger-ui-3.24.3

RUN cp docker/nginx.conf docker/cors.conf /etc/nginx/
RUN cp dist/* /usr/share/nginx/html/
RUN cp docker/run.sh /usr/share/nginx/
RUN cp -R docker/configurator /usr/share/nginx/configurator

RUN chmod +x /usr/share/nginx/run.sh && \
    chmod -R a+rw /usr/share/nginx && \
    chmod -R a+rw /etc/nginx && \
    chmod -R a+rw /var && \
    chmod -R a+rw /var/run

EXPOSE 8080

WORKDIR /

CMD ["sh", "/usr/share/nginx/run.sh"]
