# Just here to please docker and allow for code reuse
ARG BITWARDEN_TAG

FROM alpine:latest

RUN apk update && \
  apk add --no-cache openssl && \
  rm -rf "/var/cache/apk/*"

COPY ./publicKeys/generate-keys.sh /script/

WORKDIR /certs
VOLUME /certs

CMD [ "/bin/sh", "/script/generate-keys.sh"]