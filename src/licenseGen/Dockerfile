ARG BITWARDEN_TAG

FROM mcr.microsoft.com/dotnet/sdk:5.0 as build

WORKDIR /licenseGen

COPY ./src/licenseGen /licenseGen

RUN set -ex \
	&& dotnet add package Newtonsoft.Json --version 12.0.3 \
	&& dotnet restore \
	&& dotnet publish -o bin


FROM ${BITWARDEN_TAG} as base

COPY --from=build /licenseGen/bin/* /app/

FROM base as public

COPY ./publicKeys/cert.pfx /cert.pfx

ENTRYPOINT [ "dotnet", "/app/licenseGen.dll", "--core", "/app/Core.dll", "--cert", "/cert.pfx", "interactive" ]

FROM base as custom

ENTRYPOINT [ "dotnet", "/app/licenseGen.dll", "--core", "/app/Core.dll", "--cert", "/cert.pfx", "interactive" ]
