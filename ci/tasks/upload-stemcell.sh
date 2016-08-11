#!/bin/bash

set -x # print commands
set -e # fail fast

if [[ "${opsmgr_version}" == "1.6" ]]; then
  ./tile/ci/tasks/upload-stemcell-opsmgr16.sh
elif [[ "${opsmgr_version}" == "1.7" ]]; then
  ./tile/ci/tasks/upload-stemcell-opsmgr17.sh
else
  echo "\$opsmgr_version must be 1.6 or 1.7"
  exit 1
fi
