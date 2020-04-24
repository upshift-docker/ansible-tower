FROM centos:8

LABEL maintainer="docker-remove@upshift.fr"

ENV \
	ANSIBLE_TOWER_VERSION=3.6.4 \
	ANSIBLE_VERSION=2.9.1 \
	\
	ANSIBLE_TOWER_ADMIN_USERNAME=admin \
	ANSIBLE_TOWER_ADMIN_PASSWORD=redhat \
	ANSIBLE_TOWER_ADMIN_EMAIL=admin@example.com \
	\
	ANSIBLE_TOWER_PG_HOST=db \
	ANSIBLE_TOWER_PG_PORT=5432 \
	ANSIBLE_TOWER_PG_DATABASE=tower \
	ANSIBLE_TOWER_PG_USERNAME=tower \
	ANSIBLE_TOWER_PG_PASSWORD=tower \
	\
	ANSIBLE_TOWER_RABBITMQ_USERNAME=tower \
	ANSIBLE_TOWER_RABBITMQ_PASSWORD=tower \
	ANSIBLE_TOWER_RABBITMQ_COOKIE=tower \
	\
	LANG=C

# copy yum repos and gpg key
COPY src/etc /etc

# install packages and dependencies
RUN set -eux; \
	\
	dnf install -y --nodocs \
		sudo \
		ansible-$ANSIBLE_VERSION \
		ansible-tower-$ANSIBLE_TOWER_VERSION \
	; \
	dnf clean all \
	; \
	true

# copy management playbooks
COPY src/opt /opt

# VOLUME /var/log/tower
# VOLUME /var/lib/awx/projects
# VOLUME /var/lib/awx/job_status

EXPOSE 80/tcp
EXPOSE 443/tcp

WORKDIR /opt/tower-setup

COPY /src/docker-entrypoint /usr/local/bin/
ENTRYPOINT ["docker-entrypoint"]
CMD ["ansible-tower"]
