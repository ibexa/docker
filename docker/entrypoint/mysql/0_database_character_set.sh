#!/usr/bin/env bash
echo "Altering database, setting character set to utf8mb4"
echo "ALTER DATABASE ${MYSQL_DATABASE} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" | "${mysql[@]}"
if [ "${MYSQL_USER}" != "" ]; then
    echo "Granting privileges on channel databases"
    echo "GRANT ALL PRIVILEGES ON *.* TO '${MYSQL_USER}'@'%' WITH GRANT OPTION; GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}_%\`.* TO '${MYSQL_USER}'@'%'; FLUSH PRIVILEGES;" | "${mysql[@]}" 2>/dev/null || true
fi
