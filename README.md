# BitBetter
[![CircleCI](https://img.shields.io/circleci/project/github/jakeswenson/BitBetter.svg)](https://circleci.com/gh/jakeswenson/BitBetter/tree/master)

This project is a tool to modify bitwardens core dll to allow me to self license.
Beware this does janky IL magic to rewrite the bitwarden core dll and install my self signed certificate.

## Step by step instructions

### Preperations for local building (without docker build environment)
https://www.microsoft.com/net/download/linux-package-manager/ubuntu16-04/sdk-current
```bash
cd <location of BitBetter>
```

### Generate Keys
```bash
cd .keys
rm *
```
Generate a new key. Use "test" as password!
```bash
openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.cert -days 36500 -outform DER
```
Convert your DER certificate to a PEM
```bash
openssl x509 -inform DER -in cert.cert -out cert.pem
```
Convert your public and private key into a PKCS12/PFX. Also use "test" as output password (licenseGen Tool has test as hardcoded password)
```bash
openssl pkcs12 -export -out cert.pfx -inkey key.pem -in cert.pem
```
Change back to main directory of BitBetter
```bash
cd ..
```

### Building
```bash
./build.sh
./src/licenseGen/build.sh
```

### Deploying newly build Docker Image
The build process creates a local docker image called `bitbetter/api` which replaces `bitwarden/api`.

To replace the image copy the file `<bitwarden home>/bwdata/docker/docker-compose.yml` to `<bitwarden home>/bwdata/docker/docker-compose.override.yml`.
Change the contents of the override file to the following:
```
# https://docs.docker.com/compose/compose-file/
# Parameter:MssqlDataDockerVolume=False
# Parameter:HttpPort=80
# Parameter:HttpsPort=443
# Parameter:CoreVersion=1.20.0
# Parameter:WebVersion=1.27.0

version: '3'

services:
  api:
    image: bitbetter/api:latest
    container_name: bitwarden-api
    restart: always
    volumes:
      - ../core:/etc/bitwarden/core
      - ../ca-certificates:/etc/bitwarden/ca-certificates
      - ../logs/api:/etc/bitwarden/logs
    env_file:
      - global.env
      - ../env/uid.env
      - ../env/global.override.env
```

As `bitbetter/api` only exists localy, you have to update the script `<bitwarden home>/bwdata/scripts/run.sh`:
Add `--ignore-pull-failures` to the commands in the `dockerComposePull` function:
```bash
function dockerComposePull() {
    if [ -f "${DOCKER_DIR}/docker-compose.override.yml" ]
    then
        docker-compose -f $DOCKER_DIR/docker-compose.yml -f $DOCKER_DIR/docker-compose.override.yml pull --ignore-pull-failures
    else
        docker-compose -f $DOCKER_DIR/docker-compose.yml pull --ignore-pull-failures
    fi
}
```

### Restart Bitwarden
Now restart Bitwarden using `bitwarden.sh restart`. Everything should work as usual.


## Signing new licenses

Run the licensing tool:
```bash
./src/LicenseGen/run.sh <PATH TO YOUR PFX>
```
### Generate a new user license:
```bash
./src/LicenseGen/run.sh /home/bitwarden/BitBetter/.keys/cert.pfx user "User Name" "email@test.de" "GUID"
```
