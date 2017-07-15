#!/bin/bash

set -e

ssh -oStrictHostKeyChecking=no jumpbox@192.168.50.6 -i jumpbox.key

