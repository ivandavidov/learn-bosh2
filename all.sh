#!/bin/bash

# -e - exit on error
# -x - print script line  
set -ex

# Update the 'bosh-deployment' submodule. You can get the latest
# submodule sources like this:
#
# git submodule update --init --remote bosh-deploymente
#
# The original GitHub repo is here:
# https://github.com/cloudfoundry/bosh-deployment
git submodule update --init bosh-deployment

# Check whether the BOSH director is running. If there is no
# reposne, the assumption is that the bosh-lite VirtualBox VM
# is not present. You can delete all obsolete VMs manually by
# using the 'virtualbox' UI. 
if [ "`ping -c 1 192.168.50.6 | grep -i '1 received'`" = "" ]
then
  # Delete all previously generated artifacts.
  rm -f state.json
  rm -f creds.yml
  rm -f jumpbox.key

  # Create the bosh-lite VM. The BOSH director responds at IP
  # address 192.168.50.6. Additional routing rule is required
  # later in order to access other BOSH deploymnts. 
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

  # Create alias 'vbox' for our BOSH environment.
  bosh -e 192.168.50.6 \
    alias-env vbox \
    --ca-cert <(bosh int creds.yml --path /director_ssl/ca)

  ########################################################################
  #                                                                      #
  # Extract the private key for the 'jumpbox' user.                      #
  # We can use this key to connect to the director VM like this:         #
  #                                                                      #
  # ssh -oStrictHostKeyChecking=no jumpbox@192.168.50.6 -i jumpbox.key   #
  #                                                                      #
  # After you issue the command you may want to explore these locations: #
  #                                                                      #
  #   /var/vcap/sys/log                                                  #
  #   /var/vcap/jobs                                                     #
  #   /var/vcap/packages                                                 #
  #                                                                      #
  ########################################################################
  bosh int creds.yml \
    --path /jumpbox_ssh/private_key \
    > jumpbox.key

  # For security we allow the private key to be accessible only
  # by the currently logged user.
  chmod 600 jumpbox.key
fi

# Temporarily we turn off the debugging options.
set +ex

# Check if we have routing rule for the 10.10.0.0/16 network.
if [ "`route | grep ^10\\.10\\.0\\.0`" = "" ]
then
  echo "You need to provide your 'sudo' password in order to add proper route configuration."
  echo "route add -net 10.10.0.0/16 gw 192.168.0.56"
  echo
  # Add routing rule for the 10.10.0.0/16 network.
  sudo route add -net 10.10.0.0/16 gw 192.168.50.6
fi

# We set again the debugging options.
set -ex

######################################################################
#                                                                    #
# You need the following 3 exports in your shell if you want to work #
# with the 'bosh' command from terminal.                             #
#                                                                    #
######################################################################

# With this we don't need to specify the '--environment' switch.
export BOSH_ENVIRONMENT=vbox

# With this we don't need to specify the '---client' switch.
export BOSH_CLIENT=admin

# With this we don't need to specify the '---client-secret' switch.
export BOSH_CLIENT_SECRET=`bosh int creds.yml --path /admin_password`

# Log in to the director instance.
bosh -n log-in

# Load/update the common cloud configuration. 
bosh -n update-cloud-config cloud-config.yml

# Print the cloud configuration (just for information).
bosh -n cloud-config

###################################################################
#                                                                 #
# At this point we are done with the BOSH director configuration. #
# Now we move on with the nWeb server deployment procedure.       #
#                                                                 #
###################################################################

# Update the 'nweb-release' submodule. You can get the latest
# submodule sources like this:
#
# git submodule update --init --remote nweb-release
#
# The original GitHub repo is here:
# https://github.com/ivandavidov/nweb-release
git submodule update --init nweb-release

cd nweb-release

# The build process generates these folder. Removing them before the
# next build process ensures that we always build version '1' of the
# nWeb release.
rm -rf .dev_builds
rm -rf dev_releases

# The nWeb release depends on the Ubuntu stemcell and we check if this
# stemcell is already available in the director environment.
if [ "`bosh stemcells | grep ubuntu-trusty`" = "" ]
then
  # The stemcell does not exist in the director nevironment and now we
  # check if the same stemcell has already been downloaded loclly and
  # saved as 'stemcell-ubuntu-trusty.tgz'. 
  if [ ! -e stemcell-ubuntu-trusty.tgz ]
  then
    # Nope, the stemcell hasn't been downloaded yet. We do that now.
    # The stemcell is saved as 'stemcell-ubuntu-trusty.tgz'.
    wget -O stemcell-ubuntu-trusty.tgz \
      https://bosh.io/d/stemcells/bosh-warden-boshlite-ubuntu-trusty-go_agent
  fi

  # We use the already downloaded Ubuntu stemcell and we upload it in the
  # director environment.
  bosh -n upload-stemcell stemcell-ubuntu-trusty.tgz
fi

# We delete the previous 'nweb' deployment from the bosh environment.
bosh -n -d nweb delete-deployment

# We delete the previously uploaded 'nweb' release from the bosh environment.
bosh -n delete-release nweb-release

# Now we create the 'nweb' release. The '--force' flag skips the 'dirty git'
# check which allows us to make local changes to the release and experiment.
bosh -n create-release --force

# Upload the generated release in the bosh environment.
bosh -n upload-release

# Use the 'manifest.yml' manifest file in order to deploy the 'nweb' release.
bosh -n -d nweb deploy manifest.yml

# We should be able to see the 'nWeb' instance as 'running'.
bosh vms

#############################################################################
#                                                                           #
# At this point you may want to connect to the 'nweb' instance like this:   #
#                                                                           #
#   bosh -d nweb ssh nweb                                                   #
#                                                                           #
# Then explore the following locations:                                     #
#                                                                           #
#   /var/vcap/sys/log/nweb/nweb.log - the main log file for the 'nweb' job. #
#   /var/vcap/jobs/nweb/bin/ctl     - the start/stop script.                #
#   /var/vcap/packages/nweb         - the actwal nWeb server location.      #
#                                                                           #
#############################################################################

# And finally we should be able to access the nWeb web server on IP address
# 10.10.0.10 on port 8080.
firefox 10.10.0.10:8080
curl 10.10.0.10:8080

set +ex

