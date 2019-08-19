#! /bin/bash

PLAYBOOK=$1
packer build -var playbook="$1" packer.json
