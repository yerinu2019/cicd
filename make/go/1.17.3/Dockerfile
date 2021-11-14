FROM golang:1.17-buster
MAINTAINER yerinu2012
# vi: ft=dockerfile

RUN apt-get update && apt-get install curl \
                          git \
                          protobuf-compiler \
                          bash \
                          make \
                          openssh-client && \
     curl https://wasmtime.dev/install.sh -sSf | bash && \
     rm -rf /var/cache/apt/*