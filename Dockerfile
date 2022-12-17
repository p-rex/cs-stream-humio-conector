FROM ubuntu:20.04

RUN apt update && \
    apt install apache2-utils -y && \
    apt install curl -y && \
    apt install jq -y  

RUN mkdir -p /opt/cs-stream-humio-connector/from_cs && \
    mkdir /opt/cs-stream-humio-connector/to_humio && \
    mkdir /opt/cs-stream-humio-connector/offset
COPY ./src/*.sh /opt/cs-stream-humio-connector/
RUN chmod +x /opt/cs-stream-humio-connector/*.sh

WORKDIR /opt/cs-stream-humio-connector

ENTRYPOINT [ "/opt/cs-stream-humio-connector/process_keeper.sh" ]