FROM upshift/centos-systemd:7

LABEL maintainer="docker-remove@upshift.fr"

ARG ANSIBLE_TOWER_VERSION=3.7.3-1

# install centos scl repo
RUN set -eux \
	&& yum install -y \
		centos-release-scl \
		subscription-manager-rhsm-certificates \
	&& yum clean all

# copy yum repos and gpg key
COPY src/ansible-tower.repo /etc/yum.repos.d/ansible-tower.repo
COPY src/RPM-GPG-KEY-redhat-release /etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release

# install packages and dependencies
RUN set -eux \
	&& yum install -y \
		ansible \
		ansible-tower \
		python-psycopg2 \
		iproute \
		sudo \
	&& yum clean all

# copy install scripts
RUN set -eux \
	&& cd /opt \
	&& curl -OL https://releases.ansible.com/ansible-tower/setup/ansible-tower-setup-$ANSIBLE_TOWER_VERSION.tar.gz \
	&& tar xfz ansible-tower-setup-$ANSIBLE_TOWER_VERSION.tar.gz \
	&& rm ansible-tower-setup-$ANSIBLE_TOWER_VERSION.tar.gz \
	&& mv ansible-tower-setup-$ANSIBLE_TOWER_VERSION ansible-tower-setup

# copy systemd scripts
COPY src/ansible-tower-setup.sh /etc/init.d/ansible-tower-setup.sh
COPY src/ansible-tower-setup.service /etc/systemd/system/multi-user.target.wants/ansible-tower-setup.service

# volumes
# VOLUME /var/log/tower
# VOLUME /var/lib/awx/projects
# VOLUME /var/lib/awx/job_status
# VOLUME /var/opt/rh/rh-postgresql10/lib/pgsql/data

# ports
EXPOSE 80/tcp
EXPOSE 443/tcp
