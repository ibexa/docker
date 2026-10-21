#!/usr/bin/env bash
echo "Altering database, setting character set to utf8mb4"
cmd=$(command -v mariadb || command -v mysql)
$cmd -uroot -p"${MYSQL_ROOT_PASSWORD:-pleasechangethis}" -e "ALTER DATABASE ${MYSQL_DATABASE} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>/dev/null || true
if [ "${MYSQL_USER}" != "" ]; then
    echo "Granting privileges on channel databases"
    $cmd -uroot -p"${MYSQL_ROOT_PASSWORD:-pleasechangethis}" -e "GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}_%\`.* TO '${MYSQL_USER}'@'%'; FLUSH PRIVILEGES;" 2>/dev/null || true
fi
