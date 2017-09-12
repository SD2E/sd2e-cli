#################################################################
#
# docker run -it -v $HOME/.agave:/root/.agave TACC/cloud-cli bash
#
#################################################################

FROM ubuntu:xenial

RUN apt-get -y update && \
    apt-get -y install -y  git \
                        vim.tiny \
                        curl \
                        python \
                        python-pip && \
    apt-get -y clean

RUN curl -L -sk -o /usr/local/bin/jq "https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64" \
    && chmod a+x /usr/local/bin/jq

ADD tacc-cloud-cli /usr/local/tacc-cloud-cli
ENV PATH $PATH:/usr/local/tacc-cloud-cli/bin

# RUN echo export PS1=\""\[\e[32;4m\]tacc-cloud\[\e[0m\]:$AGAVE_TENANT:$AGAVE_USERNAME@\h:\w$ "\" >> /root/.bashrc

# Set user's default env. This won't get sourced, but is helpful
RUN echo HOME=/root >> /root/.bashrc && \
    echo AGAVE_CACHE_DIR=/root/.agave >> /root/.bashrc && \
    echo PROMPT_COMMAND=/usr/local/tacc-cloud-cli/bin/prompt_command >> /root/.bashrc && \
    echo export PS1=\"\\h:\\w\$ \" >> /root/.bashrc && \
    usr/local/tacc-cloud-cli/bin/tenants-init -t tacc.cloud.prod

# Runtime parameters. Start a shell by default
VOLUME /root/.agave
CMD "/bin/bash"
