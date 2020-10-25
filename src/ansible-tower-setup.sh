#!/bin/bash -eu

# export logs on container output
exec >/proc/1/fd/1 2>/proc/1/fd/2

# go to setup directory
cd /opt/ansible-tower-setup

# get environment from systemd
for tmp_env in $(tr "\000" "\n" < /proc/1/environ | grep "^ANSIBLE_TOWER_")
do
        eval "$tmp_env"
done

# configure inventory variables
for tmp_var in ${!ANSIBLE_TOWER_@}
do
        tmp_conf=${tmp_var##ANSIBLE_TOWER_}
        sed -i "s/^;*\s*${tmp_conf,,}=.*/${tmp_conf,,}='${!tmp_var}'/" inventory
done

# create secret file
if [[ "${ANSIBLE_TOWER_SECRET_KEY:-}" != "" ]]
then
	echo -n "${ANSIBLE_TOWER_SECRET_KEY}" >/etc/tower/SECRET_KEY
fi

# disable https if behind reverse proxy
if [[ "${ANSIBLE_TOWER_DISABLE_HTTPS:-no}" == "yes" ]]
then
	echo "nginx_disable_https='yes'" >>inventory
fi

# remove translations if requested
if [[ "${ANSIBLE_TOWER_REMOVE_TRANSLATIONS:-no}" == "yes" ]]
then
	rm -f /var/lib/awx/venv/awx/lib/python3.6/site-packages/awx/ui/static/languages/{es,fr,ja,nl,zh}.json
	rm -fr /var/lib/awx/venv/awx/lib/python3.6/site-packages/awx/locale/{es,fr,ja,nl,zh}
fi

# setup instance
./setup.sh
