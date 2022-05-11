FROM debian:stable-slim

ARG TARGETPLATFORM
ARG KIBANA_VERSION=v5.6.16

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
RUN echo 'export NVM_DIR="${NVM_DIR}"'                                       >> "${HOME}/.bashrc"
RUN echo '[ -s "${NVM_DIR}/nvm.sh" ] && . "${NVM_DIR}/nvm.sh"  # This loads nvm' >> "${HOME}/.bashrc"
RUN echo '[ -s "${NVM_DIR}/bash_completion" ] && . "${NVM_DIR}/bash_completion" # This loads nvm bash_completion' >> "${HOME}/.bashrc"

WORKDIR /usr/share

RUN git clone -b ${KIBANA_VERSION} https://github.com/elastic/kibana.git --single-branch kibana

WORKDIR /usr/share/kibana
RUN git config --global url."https://github.com/".insteadOf git://github.com/
RUN bash -c 'source ${HOME}/.nvm/nvm.sh && nvm install "$(cat .node-version)" \
    && npm uninstall node-sass \
    && npm install sass@~1.32.13 sass-loader@~10.2.0 \
    && npm install'

EXPOSE 5601

WORKDIR /usr/share/kibana

CMD ["bin/kibana"]
