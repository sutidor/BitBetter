FROM alpine:latest

RUN apk update && \
  apk add --no-cache openssl && \
  rm -rf "/var/cache/apk/*"

WORKDIR /certs
VOLUME /certs

CMD [ "/bin/sh", "generate-keys.sh"]