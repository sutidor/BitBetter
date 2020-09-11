#!/bin/sh

docker build -t bitbetter/certificate-gen .
docker run --rm -v "$PWD:/certs" bitbetter/certificate-gen