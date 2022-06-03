FROM centos:7 AS prep_files

ARG TARGETPLATFORM

# Install toolchain to build dumb-init
RUN yum install -y glibc-static gcc make

RUN mkdir /usr/share/kibana

WORKDIR /usr/share/kibana

RUN curl -sL https://artifacts.elastic.co/downloads/kibana/kibana-oss-7.6.2-linux-x86_64.tar.gz | tar --strip-components=1 -zxf -
RUN rm -rf /usr/share/kibana/node/* && \
    architecture=$(case ${TARGETPLATFORM} in "linux/amd64") echo "x64" ;; linux/arm64) echo "arm64" ;; *) echo "x64" ;; esac) && \
    curl -sL https://nodejs.org/dist/v10.19.0/node-v10.19.0-linux-${architecture}.tar.gz | tar -C /usr/share/kibana/node/ --strip-components=1 -xzf -

# compile dumb-init from sources
RUN mkdir -p /opt/dumb-init
RUN curl -sL https://github.com/Yelp/dumb-init/archive/v1.2.2.tar.gz | tar -C /opt/dumb-init --strip-components=1 -zxf -
RUN pushd /opt/dumb-init && make && popd

# Ensure that group permissions are the same as user permissions.
# This will help when relying on GID-0 to run Kibana, rather than UID-1000.
# OpenShift does this, for example.
# REF: https://docs.openshift.org/latest/creating_images/guidelines.html
RUN chmod -R g=u /usr/share/kibana
RUN find /usr/share/kibana -type d -exec chmod g+s {} \;

################################################################################
# Build stage 1
# Copy prepared files from the previous stage and complete the image.
################################################################################
FROM centos:7
EXPOSE 5601

# Add Reporting dependencies.
RUN yum update -y && yum install -y fontconfig freetype shadow-utils && yum clean all

# Bring in Kibana from the initial stage.
COPY --from=prep_files --chown=1000:0 /usr/share/kibana /usr/share/kibana
# Bring in dumb-init from the initial stage.
COPY --from=prep_files --chown=1000:0 /opt/dumb-init/dumb-init  /usr/local/bin/dumb-init

WORKDIR /usr/share/kibana
RUN ln -s /usr/share/kibana /opt/kibana

ENV ELASTIC_CONTAINER true
ENV PATH=/usr/share/kibana/bin:$PATH

# Ensure gid 0 write permissions for OpenShift.
RUN chmod g+ws /usr/share/kibana && find /usr/share/kibana -gid 0 -and -not -perm /g+w -exec chmod g+w {} \;

# Provide a non-root user to run the process.
RUN groupadd --gid 1000 kibana && useradd --uid 1000 --gid 1000 --home-dir /usr/share/kibana --no-create-home kibana
USER kibana

LABEL org.label-schema.schema-version="1.0" org.label-schema.vendor="Elastic" org.label-schema.name="kibana" org.label-schema.version="7.6.2-SNAPSHOT" org.label-schema.url="https://www.elastic.co/products/kibana" org.label-schema.vcs-url="https://github.com/elastic/kibana" org.label-schema.license="ASL 2.0" org.label-schema.usage="https://www.elastic.co/guide/en/kibana/index.html" org.label-schema.build-date="2020-04-11T05:35:13.592Z" license="ASL 2.0"

ENTRYPOINT ["/usr/local/bin/dumb-init", "--"]

CMD ["/usr/share/kibana/bin/kibana"]
