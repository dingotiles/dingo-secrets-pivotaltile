#!/bin/bash

set -e # fail fast
set -x # show commands

next_tile_version=$(cat tile-version/number)

tile_path=$(pwd)/$(ls generated-tile/dingo-postgresql*.pivotal)
next_tile_path=$(pwd)/reversioned-product/dingo-postgresql-${next_tile_version}.pivotal

zip_tile_path=$(pwd)/generated-tile/dingo-postgresql.zip
mv ${tile_path} ${zip_tile_path}
unzip -u ${zip_tile_path} -d unpack
TILE_VERSION=$(cat unpack/metadata/dingo-postgresql.yml| yaml2json | jq -r .product_version)
echo "Previous version $TILE_VERSION; re-versioning to $next_tile_version"

echo Updating metadata/dingo-postgresql.yml
sed -i -e "s/^product_version:.*$/product_version: \"${next_tile_version}\"/" unpack/metadata/dingo-postgresql.yml
cat unpack/metadata/dingo-postgresql.yml

echo Looking up all previous versions to generate content_migrations/dingo-postgresql.yml
./tile/ci/tasks/generate_content_migration.rb ${next_tile_version} unpack/content_migrations/dingo-postgresql.yml
cat unpack/content_migrations/dingo-postgresql.yml

cd unpack
zip -r -f ${zip_tile_path} *

unzip -l ${zip_tile_path}

mv ${zip_tile_path} ${next_tile_path}

ls -al ${next_tile_path}
