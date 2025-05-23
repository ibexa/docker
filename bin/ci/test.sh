#!/usr/bin/env sh

set -e
# Expects images from build.sh, as in:
# - ibexa_php:latest
# - ibexa_php:latest-node
REUSE_VOLUME=0

## Parse arguments
for i in "$@"; do
case $i in
    --reuse-volume)
        REUSE_VOLUME=1
        ;;
    *)
        printf "Not recognised argument: ${i}, only supported argument is: --reuse-volume"
        exit 1
        ;;
esac
done

APP_ENV="prod"

BEHAT_REQUIREMENT="ibexa/behat:$PRODUCT_VERSION"
if [ "$PRODUCT_VERSION" = "~3.3.x-dev" ]; then
    BEHAT_REQUIREMENT="ezsystems/behatbundle:^8.3.x-dev"
fi

if [ "$REUSE_VOLUME" = "0" ]; then
    printf "\n(Re-)Creating volumes/ezplatform for fresh checkout, needs sudo to delete old and chmod new folder\n"
    rm -Rf volumes/ezplatform
    # Use mode here so this can be run on Mac
    mkdir -pm 0777 volumes/ezplatform

    if [ "$COMPOSER_HOME" = "" ]; then
        COMPOSER_HOME=~/.composer
    fi

    printf "\nBuilding on ibexa_php:latest, composer will implicit check requirements\n"
    docker run -i --rm \
        -e APP_ENV \
        -e PHP_INI_ENV_memory_limit=3G \
        -v $(pwd)/volumes/ezplatform:/var/www \
        -v  $COMPOSER_HOME:/root/.composer \
        ibexa_php:latest-node \
        bash -c "
        composer --version &&
        composer create-project --no-progress --no-interaction $COMPOSER_OPTIONS ibexa/website-skeleton /var/www $PRODUCT_VERSION &&
        composer require ibexa/oss:$PRODUCT_VERSION -W  --no-scripts $COMPOSER_OPTIONS
        git init && git add . && git commit -m 'Init'
        composer recipes:install ibexa/oss --force --reset -v
        composer require ibexa/docker:$PRODUCT_VERSION --no-scripts $COMPOSER_OPTIONS &&
        composer require $BEHAT_REQUIREMENT -W --no-scripts $COMPOSER_OPTIONS &&
        sudo sed -i \"s/\['test' => true\]/\['test' => true, 'behat' => true\]/g\" config/bundles.php"
fi

printf "\nMake sure Node.js and Yarn are included in latest-node\n"
docker -l error run -a stderr ibexa_php:latest-node node -e "process.versions.node"
docker -l error run -a stderr ibexa_php:latest-node bash -c "yarn -v"

printf "\nVersion and module information about php build\n"
docker run -i --rm ibexa_php:latest-node bash -c "php -v; php -m"

printf "\nVersion and module information about php build with enabled xdebug\n"
docker run -i --rm -e ENABLE_XDEBUG="1" ibexa_php:latest-node bash -c "php -v; php -m"

printf "\nIntegration: Behat testing on ibexa_php:latest and ibexa_php:latest-node with eZ Platform\n"
cd volumes/ezplatform

export COMPOSE_FILE="doc/docker/base-dev.yml:doc/docker/redis.yml:doc/docker/selenium.yml" 
export APP_ENV="behat" APP_DEBUG="1"
export PHP_IMAGE="ibexa_php:latest-node" PHP_IMAGE_DEV="ibexa_php:latest-node"

docker compose --env-file .env up -d --build --force-recreate
echo '> Workaround for test issues: Change ownership of files inside docker container'
docker compose --env-file=.env exec -T app sh -c 'chown -R www-data:www-data /var/www'
if docker run -i --rm ibexa_php:latest-node bash -c "php -v" | grep -q '8.3'; then
    echo '> Set PHP 8.2+ Ibexa error handler to avoid deprecations'
    docker compose --env-file=.env exec -T --user www-data app sh -c "composer config extra.runtime.error_handler \"\\Ibexa\\Contracts\\Core\\MVC\\Symfony\\ErrorHandler\\Php82HideDeprecationsErrorHandler\""
    docker compose --env-file=.env exec -T --user www-data app sh -c "composer dump-autoload"
fi
# Rebuild Symfony container
docker compose --env-file=.env exec -T --user www-data app sh -c "rm -rf var/cache/*"
docker compose --env-file=.env exec -T --user www-data app php bin/console cache:clear
# Install database & generate schema
docker compose --env-file=.env exec -T --user www-data app sh -c "php /scripts/wait_for_db.php; php bin/console ibexa:install --no-interaction"
docker compose --env-file=.env exec -T --user www-data app sh -c "php bin/console ibexa:graphql:generate-schema"
docker compose --env-file=.env exec -T --user www-data app sh -c "composer run post-install-cmd"

docker compose --env-file=.env exec -T --user www-data app sh -c "php /scripts/wait_for_db.php; php bin/console cache:warmup; $TEST_CMD"

docker compose --env-file .env down -v
