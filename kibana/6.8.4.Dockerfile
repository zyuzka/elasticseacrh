FROM centos:7 AS prep_files

ARG TARGETPLATFORM

# Install toolchain to build dumb-init
RUN yum install -y glibc-static gcc make

RUN mkdir /usr/share/kibana
WORKDIR /usr/share/kibana

RUN curl -sL https://artifacts.elastic.co/downloads/kibana/kibana-oss-6.8.4-linux-x86_64.tar.gz | tar --strip-components=1 -zxf -
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

## Set some Kibana configuration defaults.
#COPY --chown=1000:0 config/kibana.yml /usr/share/kibana/config/kibana.yml

# Add the launcher/wrapper script. It knows how to interpret environment
# variables and translate them to Kibana CLI options.
COPY --chown=1000:0 bin/kibana-docker /usr/local/bin/

# Ensure gid 0 write permissions for OpenShift.
RUN chmod g+ws /usr/share/kibana && find /usr/share/kibana -gid 0 -and -not -perm /g+w -exec chmod g+w {} \;

# Provide a non-root user to run the process.
RUN groupadd --gid 1000 kibana && useradd --uid 1000 --gid 1000 --home-dir /usr/share/kibana --no-create-home kibana
USER kibana

LABEL org.label-schema.schema-version="1.0" org.label-schema.vendor="Elastic" org.label-schema.name="kibana" org.label-schema.version="7.6.2-SNAPSHOT" org.label-schema.url="https://www.elastic.co/products/kibana" org.label-schema.vcs-url="https://github.com/elastic/kibana" org.label-schema.license="ASL 2.0" org.label-schema.usage="https://www.elastic.co/guide/en/kibana/index.html" org.label-schema.build-date="2020-04-11T05:35:13.592Z" license="ASL 2.0"

ENTRYPOINT ["/usr/local/bin/dumb-init", "--"]

CMD ["/usr/local/bin/kibana-docker"]

#FROM volhovm/kibana:6.8.10-arm
#FROM blacktop/kibana:6.8.4
#FROM debian:stable-slim
#
#ARG TARGETPLATFORM
#ARG KIBANA_VERSION=v6.8.4
#ARG NODE_VERSION=v10.15.2
#
#ENV USERNAME "kibana"
#ENV HOME "/home/${USERNAME}"
#ENV NVM_DIR "${HOME}/.nvm"
#
#RUN apt update -y && \
#    apt install -y \
#    bash \
#    git \
#    curl \
#    apt-utils \
#    build-essential \
#    bash-completion \
#    make \
#    python2
#
#RUN addgroup ${USERNAME} \
#  && useradd --home ${HOME} --shell /bin/sh --groups ${USERNAME} --gid ${USERNAME} ${USERNAME} \
#  && mkdir -p ${HOME} \
#  && mkdir -p ${NVM_DIR} \
#  && chown ${USERNAME}:${USERNAME} ${HOME} \
#  && chown ${USERNAME}:${USERNAME} /usr/share \
#  && chown ${USERNAME}:${USERNAME} -R ${NVM_DIR}
#
#USER ${USERNAME}
#
## nvm
#RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
#RUN chmod -R 777 ${NVM_DIR}
#RUN echo 'export NVM_DIR="${NVM_DIR}"' >> "${HOME}/.bashrc"
#RUN echo '[ -s "${NVM_DIR}/nvm.sh" ] && . "${NVM_DIR}/nvm.sh"  # This loads nvm' >> "${HOME}/.bashrc"
#RUN echo '[ -s "${NVM_DIR}/bash_completion" ] && . "${NVM_DIR}/bash_completion" # This loads nvm bash_completion' >> "${HOME}/.bashrc"
#
#WORKDIR ${HOME}
#
#RUN git clone -b v6.8.4 https://github.com/elastic/kibana.git --single-branch kibana
#
#WORKDIR ${HOME}/kibana
#RUN git config --global url."https://github.com/".insteadOf git://github.com/
#RUN bash -c 'source ${HOME}/.nvm/nvm.sh && nvm install "$(cat .node-version)" \
#    && npm install -g yarn \
#    && yarn remove node-sass \
#    && yarn add sass@~1.32.13 \
#    && yarn install \
#    && yarn kbn bootstrap \
#    && node scripts/build --skip-archives --skip-os-packages --no-oss'
#
#ENV NODE_PATH ${NVM_DIR}/${NODE_VERSION}/lib/node_modules
#ENV PATH /home/kibana/.nvm/versions/node/${NODE_VERSION}/bin:$PATH
#ENV NODE_OPTIONS --max-old-space-size=5000
#
##RUN bash -c 'node scripts/build --skip-archives --skip-os-packages --no-oss'
#
#RUN mv build/kibana /usr/share/kibana
#RUN rm -rf ${HOME}/kibana
#
#EXPOSE 5601
#
#WORKDIR /usr/share/kibana
#
#CMD ["bin/kibana"]
