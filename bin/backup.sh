#!/usr/bin/env bash

set -o pipefail  # trace ERR through pipes
set -o errtrace  # trace ERR through 'time command' and other functions
set -o nounset   ## set -u : exit the script if you try to use an uninitialised variable
set -o errexit   ## set -e : exit the script if any statement returns a non-true return value

source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/.config.sh"

if [ "$#" -lt 1 ]; then
    echo "No type defined"
    exit 1
fi

mkdir -p -- "${BACKUP_DIR}"

case "$1" in
    ###################################
    ## MySQL
    ###################################
    "mysql")
        if [[ -n "$(extDockerContainerId mysql)" ]]; then
            if [ -f "${BACKUP_DIR}/${BACKUP_MYSQL_FILE}" ]; then
                logMsg "Removing old backup file..."
                rm -f -- "${BACKUP_DIR}/${BACKUP_MYSQL_FILE}"
            fi

            logMsg "Starting MySQL backup..."
            #dockerExec mysqldump --opt --single-transaction --events --all-databases --routines --comments | bzip2 > "${BACKUP_DIR}/${BACKUP_MYSQL_FILE}"
            source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../etc/environment.yml"
            #dockerExec mysqldump -h mysql -u root -p${MYSQL_ROOT_PASSWORD} --opt --single-transaction --events --all-databases --routines --comments | bzip2 > "${BACKUP_DIR}/${BACKUP_MYSQL_FILE}"
            dockerExec mysqldump --opt --single-transaction --skip-events --all-databases --routines --comments -P 3307 -h mysql -u vti -pvti | bzip2 > "${BACKUP_DIR}/${BACKUP_MYSQL_FILE}"
            logMsg "Finished"
        else
            echo " * Skipping mysql backup, no such container"
        fi
        ;;

    ###################################
    ## Solr
    ###################################
    "solr")
        if [[ -n "$(dockerContainerId solr)" ]]; then
            logMsg "Starting Solr backup..."
            docker-compose stop solr

            if [ -f "${BACKUP_DIR}/${BACKUP_SOLR_FILE}" ]; then
                logMsg "Removing old backup file..."
                rm -f -- "${BACKUP_DIR}/${BACKUP_SOLR_FILE}"
            fi
            dockerExec tar -cP --to-stdout /storage/solr/ | bzip2 > "${BACKUP_DIR}/${BACKUP_SOLR_FILE}"

            docker-compose start solr
            logMsg "Finished"
        else
            echo " * Skipping solr backup, no such container"
        fi
        ;;

    ###################################
    ## MariaDB
    ###################################
    "mariadb")
        logMsg "Docker Container Id : $(extDockerContainerId mariadb)"
        logMsg "Vars : $1"

        if [[ -n "$(extDockerContainerId mariadb)" ]]; then
            if [ "$#" -eq 2 ]; then
              logMsg "Database defined"
              logMsg "Database : $2"
              SET_BACKUP_DIR="${BACKUP_DIR}/$2-${BACKUP_MARIADB_FILE}"
              logMsg "Backup Directory : ${SET_BACKUP_DIR}"
            else
              SET_BACKUP_DIR="${BACKUP_DIR}/${BACKUP_MARIADB_FILE}"
            fi

            if [ -f "${SET_BACKUP_DIR}" ]; then
                logMsg "Removing old backup file..."
                rm -f -- "${SET_BACKUP_DIR}"
            fi

            logMsg "Starting mariadb backup..."

            if [ "$#" -eq 2 ]; then
                dockerExec mysqldump --opt --single-transaction --skip-events --databases $2 --routines --comments -P 3306 -h mariadb -u vti -pvti | bzip2 > "${BACKUP_DIR}/$2-${BACKUP_MARIADB_FILE}"
            else
                logMsg "Backup Directory : ${BACKUP_DIR}/${BACKUP_MARIADB_FILE}"
                dockerExec mysqldump --opt --single-transaction --skip-events --all-databases --routines --comments -P 3306 -h mariadb -u vti -pvti | bzip2 > "${BACKUP_DIR}/${BACKUP_MARIADB_FILE}"
            fi

            logMsg "Finished"
        else
            echo " * Skipping mariadb backup, no such container"
        fi
        ;;
esac
