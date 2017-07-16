#!/bin/bash

set -ex

git submodule update --init bosh-deployment

if [ "`ping -c 1 192.168.50.6 | grep -i '1 received'`" = "" ]
then
  rm -f state.json
  rm -f creds.yml
  rm -f jumpbox.key

  bosh create-env \
    bosh-deployment/bosh.yml \
    --state state.json \
    -o bosh-deployment/virtualbox/cpi.yml \
    -o bosh-deployment/virtualbox/outbound-network.yml \
    -o bosh-deployment/bosh-lite.yml \
    -o bosh-deployment/bosh-lite-runc.yml \
    -o bosh-deployment/jumpbox-user.yml \
    --vars-store creds.yml \
    -v director_name="Bosh Lite Director" \
    -v internal_ip=192.168.50.6 \
    -v internal_gw=192.168.50.1 \
    -v internal_cidr=192.168.50.0/24 \
    -v outbound_network_name=NatNetwork

  bosh -e 192.168.50.6 \
    alias-env vbox \
    --ca-cert <(bosh int creds.yml --path /director_ssl/ca)

  bosh int creds.yml \
    --path /jumpbox_ssh/private_key \
    > jumpbox.key

  chmod 600 jumpbox.key
fi

set +ex

if [ "`route | grep ^10\\.10\\.0\\.0`" = "" ]
then
  echo "You need to provide your 'sudo' password in order to add proper route configuration."
  echo "route add -net 10.10.0.0/16 gw 192.168.0.56"
  echo
  sudo route add -net 10.10.0.0/16 gw 192.168.50.6
fi

set -ex

export BOSH_ENVIRONMENT=vbox
export BOSH_CLIENT=admin
export BOSH_CLIENT_SECRET=`bosh int creds.yml --path /admin_password`

bosh -n log-in
bosh -n update-cloud-config cloud-config.yml
bosh -n cloud-config

git submodule update --init nweb-release

cd nweb-release

rm -rf .dev_builds
rm -rf dev_releases

if [ "`bosh stemcells | grep ubuntu-trusty`" = "" ]
then
  if [ ! -e stemcell-ubuntu-trusty.tgz ]
  then
    wget -O stemcell-ubuntu-trusty.tgz \
      https://bosh.io/d/stemcells/bosh-warden-boshlite-ubuntu-trusty-go_agent
  fi

  bosh -n upload-stemcell stemcell-ubuntu-trusty.tgz
fi

bosh -n -d nweb delete-deployment
bosh -n delete-release nweb-release

bosh -n create-release --force
bosh -n upload-release
bosh -n -d nweb deploy manifest.yml

bosh vms

firefox 10.10.0.10:8080

set +ex

