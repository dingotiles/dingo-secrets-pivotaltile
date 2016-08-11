#!/bin/bash

stemcell_path=$(ls pivnet-stemcell/*vsphere*)
ls -al ${stemcell_path}

insecure=
if [[ "${opsmgr_insecure_verification}X" != "X" ]]; then
  insecure="-k "
fi

curl -f ${insecure} -u ${opsmgr_username}:${opsmgr_password} \
  "${opsmgr_url}/api/stemcells" -X POST -F "stemcell[file]=@${stemcell_path}"
