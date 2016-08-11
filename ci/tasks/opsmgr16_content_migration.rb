#!/usr/bin/env ruby

require "fog"
require "yaml"

tile_version = ARGV[0]
filepath = ARGV[1]
unless tile_version && filepath
  puts "USAGE: ./ci/tasks/generate_content_migration.rb 1.2.3 /path/to/content_migrations.yml"
  exit 1
end

s3 = Fog::Storage.new(provider: 'AWS',
  aws_access_key_id: ENV['AWS_ACCESS_KEY'],
  aws_secret_access_key: ENV['AWS_SECRET_KEY'],
  region: 'ap-southeast-1')
bucket = s3.directories.get('dingo-secrets-pivotaltile')
tiles = bucket.files.all('prefix' => 'dingo-secrets-')
versions = tiles.inject([]) do |vs, tile|
  if tile.key =~ /^dingo-secrets-(.*)\.pivotal$/
    vs << $1
  end
  vs
end

content_migrations = <<EOS
---
product: dingo-secrets
installation_schema_version: "1.6"
to_version: "#{tile_version}"
migrations:
EOS

versions.each do |version|
  content_migrations << "- {from_version: \"#{version}\", rules: [{type: update, selector: product_version, to: \"#{tile_version}\"}]}\n"
end

File.open(filepath, "w") do |f|
  f << content_migrations
end
