ARG BITWARDEN_TAG

FROM mcr.microsoft.com/dotnet/sdk:5.0 as build

WORKDIR /licenseGen

COPY ./src/licenseGen /licenseGen

RUN set -e; set -x; \
	dotnet add package Newtonsoft.Json --version 12.0.3 \
	&& dotnet restore \
	&& dotnet publish -o bin


FROM ${BITWARDEN_TAG}

COPY --from=build /licenseGen/bin/licenseGen.dll /app/
COPY ./publicKeys/cert.pfx /cert.pfx

ENTRYPOINT [ "dotnet", "/app/licenseGen.dll", "--core", "/app/Core.dll", "--cert", "/cert.pfx", "interactive" ]