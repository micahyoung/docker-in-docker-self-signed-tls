$ErrorActionPreference="Stop"
# Note: this script is only meaningful if there is no insecure-registries entry for this host

if (!(Test-Path certs)) {
    mkdir certs
    openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 -subj "/C=ZZ/ST=ZZ/L=ZZ/O=ZZ/CN=host.docker.internal" -keyout certs\certificate.key -out certs\certificate.crt
}

# Check for existing self-signed certs of unknown origin
if (Get-ChildItem Cert:\LocalMachine\Root -Recurse | Where-Object {$_.Subject -like "*host.docker.internal*"}) {
    echo "An existing self-signed cert for host.docker.internal was found. Re-run after removing manually"
    echo 'PS > Get-ChildItem Cert:\LocalMachine\Root -Recurse | Where-Object {$_.Subject -like "*host.docker.internal*"} | Remove-Item'
    exit 1
}

try {
    # Import self-signed cert into trusted root
    Import-Certificate -FilePath certs\certificate.crt -CertStoreLocation cert:\LocalMachine\Root

    docker run --name reg -d -p 5000:5000 -v $PWD\certs:c:/certs -e REGISTRY_HTTP_TLS_CERTIFICATE=c:/certs/certificate.crt -e REGISTRY_HTTP_TLS_KEY=c:/certs/certificate.key --user ContainerAdministrator micahyoung/registry

    docker tag micahyoung/registry host.docker.internal:5000/my-image

    # Run with servercore, which the docker cli requires
    # Bind-mount in Docker CLI since Windows DIND images are out of date
    docker run -v '\\.\pipe\docker_engine:\\.\pipe\docker_engine' -v 'C:/Program Files/Docker/Docker/resources/bin:c:/bin' mcr.microsoft.com/windows/servercore:1809 cmd /c c:\bin\docker.exe push host.docker.internal:5000/my-image
} finally {
    # Remove cert
    Get-ChildItem Cert:\LocalMachine\Root -Recurse | Where-Object {$_.Subject -like "*host.docker.internal*"} | Remove-Item

    # Remove reg container
    docker rm -f reg
}

