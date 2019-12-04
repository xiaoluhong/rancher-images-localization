ARG IMGS
ARG USER
FROM ${IMGS}

USER root

COPY run.sh /run.sh
RUN chmod +x /run.sh \
&&  sh /run.sh \
&&  rm -rf /run.sh

USER ${USER}