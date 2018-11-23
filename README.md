# BitBetter

This project is a tool to modify bitwardens core dll to allow me to self license.
Beware this does janky IL magic to rewrite the bitwarden core dll and install my self signed certificate.
Make sure to create a backup before using this tool!

## Step by step instructions

### Preperations for local building
Install docker and dotnet-sdk:
https://www.microsoft.com/net/download/linux-package-manager/ubuntu16-04/sdk-current

After installing docker, make sure that the service is started and your current user is in the docker group:
```bash
sudo systemctl start docker
sudo usermod -a -G docker $USER
```

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

If you have build the image on another pc, use the following commands to export the docker image and import it 
to your target machine:

```bash
# on the build machine
docker image save bitbetter/api > /tmp/bitbetter-api.tar

# on the target machine
docker load -i /tmp/bitbetter-api.tar
# optional, delete old bitbetter image
docker image rm <OLD IMAGE ID>
```

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
    dockerComposeFiles
    docker-compose pull --ignore-pull-failures
}
```

### Restart Bitwarden
Now restart Bitwarden using `bitwarden.sh restart`. Everything should work as usual.


## Signing new licenses

Run the licensing tool:
```bash
./src/licenseGen/run.sh <PATH TO YOUR PFX>
```
### Generate a new user license:
```bash
./src/licenseGen/run.sh /home/bitwarden/BitBetter/.keys/cert.pfx user "User Name" "email@test.de" "USER-GUID"
```

### Generate a new organisation license:
```bash
./src/licenseGen/run.sh /home/bitwarden/BitBetter/.keys/cert.pfx org "Shared Vault" "billing@test.de" "INSTALL-GUID"
```

## Updating Bitwarden
Here is a step by step guide to update bitwarden and bitbetter:

Run the updateself and update command:
```bash
./bitwarden.sh updateself
sudo ./bitwarden.sh update
```
The update script will fail.

Now edit the `<bitwarden home>/bitwarden.sh` file and disable re-downloading of the run file (comment out *downloadRunFile*):
```bash
...
elif [ "$1" == "update" ]
then
    checkOutputDirExists
    #downloadRunFile
    $SCRIPTS_DIR/run.sh update $OUTPUT $COREVERSION $WEBVERSION
...
```

Now add `--ignore-pull-failures` to the commands in the `dockerComposePull` function of the run file (same procedure as for the initial installation) `<bitwarden home>/bwdata/scripts/run.sh`:
```bash
function dockerComposePull() {
    dockerComposeFiles
    docker-compose pull --ignore-pull-failures
}
```

Now run the update script again:
```bash
sudo ./bitwarden.sh update
```
This time it should finish sucessfully.
Next you have to rebuild bitbetter/api:

First stop bitwarden:
```bash
sudo ./bitwarden.sh stop
```
Then run the steps from the *Building* section of this README.

As a last step, remove the comment in front of *downloadRunFile* in the `<bitwarden home>/bitwarden.sh` again.

# Questions (you might have?)

## But why? Its open source?

Yes, bitwarden is great.
I was bothered that if i want to host bitwarden myself, at my house, 
for my family to use (with the ability to share access) I would still have to pay a monthly ENTERPRISE organization fee.

Until Bitwarden offers a better license (family, 4 members for example) for account sharing that allows self hosted installations, I will have to use this tool.

