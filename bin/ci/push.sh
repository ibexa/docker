#!/usr/bin/env sh

set -e

# Expects images from build.sh, as in:
# - ibexa_php:latest
# - ibexa_php:latest-node

if [ "$1" = "" ]; then
    echo "Argument 1 variable REMOTE_IMAGE is not set, format: ezsystems/php. Bailing out !"
    exit 1
fi

REMOTE_IMAGE="$1"

PHP_VERSION=$(docker -l error run ibexa_php:latest php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;")
NODE_VERSION=$(docker -l error run ibexa_php:latest-node node -e "console.log(process.versions.node)" | cut -f 1 -d ".")

docker images

## TAGS
echo "About to tag remote image '${REMOTE_IMAGE}' with php version '${PHP_VERSION}' and Node '${NODE_VERSION}'"

# "7.0"
docker tag ibexa_php:latest "${REMOTE_IMAGE}:${PHP_VERSION}"
docker tag ibexa_php:latest-node "${REMOTE_IMAGE}:${PHP_VERSION}-node${NODE_VERSION}"

echo "Pushing docker image with all tags : ${REMOTE_IMAGE}"
docker push --all-tags "${REMOTE_IMAGE}"
