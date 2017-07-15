#!/bin/bash

bosh -e 192.168.50.6 \
  alias-env vbox \
  --ca-cert <(bosh int creds.yml --path /director_ssl/ca)

bosh int creds.yml \
  --path /jumpbox_ssh/private_key \
  > jumpbox.key

chmod 600 ~/vbox/jumpbox.key

export BOSH_ENVIRONMENT=vbox
export BOSH_CLIENT=admin
export BOSH_CLIENT_SECRET=`bosh int creds.yml --path /admin_password`

bosh -n log-in
bosh -n update-cloud-config cloud-config.yml
bosh -n cloud-config

