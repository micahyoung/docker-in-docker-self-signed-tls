#!/bin/bash
set -o errexit -o pipefail -o nounset

cleanup_commands=""
cleanup() {
  cleanup_commands+="$1 ;"
  trap "$cleanup_commands" EXIT
}

# Generate self-signed certs
if [ ! -d certs ]; then
  mkdir -p certs
  openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 -subj "/C=ZZ/ST=ZZ/L=ZZ/O=ZZ/CN=host.docker.internal" -keyout certs/certificate.key -out certs/certificate.crt
fi

# Add self-signed cert trusted root
if sudo security find-certificate -c host.docker.internal "/Library/Keychains/System.keychain" >/dev/null; then
  sudo security add-trusted-cert -d -r trustRoot -k "/Library/Keychains/System.keychain" certs/certificate.crt
  read -p "cert added. Restart docker and press any key to continue"
fi
cleanup "sudo security remove-trusted-cert -d certs/certificate.crt"

# Start a registry (and cleanup after exit)
cleanup "docker rm -f reg >/dev/null"
docker run --name reg -d -p 5000:5000 -v $PWD/certs:/certs -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/certificate.crt -e REGISTRY_HTTP_TLS_KEY=/certs/certificate.key registry:2

docker tag my-image host.docker.internal:5000/my-image

docker run -v '/var/run/docker.sock:/var/run/docker.sock' docker push host.docker.internal:5000/my-image