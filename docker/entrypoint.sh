#!/bin/bash
set -euo pipefail

MISP_PATH=/var/www/MISP
APACHE_USER=www-data
CAKE="${MISP_PATH}/app/Console/cake"
PHP_INI=/etc/php/8.3/apache2/php.ini

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

# ---------------------------------------------------------------------------
# Wait for MariaDB
# ---------------------------------------------------------------------------
log "Waiting for database at ${DBHOST}:${DBPORT:-3306}..."
until mysql -h "${DBHOST}" -P "${DBPORT:-3306}" \
        -u "${DBUSER_MISP}" -p"${DBPASSWORD_MISP}" \
        -e "SELECT 1" "${DBNAME}" &>/dev/null; do
    sleep 2
done
log "Database is ready."

# ---------------------------------------------------------------------------
# Git submodules (CakePHP core lives in app/Lib/cakephp/)
# ---------------------------------------------------------------------------
# The source is mounted from the host whose UID differs from root inside the
# container — tell git to trust it before running any git commands.
git config --global --add safe.directory "${MISP_PATH}" 2>/dev/null || true

CAKEPHP_CORE="${MISP_PATH}/app/Lib/cakephp/lib/Cake/Console/ShellDispatcher.php"
if [ ! -f "${CAKEPHP_CORE}" ]; then
    log "CakePHP submodule missing — running git submodule update --init --recursive..."
    git -C "${MISP_PATH}" submodule update --init --recursive
    log "Submodules initialised."
fi

# ---------------------------------------------------------------------------
# Point PHP sessions at Redis
# ---------------------------------------------------------------------------
sed -i "s|^session.save_handler.*|session.save_handler = redis|" "$PHP_INI"
if grep -q "^session.save_path" "$PHP_INI"; then
    sed -i "s|^session.save_path.*|session.save_path = 'tcp://${REDIS_HOST:-redis}:6379'|" "$PHP_INI"
else
    sed -i "/^session.save_handler/a session.save_path = 'tcp:\/\/${REDIS_HOST:-redis}:6379'" "$PHP_INI"
fi

# ---------------------------------------------------------------------------
# MISP config files (only created on first run)
# ---------------------------------------------------------------------------
CONFIG_DIR="${MISP_PATH}/app/Config"

if [ ! -f "${CONFIG_DIR}/database.php" ]; then
    log "Creating database.php..."
    cp "${CONFIG_DIR}/database.default.php" "${CONFIG_DIR}/database.php"
    sed -i "s|'host' => 'localhost'|'host' => '${DBHOST}'|"  "${CONFIG_DIR}/database.php"
    sed -i "s|'port' => 3306|'port' => ${DBPORT:-3306}|"     "${CONFIG_DIR}/database.php"
    sed -i "s|db login|${DBUSER_MISP}|"                       "${CONFIG_DIR}/database.php"
    sed -i "s|db password|${DBPASSWORD_MISP}|"                "${CONFIG_DIR}/database.php"
    sed -i "s|'database' => 'misp'|'database' => '${DBNAME}'|" "${CONFIG_DIR}/database.php"
fi

[ ! -f "${CONFIG_DIR}/bootstrap.php" ] && cp "${CONFIG_DIR}/bootstrap.default.php" "${CONFIG_DIR}/bootstrap.php"
[ ! -f "${CONFIG_DIR}/core.php" ]      && cp "${CONFIG_DIR}/core.default.php"      "${CONFIG_DIR}/core.php"

if [ ! -f "${CONFIG_DIR}/config.php" ]; then
    log "Creating config.php..."
    cp "${CONFIG_DIR}/config.default.php" "${CONFIG_DIR}/config.php"
    SALT=$(tr -dc 'a-zA-Z0-9' </dev/urandom | fold -w 32 | head -n 1)
    sed -i "s|Rooraenietu8Eeyo<Qu2eeNfterd-dd+|${SALT}|" "${CONFIG_DIR}/config.php"
fi

# Ensure Apache can write to runtime directories
mkdir -p "${MISP_PATH}/app/tmp/logs" \
         "${MISP_PATH}/app/tmp/cache/models" \
         "${MISP_PATH}/app/tmp/cache/persistent" \
         "${MISP_PATH}/app/tmp/cache/views" \
         "${MISP_PATH}/app/tmp/sessions"
chown -R "${APACHE_USER}:${APACHE_USER}" "${CONFIG_DIR}" \
    "${MISP_PATH}/app/tmp" 2>/dev/null || true

# Named volumes start root-owned; hand them to www-data so composer/pip can write.
chown "${APACHE_USER}:${APACHE_USER}" \
    "${MISP_PATH}/app/Vendor" \
    "${MISP_PATH}/venv" 2>/dev/null || true

# The source volume is owned by the host user (different UID on Linux/Mac).
# Tell git to trust the directory for the www-data user so composer doesn't fail.
sudo -u "${APACHE_USER}" git config --global \
    --add safe.directory "${MISP_PATH}" 2>/dev/null || true

# ---------------------------------------------------------------------------
# Composer dependencies (persisted in the vendor named volume)
# ---------------------------------------------------------------------------
if [ ! -f "${MISP_PATH}/app/Vendor/autoload.php" ]; then
    log "Installing Composer dependencies (this takes a minute on first run)..."
    sudo -u "${APACHE_USER}" composer install \
        --no-dev --no-interaction --prefer-dist \
        --working-dir="${MISP_PATH}/app"
fi

# ---------------------------------------------------------------------------
# Python virtualenv (persisted in the venv named volume)
# ---------------------------------------------------------------------------
if [ ! -d "${MISP_PATH}/venv/bin" ]; then
    log "Creating Python virtualenv..."
    python3 -m virtualenv "${MISP_PATH}/venv"
    "${MISP_PATH}/venv/bin/pip" install --quiet \
        -r "${MISP_PATH}/requirements.txt"
    chown -R "${APACHE_USER}:${APACHE_USER}" "${MISP_PATH}/venv" 2>/dev/null || true
fi

# ---------------------------------------------------------------------------
# Supervisor config for MISP background workers
# ---------------------------------------------------------------------------
SUPERVISOR_USER="${SUPERVISOR_USER:-supervisor}"
SUPERVISOR_PASSWORD="${SUPERVISOR_PASSWORD:-supervisor}"

cat > /etc/supervisor/conf.d/misp-workers.conf << SUPEOF
[inet_http_server]
port=127.0.0.1:9001
username=${SUPERVISOR_USER}
password=${SUPERVISOR_PASSWORD}

[supervisorctl]
serverurl=http://127.0.0.1:9001
username=${SUPERVISOR_USER}
password=${SUPERVISOR_PASSWORD}

[rpcinterface:supervisor]
supervisor.rpcinterface_factory=supervisor.rpcinterface:make_main_rpcinterface

[group:misp-workers]
programs=default,email,cache,prio,update,scheduler

[program:default]
directory=${MISP_PATH}
command=${MISP_PATH}/app/Console/cake start_worker default
process_name=%(program_name)s_%(process_num)02d
numprocs=5
autostart=true
autorestart=true
redirect_stderr=false
stderr_logfile=${MISP_PATH}/app/tmp/logs/misp-workers-errors.log
stdout_logfile=${MISP_PATH}/app/tmp/logs/misp-workers.log
user=${APACHE_USER}

[program:prio]
directory=${MISP_PATH}
command=${MISP_PATH}/app/Console/cake start_worker prio
process_name=%(program_name)s_%(process_num)02d
numprocs=5
autostart=true
autorestart=true
redirect_stderr=false
stderr_logfile=${MISP_PATH}/app/tmp/logs/misp-workers-errors.log
stdout_logfile=${MISP_PATH}/app/tmp/logs/misp-workers.log
user=${APACHE_USER}

[program:email]
directory=${MISP_PATH}
command=${MISP_PATH}/app/Console/cake start_worker email
process_name=%(program_name)s_%(process_num)02d
numprocs=5
autostart=true
autorestart=true
redirect_stderr=false
stderr_logfile=${MISP_PATH}/app/tmp/logs/misp-workers-errors.log
stdout_logfile=${MISP_PATH}/app/tmp/logs/misp-workers.log
user=${APACHE_USER}

[program:update]
directory=${MISP_PATH}
command=${MISP_PATH}/app/Console/cake start_worker update
process_name=%(program_name)s_%(process_num)02d
numprocs=1
autostart=true
autorestart=true
redirect_stderr=false
stderr_logfile=${MISP_PATH}/app/tmp/logs/misp-workers-errors.log
stdout_logfile=${MISP_PATH}/app/tmp/logs/misp-workers.log
user=${APACHE_USER}

[program:cache]
directory=${MISP_PATH}
command=${MISP_PATH}/app/Console/cake start_worker cache
process_name=%(program_name)s_%(process_num)02d
numprocs=5
autostart=true
autorestart=true
redirect_stderr=false
stderr_logfile=${MISP_PATH}/app/tmp/logs/misp-workers-errors.log
stdout_logfile=${MISP_PATH}/app/tmp/logs/misp-workers.log
user=${APACHE_USER}

[program:scheduler]
directory=${MISP_PATH}
command=${MISP_PATH}/app/Console/cake scheduler_worker
process_name=%(program_name)s_%(process_num)02d
numprocs=1
autostart=true
autorestart=true
redirect_stderr=false
stderr_logfile=${MISP_PATH}/app/tmp/logs/misp-workers-errors.log
stdout_logfile=${MISP_PATH}/app/tmp/logs/misp-workers.log
user=${APACHE_USER}
SUPEOF

# ---------------------------------------------------------------------------
# Database schema import (skipped if tables already exist)
# ---------------------------------------------------------------------------
TABLE_COUNT=$(mysql -h "${DBHOST}" -P "${DBPORT:-3306}" \
    -u "${DBUSER_MISP}" -p"${DBPASSWORD_MISP}" \
    -Nse "SELECT COUNT(*) FROM information_schema.tables \
          WHERE table_schema = '${DBNAME}';")

IS_FRESH_DB=false
if [ "${TABLE_COUNT}" -eq 0 ]; then
    log "Importing MISP database schema..."
    mysql -h "${DBHOST}" -P "${DBPORT:-3306}" \
        -u "${DBUSER_MISP}" -p"${DBPASSWORD_MISP}" \
        "${DBNAME}" < "${MISP_PATH}/INSTALL/MYSQL.sql"
    IS_FRESH_DB=true
fi

# ---------------------------------------------------------------------------
# MISP settings — tracked by a marker file so a partial first-boot always
# retries on the next restart (independent of whether schema was imported).
# ---------------------------------------------------------------------------
MISP_CONFIGURED_MARKER="${MISP_PATH}/app/tmp/.misp_docker_configured"
_cake() { sudo -u "${APACHE_USER}" "$CAKE" "$@"; }

if [ ! -f "${MISP_CONFIGURED_MARKER}" ]; then
    log "Applying MISP configuration settings..."
    BASEURL="${MISP_BASEURL:-http://localhost}"

    _cake Admin setSetting "MISP.osuser"              "${APACHE_USER}"
    _cake Admin setSetting "MISP.baseurl"             "${BASEURL}"
    _cake Admin setSetting "MISP.external_baseurl"    "${BASEURL}"
    _cake Admin setSetting "MISP.python_bin"          "${MISP_PATH}/venv/bin/python"
    _cake Admin setSetting "MISP.email"               "admin@admin.test"
    _cake Admin setSetting "MISP.disable_emailing"    true
    _cake Admin setSetting "MISP.disablerestalert"    true
    _cake Admin setSetting "MISP.log_new_audit"       1
    _cake Admin setSetting "MISP.tmpdir"              "${MISP_PATH}/app/tmp"
    _cake Admin setSetting "Session.autoRegenerate"   0
    _cake Admin setSetting "Session.timeout"          600
    _cake Admin setSetting "Session.cookieTimeout"    3600

    _cake Admin setSetting "SimpleBackgroundJobs.enabled"             1
    _cake Admin setSetting "SimpleBackgroundJobs.redis_host"          "${REDIS_HOST:-redis}"
    _cake Admin setSetting "SimpleBackgroundJobs.redis_port"          6379
    _cake Admin setSetting "SimpleBackgroundJobs.redis_database"      13
    _cake Admin setSetting "SimpleBackgroundJobs.redis_password"      ""
    _cake Admin setSetting "SimpleBackgroundJobs.redis_namespace"     "background_jobs"
    _cake Admin setSetting "SimpleBackgroundJobs.redis_serializer"    "JSON"
    _cake Admin setSetting "SimpleBackgroundJobs.supervisor_host"     "localhost"
    _cake Admin setSetting "SimpleBackgroundJobs.supervisor_port"     9001
    _cake Admin setSetting "SimpleBackgroundJobs.supervisor_user"     "${SUPERVISOR_USER}"
    _cake Admin setSetting "SimpleBackgroundJobs.supervisor_password" "${SUPERVISOR_PASSWORD}"

    _cake Admin runUpdates

    # Admin user is only created once against a fresh database
    if [ "${IS_FRESH_DB}" = true ]; then
        MISP_USER_KEY=$(sudo -u "${APACHE_USER}" "$CAKE" User init)
        log "=========================================="
        log "MISP admin API key: ${MISP_USER_KEY}"
        log "=========================================="

        ADMIN_PASSWORD="${MISP_ADMIN_PASSWORD:-admin}"
        sudo -u "${APACHE_USER}" "$CAKE" User change_pw \
            'admin@admin.test' "${ADMIN_PASSWORD}"
        log "Admin login: admin@admin.test / ${ADMIN_PASSWORD}"
    fi

    touch "${MISP_CONFIGURED_MARKER}"
    log "MISP configuration complete."
fi

# ---------------------------------------------------------------------------
# Start supervisor (background workers) then Apache (foreground)
# ---------------------------------------------------------------------------
log "Starting supervisor..."
supervisord -c /etc/supervisor/supervisord.conf

log "Starting Apache on port 80..."
exec apache2ctl -D FOREGROUND
