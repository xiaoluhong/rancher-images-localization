ARG IMGS
FROM ${IMGS}

COPY run.sh /run.sh

RUN chmod +x /run.sh && sh /run.sh && rm -rf /run.sh
