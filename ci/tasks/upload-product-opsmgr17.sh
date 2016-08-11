#!/bin/bash

opsmgr_url=${opsmgr_url:-https://10.213.1.1}
opsmgr_username=${opsmgr_username:-admin}
opsmgr_password=${opsmgr_password:-Cloudc0w}

if [[ "${opsmgr_url}X" == "X" ]]; then
  echo "upload-product.sh requires \$opsmgr_url, \$opsmgr_username, \$opsmgr_password"
  exit
fi

insecure=
skip_ssl=
if [[ "${opsmgr_skip_ssl_verification}X" != "X" ]]; then
  insecure="-k"
  skip_ssl="--skip-ssl-validation"
fi

uaac target ${opsmgr_url}/uaa ${skip_ssl}
uaac token owner get opsman ${opsmgr_username} -s '' -p ${opsmgr_password}

access_token=$(uaac context admin | grep access_token | awk '{print $2}')

curl ${insecure} -H "Authorization: Bearer ${access_token}" \
  "${opsmgr_url}/api/products" -X GET

curl -f ${insecure} -H "Authorization: Bearer ${access_token}" \
  "${opsmgr_url}/api/products" -X POST -F "product[file]=@${tile_path}"; echo

curl -sf ${insecure} -H "Authorization: Bearer ${access_token}" \
  "${opsmgr_url}/api/products"; echo

echo Getting $product_version from inside .pivotal zip file
zip_tile_path=generated-tile/dingo-secrets.zip
mv ${tile_path} ${zip_tile_path}
  unzip -u ${zip_tile_path} metadata/dingo-secrets.yml
  product_version=$(cat metadata/dingo-secrets.yml| yaml2json | jq -r .product_version)
  echo Installing product version $product_version
mv ${zip_tile_path} ${tile_path}

prev_version=$(curl -f ${insecure} -H "Authorization: Bearer ${access_token}" \
  "${opsmgr_url}/api/installation_settings" | jq -r ".products[] | select(.identifier == \"dingo-secrets\") | .product_version")

if [[ "${prev_version}X" == "X" ]]; then
  echo Adding product ${product_version} to the installation
  product_install_uuid=$(curl -f ${insecure} -H "Authorization: Bearer ${access_token}" \
    "${opsmgr_url}/api/installation_settings" | jq -r ".products[] | select(.identifier == \"dingo-secrets\") | .guid")
  curl -f ${insecure} -H "Authorization: Bearer ${access_token}" \
    ${opsmgr_url}/api/installation_settings/products -X POST \
      -d "name=dingo-secrets&product_version=${product_version}"
else
  echo Upgrading product from ${prev_version} to ${product_version}

  product_install_uuid=$(curl -f ${insecure} -H "Authorization: Bearer ${access_token}" \
    "${opsmgr_url}/api/installation_settings" | jq -r ".products[] | select(.identifier == \"dingo-secrets\") | .guid")
  curl -f ${insecure} -H "Authorization: Bearer ${access_token}" \
    ${opsmgr_url}/api/installation_settings/products/${product_install_uuid} -X PUT \
      -d "to_version=${product_version}"
fi
echo

echo "\nInstalling product\n"

echo "Running installation process"
response=$(curl -sf ${insecure} -H "Authorization: Bearer ${access_token}" \
  "${opsmgr_url}/api/installation?ignore_warnings=1" -d '' -X POST)
installation_id=$(echo $response | jq -r .install.id)

set +x # silence print commands
status=running
prevlogslength=0
until [[ "${status}" != "running" ]]; do
  sleep 1
  status_json=$(curl -sf ${insecure} -H "Authorization: Bearer ${access_token}" \
    "${opsmgr_url}/api/installation/${installation_id}")
  status=$(echo $status_json | jq -r .status)
  if [[ "${status}X" == "X" || "${status}" == "failed" ]]; then
    installation_exit=1
  fi

  logs=$(curl -sf ${insecure} -H "Authorization: Bearer ${access_token}" \
    ${opsmgr_url}/api/installation/${installation_id}/logs | jq -r .logs)
  if [[ "${logs:${prevlogslength}}" != "" ]]; then
    echo "${logs:${prevlogslength}}"
    prevlogslength=${#logs}
  fi
done
echo $status_json

if [[ "${installation_exit}X" != "X" ]]; then
  exit ${installation_exit}
fi
