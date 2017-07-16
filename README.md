# learn-bosh2

## About

This project demosntstrates the following:

* How to use [BOSH CLI v2](https://bosh.io/docs/cli-v2.html) in order to setup [bosh-lite VM](https://github.com/cloudfoundry/bosh-deployment/blob/master/docs/bosh-lite-on-vbox.md) based on [bosh-deployment](https://github.com/cloudfoundry/bosh-deployment) manifest files.
* How to create, upload and deploy the [nWeb release](https://github.com/ivandavidov/nweb-release). This release has very simple structure and you can easily reverse engineer the connections between its components.

## Prerequisites

* Linux OS - all scripts are designed to run on Linux. The scripts have been tested on [Linux Minut](http://linuxmint.com) but they should work fine on pretty much all major Linux distributions.
* [VirtualBox](https://virtualbox.org) - you need at least version 5.0.
* [BOSH CLI v2](https://bosh.io/docs/cli-v2.html#install) - the CLI should be accessible via ``bosh``.
* Git - for obvious reasons.

## Tutorial

Long story short - run the ``all.sh`` script and follow the instructions. Also, take a look at the script and read the comments. They are quite descriptive.

* TODO - add more explanations...
