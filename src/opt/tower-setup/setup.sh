#!/usr/bin/env bash
# This script runs setup for Ansible Tower.

# -------------
# Initial Setup
# -------------

# Cause exit codes to trickle through piping.
set -o pipefail

# When using an interactive shell, force colorized output from Ansible.
if [ -t "0" ]; then
    ANSIBLE_FORCE_COLOR=True
fi

# Set variables.
TIMESTAMP=$(date +"%F-%T")
LOG_DIR="/var/log/tower"
LOG_FILE="${LOG_DIR}/setup-${TIMESTAMP}.log"
TEMP_LOG_FILE='setup.log'

INVENTORY_FILE="inventory"
OPTIONS=""

# What playbook should be run?
PLAYBOOK="install.yml"

# -------------
# Helper functions
# -------------

log_success() {
    if [ $# -eq 0 ]; then
        cat
    else
        echo "$*"
    fi
}

log_warning() {
    echo -n "[warn] "
    if [ $# -eq 0 ]; then
        cat
    else
        echo "$*"
    fi
}

log_error() {
    echo -n "[error] "
    if [ $# -eq 0 ]; then
        cat
    else
        echo "$*"
    fi
}

# --------------
# Usage
# --------------

function usage() {
    cat << EOF
Usage: $0 [Options] [-- Ansible Options]

Options:
  -i INVENTORY_FILE     Path to ansible inventory file (default: ${INVENTORY_FILE})
  -e EXTRA_VARS         Set additional ansible variables as key=value or YAML/JSON
                        i.e. -e bundle_install=false will force an online install

  -b                    Perform a database backup in lieu of installing.
  -r                    Perform a database restore in lieu of installing.
  -k                    Generate and distribute a new SECRET_KEY

  -h                    Show this help message and exit
EOF
    exit 64
}

# --------------
# Option Parsing
# --------------

# First, search for -- (end of args)
# Anything after -- is placed into OPTIONS and passed to Ansible
# Anything before -- (or the whole string, if no --) is processed below
ARGS=$*
if [[ "$ARGS" == *"-- "* ]]; then
    SETUP_ARGS=${ARGS%%-- *}
    OPTIONS=${ARGS##*-- }
else
    SETUP_ARGS=$ARGS
    OPTIONS=""
fi

# Process options to setup.sh
while getopts ':i:e:brk' OPTION $SETUP_ARGS; do
    case $OPTION in
        i)
            INVENTORY_FILE="$OPTARG"
            ;;
        e)
            OPTIONS="$OPTIONS -e $OPTARG"
            ;;
        b)
            PLAYBOOK="backup.yml"
            TEMP_LOG_FILE="backup.log"
            OPTIONS="$OPTIONS --force-handlers"
            ;;
        r)
            PLAYBOOK="restore.yml"
            TEMP_LOG_FILE="restore.log"
            OPTIONS="$OPTIONS --force-handlers"
            ;;
        k)
            PLAYBOOK="rekey.yml"
            TEMP_LOG_FILE="rekey.log"
            OPTIONS="$OPTIONS --force-handlers"
            ;;
        *)
            usage
            ;;
    esac
done

# Change to the running directory for tower conf file and inventory file defaults.
cd "$( dirname "${BASH_SOURCE[0]}" )"

# Sanity check: Test to ensure that an inventory file exists.
if [ ! -e "${INVENTORY_FILE}" ]; then
    log_error <<-EOF
		No inventory file could be found at ${INVENTORY_FILE}.
		Please create one, or specify one manually with -i.
		EOF
    exit 64
fi

# Run the playbook.
PYTHONUNBUFFERED=x ANSIBLE_FORCE_COLOR=$ANSIBLE_FORCE_COLOR \
ANSIBLE_ERROR_ON_UNDEFINED_VARS=True \
ansible-playbook -i "${INVENTORY_FILE}" -v \
                 $OPTIONS \
                 $PLAYBOOK 2>&1 | tee $TEMP_LOG_FILE

# Save the exit code and output accordingly.
RC=$?
if [ ${RC} -ne 0 ]; then
    log_error "Oops!  An error occurred while running setup."
else
    log_success "The setup process completed successfully."
fi

# Save log file.
if [ -d "${LOG_DIR}" ]; then
    sudo cp ${TEMP_LOG_FILE} ${LOG_FILE}
    if [ $? -eq 0 ]; then
        sudo rm ${TEMP_LOG_FILE}
    fi
    log_success "Setup log saved to ${LOG_FILE}"
else
    log_warning <<-EOF
		${LOG_DIR} does not exist.
		Setup log saved to ${TEMP_LOG_FILE}.
		EOF
fi

exit ${RC}
