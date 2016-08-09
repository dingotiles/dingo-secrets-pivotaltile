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
boshreleases=("dingo-postgresql" "broker-registrar")
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

ls -lRt dingo-postgresql/*

# versions available via dingo-postgresql github release files
boshreleases=("etcd" "simple-remote-syslog")
for boshrelease in "${boshreleases[@]}"
do
  regexp="${boshrelease}-(.*)\.tgz"
  file=$(ls dingo-postgresql/${boshrelease}*)
  if [[ $file =~ $regexp ]]; then
    release_version="${BASH_REMATCH[1]}"
  else
    echo "$file did not contain version"
    exit 1
  fi
  cp $file workspace/releases/${boshrelease}-${release_version}.tgz
  cat >>tile/tmp/metadata/releases.yml <<YAML
  - name: ${boshrelease}
    file: ${boshrelease}-${release_version}.tgz
    version: "${release_version}"
YAML
done

spruce merge --prune meta \
  tile/templates/metadata/base.yml \
  tile/templates/metadata/stemcell_criteria.yml \
  tile/tmp/metadata/version.yml \
  tile/tmp/metadata/releases.yml \
  tile/templates/metadata/form_types.yml \
  tile/templates/metadata/property_blueprints.yml \
  tile/templates/metadata/job_compilation.yml \
  tile/templates/metadata/job_etcd.yml \
  tile/templates/metadata/job_cell_z1.yml \
  tile/templates/metadata/job_cell_z2.yml \
  tile/templates/metadata/job_router.yml \
  tile/templates/metadata/job_tests.yml \
  tile/templates/metadata/job_broker_registrar.yml \
  tile/templates/metadata/job_disaster_recovery.yml \
    > workspace/metadata/dingo-postgresql.yml

sed -i "s/RELEASE_VERSION_MARKER/${TILE_VERSION}/" workspace/metadata/dingo-postgresql.yml
image_tag=$(cat dingo-postgresql/version)
sed -i "s/IMAGE_TAG_MARKER/${image_tag}/" workspace/metadata/dingo-postgresql.yml

cat workspace/metadata/dingo-postgresql.yml

echo Looking up all previous versions to generate content_migrations/dingo-postgresql.yml
./tile/ci/tasks/generate_content_migration.rb ${TILE_VERSION} workspace/content_migrations/dingo-postgresql.yml

cat workspace/content_migrations/dingo-postgresql.yml

cd workspace
ls -laR .

echo "creating dingo-postgresql-${TILE_VERSION}.pivotal file"
zip -r dingo-postgresql-${TILE_VERSION}.pivotal content_migrations metadata releases

mv dingo-postgresql-${TILE_VERSION}.pivotal ../product
ls ../product
