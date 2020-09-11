FROM mcr.microsoft.com/dotnet/core/sdk:3.1 as build

WORKDIR /licenseGen

COPY ./src/licenseGen /licenseGen

RUN set -e; set -x; \
	dotnet add package Newtonsoft.Json --version 12.0.3 \
	&& dotnet restore \
	&& dotnet publish


FROM yaoa/bitbetter:api-latest

COPY --from=build /licenseGen/bin/Debug/netcoreapp3.1/publish/* /app/
COPY ./publicKeys/cert.pfx /cert.pfx

ENTRYPOINT [ "dotnet", "/app/licenseGen.dll", "--core", "/app/Core.dll", "--cert", "/cert.pfx", "interactive" ]
