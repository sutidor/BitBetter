#!/bin/bash

SCRIPT_BASE="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
BW_VERSION="$(curl --silent https://raw.githubusercontent.com/bitwarden/server/master/scripts/bitwarden.sh | grep 'COREVERSION="' | sed 's/^[^"]*"//; s/".*//')"

echo "Starting Bitwarden update, newest server version: $BW_VERSION"

# Default path is the parent directory of the BitBetter location
BITWARDEN_BASE="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Get Bitwarden base from user (or keep default value)
read -p "Enter Bitwarden base directory [$BITWARDEN_BASE]: " tmpbase
BITWARDEN_BASE=${tmpbase:-$BITWARDEN_BASE}

# Check if directory exists and is valid
[ -d "$BITWARDEN_BASE" ] || { echo "Bitwarden base directory $BITWARDEN_BASE not found!"; exit 1; }
[ -f "$BITWARDEN_BASE/bitwarden.sh" ] || { echo "Bitwarden base directory $BITWARDEN_BASE is not valid!"; exit 1; }


# Check if BitBetter directory exists; if exists ask to regenerate, if not generate
if [ ! -d "$BITWARDEN_BASE/BitBetter" ]; then
    docker pull yaoa/bitbetter:certificate-gen-latest
    docker run --rm -v $BITWARDEN_BASE/bwdata/bitbetter:/certs yaoa/bitbetter:certificate-gen-latest
    echo "Certificates generated!"
else
    # Check if user wants to regenerate certificates
    REGEN_CERT="n"
    read -p "Regenerate certificates? [y/N]: " tmprecreate
    REGEN_CERT=${tmprecreate:-$REGEN_CERT}

    if [[ $REGEN_CERT =~ ^[Yy]$ ]]
    then
        docker pull yaoa/bitbetter:certificate-gen-latest
        docker run --rm -v $BITWARDEN_BASE/bwdata/bitbetter:/certs yaoa/bitbetter:certificate-gen-latest
    else
        echo "Not creating new certificates!"
    fi
fi;


# Check if user wants to recreate the docker-compose override file
RECREATE_OV="y"
read -p "Rebuild docker-compose override? [Y/n]: " tmprecreate
RECREATE_OV=${tmprecreate:-$RECREATE_OV}

if [[ $RECREATE_OV =~ ^[Yy]$ ]]
then
    {
        echo "version: '3'"
        echo ""
        echo "services:"
        echo "  api:"
        echo "    image: yaoa/bitbetter:api-custom-$BW_VERSION"
        echo "    volumes:"
        echo "      - ../bitbetter/cert.cert:/newLicensing.cer"
        echo ""
        echo "  identity:"
        echo "    image: yaoa/bitbetter:identity-custom-$BW_VERSION"
        echo "    volumes:"
        echo "      - ../bitbetter/cert.cert:/newLicensing.cer"
        echo ""
    } > $BITWARDEN_BASE/bwdata/docker/docker-compose.override.yml
    echo "BitBetter docker-compose override created!"
else
    echo "Make sure to check if the docker override contains the correct image version ($BW_VERSION) in $BITWARDEN_BASE/bwdata/docker/docker-compose.override.yml!"
fi

# Now start the bitwarden update
cd $BITWARDEN_BASE

./bitwarden.sh updateself

./bitwarden.sh update

./bitwarden.sh restart

cd $SCRIPT_BASE
echo "Bitwarden update completed!"