FROM upshift/centos-systemd:7

LABEL maintainer="docker-remove@upshift.fr"

ARG ANSIBLE_TOWER_VERSION=3.7.3

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
		ansible-tower-$ANSIBLE_TOWER_VERSION \
		libselinux-python \
		setools-libs \
		python-psycopg2 \
		iproute \
		sudo \
	&& yum clean all

ARG ANSIBLE_TOWER_RELEASE=1

# copy install scripts
RUN set -eux \
	&& cd /opt \
	&& curl -OL https://releases.ansible.com/ansible-tower/setup/ansible-tower-setup-$ANSIBLE_TOWER_VERSION-$ANSIBLE_TOWER_RELEASE.tar.gz \
	&& tar xfz ansible-tower-setup-$ANSIBLE_TOWER_VERSION-$ANSIBLE_TOWER_RELEASE.tar.gz \
	&& rm ansible-tower-setup-$ANSIBLE_TOWER_VERSION-$ANSIBLE_TOWER_RELEASE.tar.gz \
	&& mv ansible-tower-setup-$ANSIBLE_TOWER_VERSION-$ANSIBLE_TOWER_RELEASE ansible-tower-setup

# copy redhat certificates
COPY src/redhat-uep.pem /etc/rhsm/ca/redhat-uep.pem

# copy systemd scripts
COPY src/ansible-tower-setup.sh /etc/init.d/ansible-tower-setup.sh
COPY src/ansible-tower-setup.service /etc/systemd/system/multi-user.target.wants/ansible-tower-setup.service

# volumes
# VOLUME /var/log/tower
# VOLUME /var/lib/awx/projects
# VOLUME /var/lib/awx/job_status

# ports
EXPOSE 80/tcp
EXPOSE 443/tcp
