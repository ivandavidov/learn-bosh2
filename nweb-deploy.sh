#!/bin/bash

set -e

export BOSH_ENVIRONMENT=vbox
export BOSH_CLIENT=admin
export BOSH_CLIENT_SECRET=`bosh int creds.yml --path /admin_password`

git submodule update --init nweb-release

cd nweb-release

rm -rf .dev_builds
rm -rf dev_releases

bosh -n -d nweb delete-deployment
bosh -n delete-release nweb-release

if [ "`bosh stemcells | grep ubuntu-trusty`" = "" ]
then
  if [ ! -e stemcell-ubuntu-trusty.tgz ]
  then
    wget -O stemcell-ubuntu-trusty.tgz \
      https://bosh.io/d/stemcells/bosh-warden-boshlite-ubuntu-trusty-go_agent
  fi

  bosh -n upload-stemcell stemcell-ubuntu-trusty.tgz
fi

bosh -n create-release --force
bosh -n upload-release
bosh -n -d nweb deploy manifest.yml

bosh vms

set +x

