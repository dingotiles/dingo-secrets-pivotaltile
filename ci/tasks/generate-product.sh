#!/bin/bash

set -e # fail fast
set -x # print commands

mkdir -p tile/tmp/metadata
mkdir -p workspace/metadata
mkdir -p workspace/releases
mkdir -p workspace/content_migrations

TILE_VERSION=$(cat tile-version/number)

cat >tile/tmp/metadata/version.yml <<EOF
---
product_version: "${TILE_VERSION}"
EOF

cat >tile/tmp/metadata/releases.yml <<YAML
---
releases:
YAML

# versions available via inputs
boshreleases=("vault-boshrelease" "broker-registrar")
for boshrelease in "${boshreleases[@]}"
do
  release_version=$(cat ${boshrelease}/version)
  cat >>tile/tmp/metadata/releases.yml <<YAML
  - name: ${boshrelease}
    file: ${boshrelease}-${release_version}.tgz
    version: "${release_version}"
YAML
  if [[ -f ${boshrelease}/release.tgz ]]; then
    cp ${boshrelease}/release.tgz workspace/releases/${boshrelease}-${release_version}.tgz
  fi
  if [[ -f ${boshrelease}/${boshrelease}-${release_version}.tgz ]]; then
    cp ${boshrelease}/${boshrelease}-${release_version}.tgz workspace/releases/
  fi
done

spruce merge --prune meta \
  tile/templates/metadata/base.yml \
  tile/templates/metadata/stemcell_criteria.yml \
  tile/tmp/metadata/version.yml \
  tile/tmp/metadata/releases.yml \
  tile/templates/metadata/form_types.yml \
  tile/templates/metadata/property_blueprints.yml \
  tile/templates/metadata/job_compilation.yml \
  tile/templates/metadata/job_vault.yml \
  tile/templates/metadata/job_broker_registrar.yml \
    > workspace/metadata/dingo-secrets.yml

sed -i "s/RELEASE_VERSION_MARKER/${TILE_VERSION}/" workspace/metadata/dingo-secrets.yml
image_tag=$(cat dingo-secrets/version)

cat workspace/metadata/dingo-secrets.yml

echo Looking up all previous versions to generate content_migrations/dingo-secrets.yml
./tile/ci/tasks/generate_content_migration.rb ${TILE_VERSION} workspace/content_migrations/dingo-secrets.yml

cat workspace/content_migrations/dingo-secrets.yml

cd workspace
ls -laR .

echo "creating dingo-secrets-${TILE_VERSION}.pivotal file"
zip -r dingo-secrets-${TILE_VERSION}.pivotal content_migrations metadata releases

mv dingo-secrets-${TILE_VERSION}.pivotal ../product
ls ../product
