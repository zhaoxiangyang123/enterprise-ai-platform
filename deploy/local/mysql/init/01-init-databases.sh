#!/usr/bin/env bash
set -euo pipefail

echo "[mysql-init] Creating application databases and user..."

mysql --protocol=socket -uroot -p"${MYSQL_ROOT_PASSWORD}" <<EOSQL
CREATE DATABASE IF NOT EXISTS eap_user
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_unicode_ci;

CREATE DATABASE IF NOT EXISTS eap_ai
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_unicode_ci;

CREATE USER IF NOT EXISTS '${MYSQL_APP_USER}'@'%'
  IDENTIFIED BY '${MYSQL_APP_PASSWORD}';

ALTER USER '${MYSQL_APP_USER}'@'%'
  IDENTIFIED BY '${MYSQL_APP_PASSWORD}';

GRANT ALL PRIVILEGES ON eap_user.* TO '${MYSQL_APP_USER}'@'%';
GRANT ALL PRIVILEGES ON eap_ai.* TO '${MYSQL_APP_USER}'@'%';
FLUSH PRIVILEGES;
EOSQL

echo "[mysql-init] Databases eap_user and eap_ai are ready."
