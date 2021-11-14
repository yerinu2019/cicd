FROM golang:1.17-alpine
MAINTAINER yerinu2012
# vi: ft=dockerfile

RUN apk update && apk add curl \
                          git \
                          protobuf \
                          bash \
                          make \
                          openssh-client && \
     rm -rf /var/cache/apk/*