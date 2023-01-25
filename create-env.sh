#!/usr/bin/env bash

set -euxo pipefail

# To run bosh CLI using docker cpi:
# https://github.com/cloudfoundry-attic/bosh-lite/issues/439#issuecomment-348329967
dockerd > /dev/null 2>&1 &

export BOSH_LOG_LEVEL=none
bosh -n --tty create-env /bosh-deployment/bosh.yml \
  -o /bosh-deployment/docker/cpi.yml \
  -o /bosh-deployment/docker/unix-sock.yml \
  -o /bosh-deployment/uaa.yml \
  -o /bosh-deployment/credhub.yml \
  -o /bosh-deployment/jumpbox-user.yml \
  --state=/workspace/state.json              \
  --vars-store /workspace/creds.yml          \
  -v director_name=bosh-lite \
  -v internal_cidr=10.245.0.0/16 \
  -v internal_gw=10.245.0.1 \
  -v internal_ip=10.245.0.10 \
  -v docker_host=unix:///var/run/docker.sock \
  -v network=NatNetwork
  # -v network=net3
##

# Docker CPI - Cannot upload stemcell due to "Cannot connect to the Docker daemon... Is the docker daemon running?"
# https://github.com/cloudfoundry/bosh-deployment/issues/94
chmod 777 /var/run/docker.sock

rm -Rf /shared-creds/*
ssh-keygen -t rsa -q -f /shared-creds/id_rsa -N ""
mkdir -p ~/.ssh && cat /shared-creds/id_rsa.pub | cat > ~/.ssh/authorized_keys
/etc/init.d/ssh start

# https://medium.com/@ravijagannathan/install-cloud-foundry-on-bosh-lite-6d3b9a1e416a
# https://github.com/cloudfoundry-attic/bosh-lite/blob/master/bin/add-route
add-route

cat << EOF > /shared-creds/bosh-creds.bash
export BOSH_CLIENT_SECRET='$(bosh int /workspace/creds.yml --path /admin_password)'
export BOSH_CA_CERT='$(bosh int /workspace/creds.yml --path /director_ssl/ca)'
export BOSH_CLIENT=admin
export BOSH_ENVIRONMENT=https://10.245.0.10:25555
# export BOSH_ALL_PROXY=ssh+sock5://root@bosh-in-docker:22?private-key=/shared-creds/id_rsa
export BOSH_GW_USER=root
export BOSH_GW_HOST=bosh-in-docker
export BOSH_GW_PRIVATE_KEY='$(cat /shared-creds/id_rsa)'
export CREDHUB_SERVER=10.245.0.10:8844
export CREDHUB_CLIENT=credhub-admin
export CREDHUB_SECRET="$(bosh -n --tty interpolate /workspace/creds.yml --path=/credhub_admin_client_secret | head -n -2)"
export CREDHUB_CA_CERT="$(bosh -n --tty interpolate /workspace/creds.yml --path=/credhub_tls/ca | head -n -2)"$'\n'"$(bosh -n --tty interpolate /workspace/creds.yml --path=/uaa_ssl/ca | head -n -2)"
EOF

source /shared-creds/bosh-creds.bash
bosh -n --tty update-cloud-config /bosh-deployment/docker/cloud-config.yml -v network=NatNetwork
bosh -n --tty update-runtime-config /bosh-deployment/runtime-configs/dns.yml --name dns
bosh -n --tty update-cloud-config /bosh-in-docker/cloud-config.yml -v network=NatNetwork

pushd "/cf-deployment"
  export STEMCELL_TYPE=$(bosh int cf-deployment.yml --path /stemcells/alias=default/os)
  export STEMCELL_VERSION=$(bosh int cf-deployment.yml --path /stemcells/alias=default/version)
  bosh -n --tty upload-stemcell https://bosh.io/d/stemcells/bosh-warden-boshlite-$STEMCELL_TYPE-go_agent?v=$STEMCELL_VERSION

  bosh -n --tty -d cf deploy "cf-deployment.yml" \
   -o "/bosh-in-docker/bosh-lite.yml" \
   -o "operations/scale-to-one-az.yml" \
   -o "operations/use-compiled-releases.yml" \
   -v system_domain="bosh-in-docker" \
   --no-redact || true # prevent container from automatically terminating because of the error

popd

while true; do sleep 30; done;
