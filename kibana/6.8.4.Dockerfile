FROM debian:stable-slim

ARG TARGETPLATFORM
ARG KIBANA_VERSION=v6.8.4
ARG NODE_VERSION=v10.15.2

ENV USERNAME "kibana"
ENV HOME "/home/${USERNAME}"
ENV NVM_DIR "${HOME}/.nvm"

RUN apt update -y && \
    apt install -y \
    bash \
    git \
    curl \
    apt-utils \
    build-essential \
    bash-completion \
    make \
    python2

RUN addgroup ${USERNAME} \
  && useradd --home ${HOME} --shell /bin/sh --groups ${USERNAME} --gid ${USERNAME} ${USERNAME} \
  && mkdir -p ${HOME} \
  && mkdir -p ${NVM_DIR} \
  && chown ${USERNAME}:${USERNAME} ${HOME} \
  && chown ${USERNAME}:${USERNAME} /usr/share \
  && chown ${USERNAME}:${USERNAME} -R ${NVM_DIR}

USER ${USERNAME}

# nvm
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
RUN chmod -R 777 ${NVM_DIR}
RUN echo 'export NVM_DIR="${NVM_DIR}"' >> "${HOME}/.bashrc"
RUN echo '[ -s "${NVM_DIR}/nvm.sh" ] && . "${NVM_DIR}/nvm.sh"  # This loads nvm' >> "${HOME}/.bashrc"
RUN echo '[ -s "${NVM_DIR}/bash_completion" ] && . "${NVM_DIR}/bash_completion" # This loads nvm bash_completion' >> "${HOME}/.bashrc"

WORKDIR ${HOME}

RUN git clone -b ${KIBANA_VERSION} https://github.com/elastic/kibana.git --single-branch kibana

WORKDIR ${HOME}/kibana
RUN git config --global url."https://github.com/".insteadOf git://github.com/
RUN bash -c 'source ${HOME}/.nvm/nvm.sh && nvm install "$(cat .node-version)" \
    && npm install -g yarn \
    && yarn remove node-sass \
    && yarn add sass \
    && yarn install \
    && yarn kbn bootstrap'
RUN bash -c 'node scripts/build --skip-archives --skip-os-packages --no-oss'

RUN mv build/kibana /usr/share/kibana
RUN rm -rf ${HOME}/kibana

ENV NODE_PATH ${NVM_DIR}/${NODE_VERSION}/lib/node_modules
ENV PATH /home/kibana/.nvm/versions/node/${NODE_VERSION}/bin:$PATH
ENV NODE_OPTIONS --max-old-space-size=5000

EXPOSE 5601

WORKDIR /usr/share/kibana

CMD ["bin/kibana"]
