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
echo "Adding self-signed cert to MacOS trusted CA root store. This requires sudo. Cert will be removed from root store at the end of this script"
sudo security add-trusted-cert -d -r trustRoot -k "/Library/Keychains/System.keychain" certs/certificate.crt
cleanup "sudo security remove-trusted-cert -d certs/certificate.crt"

echo "cert added but docker needs to be restarted for system certs to be accessible do the daemon"
read -p "Restart docker, wait for restart, and press any key to continue"

# Start a registry (and cleanup after exit)
docker run --name reg -d -p 5000:5000 -v $PWD/certs:/certs -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/certificate.crt -e REGISTRY_HTTP_TLS_KEY=/certs/certificate.key registry:2
cleanup "docker rm -f reg >/dev/null"

docker tag registry:2 host.docker.internal:5000/my-image

docker run -v '/var/run/docker.sock:/var/run/docker.sock' docker push host.docker.internal:5000/my-image
