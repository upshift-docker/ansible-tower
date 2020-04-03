# Ansible Tower server

Docker image for [Ansible Tower](https://www.ansible.com/products/tower).

This image provides easy deployment of an Ansible Tower server in a Docker environment and can be used for product testing (license required).

## Running this image with docker-compose

Create `docker-compose.yml` file as following:

```yml
version: '3'

volumes:
  tower_data:
  tower_projects:

services:

  database:
    image: postgres:10-alpine
    volumes:
      - tower_data:/var/lib/postgresql/data
    environment:
        - "POSTGRES_DB=tower"
        - "POSTGRES_USER=tower"
        - "POSTGRES_PASSWORD=tower"

  server:
    image: upshift/ansible-tower:latest
    depends_on:
        - database
    ports:
        - "80:80"
        - "443:443"
    volumes:
        - tower_projects:/var/lib/awx/projects
    environment:
        - "ANSIBLE_TOWER_ADMIN_USERNAME=admin"
        - "ANSIBLE_TOWER_ADMIN_PASSWORD=password"
        - "ANSIBLE_TOWER_PG_HOST=database"
        - "ANSIBLE_TOWER_PG_PORT=5432"
        - "ANSIBLE_TOWER_PG_DATABASE=tower"
        - "ANSIBLE_TOWER_PG_USERNAME=tower"
        - "ANSIBLE_TOWER_PG_PASSWORD=tower"
        - "ANSIBLE_TOWER_CREATE_PRELOAD_DATA=yes"
```

Then run all services `docker-compose up -d`. Wait until initialization is complete and go to http://localhost/ to access the Tower web ui.

## Persistent data

To make your data persistent to upgrading, you should mount named docker volumes or host folders.

Tower server:
- `/var/lib/awx/projects/` ansible projects storage directory
- `/var/lib/awx/job_status/` job outputs directory
- `/var/log/tower/` Ansible Tower logs directory

Database server:
- `/var/lib/postgresql/data/` PostgreSQL database files

## Auto configuration via environment variables

This image supports customization via environment variables.

### ANSIBLE_TOWER_ADMIN_USERNAME

*Default value*: `admin`

Administrator user name.

### ANSIBLE_TOWER_ADMIN_PASSWORD

*Default value*: `redhat`

Administrator password.

### ANSIBLE_TOWER_ADMIN_EMAIL

*Default value*: `admin@example.com`

Administrator email.

### ANSIBLE_TOWER_PG_HOST

*Default value*: `db`

PostgreSQL database server host name.

### ANSIBLE_TOWER_PG_PORT

*Default value*: `5432`

PostgreSQL database server port.

### ANSIBLE_TOWER_PG_DATABASE

*Default value*: `tower`

PostgreSQL database name.

### ANSIBLE_TOWER_PG_USERNAME

*Default value*: `tower`

PostgreSQL database username.

### ANSIBLE_TOWER_RABBITMQ_USERNAME

*Default value*: `tower`

Internal rabbitmq server username.

### ANSIBLE_TOWER_RABBITMQ_PASSWORD

*Default value*: `tower`

Internal rabbitmq user password.

### ANSIBLE_TOWER_RABBITMQ_COOKIE

*Default value*: `tower`

Internal rabbitmq erlang cookie.

### ANSIBLE_TOWER_CREATE_PRELOAD_DATA

*Default value*: `no`

Initialize database with sample data.

### ANSIBLE_TOWER_DISABLE_HTTPS

*Default value*: `no`

Disable SSL configuration when Tower is behind a reverse proxy.

### ANSIBLE_TOWER_REMOVE_TRANSLATIONS

*Default value*: `no`

Disable web ui translations, force using english regardless of accept-language sent by the browser.
