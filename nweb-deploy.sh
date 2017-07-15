#!/bin/bash

set -e

git submodule update --init nweb-release

cd nweb-release

bosh -n upload-stemcell https://bosh.io/d/stemcells/bosh-warden-boshlite-ubuntu-trusty-go_agent

bosh -n create-release
bosh -n upload-release
bosh -n -d nweb deploy manifest.mf

