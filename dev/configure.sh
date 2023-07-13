#!/bin/bash

# tidy up any stale files
rm -rf ./autogenerated
rm -rf ./playbooks

mkdir -p autogenerated || true #ignore error (it might already exist, although we don't check)
mkdir -p playbooks || true #ignore error (it might already exist, although we don't check)

# Edit to suit your instance

# Directory for services secrets (must contain book.pat, jump.pat, project, relay.pat)
export SECRETS=~/secret/app.practable.io/dev

# SSH access
export ZONE=europe-west2-c
export INSTANCE=instance-app-practable-dev

# Health check info
export BACKEND_SERVICE=app-practable-dev-backend-service

# Networking info for services & ansible nginx conf
export INSTANCE_PATH=dev
# used in nginx configuration & ansible playbook for lets encrypt
export DOMAIN=app.practable.io
# Used in ansible nginx playbook for setting up certbot
export EMAIL=rl.eng@ed.ac.uk
# used in all ansible playbook templates (note usually underscore, not hyphen)
export ANSIBLE_GROUP=app_practable_dev

# Static content: main/default content for the instance ("production" equivalent)
export STATIC_REPO_NAME=static-app-practable-io-dev-default
export STATIC_REPO_URL=https://github.com/practable/static-app-practable-io-dev-default.git
# Note that book is deliberately not included in this list of sub-dirs
export STATIC_SUB_DIRS="['config', 'images', 'info', 'ui']"

# Static content: development versions on same server (TODO improve to let devs be self sufficient)
export DEV_STATIC_REPO_NAME=static-app-practable-io-dev-dev
export DEV_STATIC_REPO_URL=https://github.com/practable/static-app-practable-io-dev-dev.git
# Note that book is deliberately not included in this list of sub-dirs
export DEV_STATIC_SUB_DIRS="['config', 'images', 'info', 'ui']"

	
###########################################################################
# Do not edit below this line (unless you want a non-standard installation)
###########################################################################

export HTTPS_HOST="https://${DOMAIN}/${INSTANCE_PATH}"
export WSS_HOST="wss://${DOMAIN}/${INSTANCE_PATH}"

# create login.sh
export PROJECT=$(cat "${SECRETS}/project")
envsubst '${INSTANCE} ${PROJECT} ${ZONE}' < ./templates/login.sh.template > ./login.sh
chmod +x ./login.sh

#create health.sh
envsubst '${BACKEND_SERVICE} ${PROJECT}' < ./templates/health.sh.template > ./health.sh
chmod +x ./health.sh

# Create book.service by adding variables to template
export BOOK_PORT=4000
export BOOK_AUDIENCE="${HTTPS_HOST}/book"
export BOOK_SECRET=$(cat ${SECRETS}/book.pat)
export RELAY_SECRET=$(cat  ${SECRETS}/relay.pat)
envsubst < ./templates/book.service.template > ./autogenerated/book.service

# create relay.service by adding variables to template
export RELAY_ALLOW_NO_BOOKING_ID=true
export RELAY_AUDIENCE="${HTTPS_HOST}/access"
export RELAY_PORT_ACCESS=3000
export RELAY_PORT_PROFILE=6061
export RELAY_PORT_RELAY=3001
export RELAY_SECRET=$(cat ${SECRETS}/relay.pat)
export RELAY_URL="${WSS_HOST}/relay"
envsubst < ./templates/relay.service.template > ./autogenerated/relay.service

# create jump.service by adding variables to template
export JUMP_AUDIENCE="${HTTPS_HOST}/jump"
export JUMP_PORT_ACCESS=3002
export JUMP_PORT_RELAY=3003
export JUMP_SECRET=$(cat ${SECRETS}/jump.pat)
export JUMP_URL="${WSS_HOST}/jump"
envsubst < ./templates/jump.service.template > ./autogenerated/jump.service

# create nginx.conf with the ports and routings above
# export vars to avoid $request_uri, $uri etc being replaced with blank
# https://unix.stackexchange.com/questions/294378/replacing-only-specific-variables-with-envsubst
envsubst '${DOMAIN} ${HTTPS_HOST}' < ./templates/nginx-initial.conf.template > ./autogenerated/nginx-initial.conf
envsubst '${BOOK_PORT} ${DOMAIN} ${HTTPS_HOST} ${RELAY_PORT_ACCESS} ${RELAY_PORT_RELAY} ${JUMP_PORT_ACCESS} ${JUMP_PORT_RELAY}' < ./templates/nginx.conf.template > ./autogenerated/nginx.conf

# Create a vars file for ansible, so we can refer to the domain as needed.
envsubst '${DOMAIN} ${STATIC_REPO_NAME} ${STATIC_REPO_URL} ${STATIC_SUB_DIRS} ${DEV_STATIC_REPO_NAME} ${DEV_STATIC_REPO_URL} ${DEV_STATIC_SUB_DIRS}' < ./templates/vars.yml.template > ./autogenerated/vars.yml

# Populate our playbooks with group name and other variables
export SSL_DOMAIN="${DOMAIN}/${INSTANCE_PATH}"
envsubst '${ANSIBLE_GROUP}' < ./templates/playbook-install-book.yml.template > ./playbooks/install-book.yml
envsubst '${ANSIBLE_GROUP}' < ./templates/playbook-install-jump.yml.template > ./playbooks/install-jump.yml
envsubst '${ANSIBLE_GROUP} ${SSL_DOMAIN} ${EMAIL}' < ./templates/playbook-install-nginx.yml.template > ./playbooks/install-nginx.yml
envsubst '${ANSIBLE_GROUP}' < ./templates/playbook-install-relay.yml.template > ./playbooks/install-relay.yml
envsubst '${ANSIBLE_GROUP}' < ./templates/playbook-revert-relay.yml.template > ./playbooks/revert-relay.yml
envsubst '${ANSIBLE_GROUP}' < ./templates/playbook-update-book.yml.template > ./playbooks/update-book.yml
envsubst '${ANSIBLE_GROUP}' < ./templates/playbook-update-book-service.yml.template > ./playbooks/update-book-service.yml
envsubst '${ANSIBLE_GROUP}' < ./templates/playbook-update-jump-service.yml.template > ./playbooks/update-jump-service.yml
envsubst '${ANSIBLE_GROUP}' < ./templates/playbook-update-nginx-conf.yml.template > ./playbooks/update-nginx-conf.yml
envsubst '${ANSIBLE_GROUP}' < ./templates/playbook-update-relay.yml.template > ./playbooks/update-relay.yml
envsubst '${ANSIBLE_GROUP}' < ./templates/playbook-update-relay-service.yml.template > ./playbooks/update-relay-service.yml
envsubst '${ANSIBLE_GROUP}' < ./templates/playbook-update-static-contents.yml.template > ./playbooks/update-static-contents.yml



