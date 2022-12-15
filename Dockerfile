FROM ubuntu:20.04

RUN apt update
RUN apt install apache2-utils -y
RUN apt install curl -y
RUN apt install jq -y

RUN mkdir -p /opt/cs-stream-humio-connector/from_cs
RUN mkdir -p /opt/cs-stream-humio-connector/to_humio
COPY ./src/*.sh /opt/cs-stream-humio-connector/
RUN chmod +x /opt/cs-stream-humio-connector/*.sh

WORKDIR /opt/cs-stream-humio-connector

ENTRYPOINT [ "/opt/cs-stream-humio-connector/main.sh" ]