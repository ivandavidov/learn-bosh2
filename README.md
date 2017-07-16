# Learn BOSH v2 (CLI, relase & deployment)

This project demosntstrates the following:

* How to use [BOSH CLI v2](https://bosh.io/docs/cli-v2.html) in order to setup [bosh-lite VM](https://github.com/cloudfoundry/bosh-deployment/blob/master/docs/bosh-lite-on-vbox.md) based on [bosh-deployment](https://github.com/cloudfoundry/bosh-deployment) manifest files.
* How to create, upload and deploy the [nWeb release](https://github.com/ivandavidov/nweb-release). This release has very simple structure and you can easily reverse engineer the connections between its components.

## Prerequisites

* Linux OS - all scripts are designed to run on Linux. The scripts have been tested on [Linux Minut](http://linuxmint.com) but they should work fine on pretty much all major Linux distributions.
* Sudo - in order to create routing rule between your network and the nWeb release network via the BOSH director.
* [VirtualBox](https://virtualbox.org) - you need at least version 5.0.
* [BOSH CLI v2](https://bosh.io/docs/cli-v2.html#install) - the CLI should be accessible via ``bosh``.
* Git - for obvious reasons.

## Tutorial

Long story short - run the [all.sh](https://github.com/ivandavidov/learn-bosh2/blob/master/all.sh) script, sit down and observe the output. Also, take a look at the script and read the comments. They are quite descriptive. You won't learn anything if you just run the script - you actually need to go through the script, examine the commands and experiment.

At some point you may want to save your work. The bosh-lite VM runs in headless mode and by default you don't get UI. You can manually run ``virtualbox`` and then choose Machine => Close => Save State. Then you can run the VM by choosing Machine => Start => Headless Start.

## Other resources

Perhaps you'd like to take a look at Maria Shaldibina's [BOSH guide](http://mariash.github.io/learn-bosh/). Her tutorial is focused around [learn-bosh-release](https://github.com/mariash/learn-bosh-release).
