#!/bin/bash

set -ex

# Update the apt package index.
apt-get update

# Install required packages.
apt install --no-install-recommends --no-install-suggests --yes \
    postgresql-13 \
    redis-server

# Configure PostgreSQL.
pg_ctlcluster --skip-systemctl-redirect 13-main start
su --login postgres --command \
    "psql -c \"CREATE ROLE bender WITH LOGIN PASSWORD 'rocks';\""
su --login postgres --command \
    "psql -c \"CREATE DATABASE random OWNER bender;\""
pg_ctlcluster --skip-systemctl-redirect --mode fast 13-main stop

# Fetch required Perl modules.
curl --location --insecure --output /tmp/linux-random.zip \
    https://github.com/tschaefer/linux-random/archive/refs/heads/master.zip

# Install required Perl modules.
cpanm --notest --verbose Mojo::Redis
cpanm --notest --verbose /tmp/linux-random.zip
cpanm --notest --verbose /src

# Clean-up.
rm -rf /tmp/*
rm -rf /var/lib/apt/lists/*
