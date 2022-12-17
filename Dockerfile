FROM ubuntu:20.04

RUN apt update && \
    apt install apache2-utils -y && \
    apt install curl -y && \
    apt install jq -y  

RUN mkdir -p /opt/cs-stream-logscale-connector/from_cs && \
    mkdir /opt/cs-stream-logscale-connector/to_logscale && \
    mkdir /opt/cs-stream-logscale-connector/offset
COPY ./src/*.sh /opt/cs-stream-logscale-connector/
RUN chmod +x /opt/cs-stream-logscale-connector/*.sh

WORKDIR /opt/cs-stream-logscale-connector

ENTRYPOINT [ "/opt/cs-stream-logscale-connector/process_keeper.sh" ]