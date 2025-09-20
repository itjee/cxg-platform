#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE DATABASE manages;
    CREATE DATABASE tenants;
    GRANT ALL PRIVILEGES ON DATABASE manages TO $POSTGRES_USER;
    GRANT ALL PRIVILEGES ON DATABASE tenants TO $POSTGRES_USER;
EOSQL

echo "Databases 'manages' and 'tenants' created successfully"
