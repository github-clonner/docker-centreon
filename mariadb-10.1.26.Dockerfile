FROM oxyure/base:latest
LABEL com.oxyure.vendor="United Microbiotas" \
      maintainer="stef@oxyure.com" \
      description="MariaDB 10.1.26"

# If those two password build arguments are empty, a random string will be choosen.
# NB: This is NOT the MariaDB root password
ARG ROOT_PASSWD=""
ARG OPERATOR_PASSWD=""

# Change some passwords (do not leave them empty)
RUN if [ -z "${ROOT_PASSWD}" ]; then echo "root:$(echo $RANDOM |sha512sum |cut -d' ' -f1)" | chpasswd; \
        else echo "root:${ROOT_PASSWD}" | chpasswd; fi

## Additional repositories & Common packages ##
RUN apk update && apk add tini

## MariaDB configuration


# Install MariaDB & remove OpenRC (this image will use a custom entrypoint).
# Also remove sudo.
RUN apk del --purge openrc sudo &&\
    apk add mariadb=10.1.26-r0 mariadb-client=10.1.26-r0

## Clean the room ##
RUN rm -rf /var/cache/apk/* /tmp/* \
           /etc/modprobe.d /etc/modules-load.d /etc/modules \
           /etc/udhcpd.conf /etc/securetty

# Add some information in the MOTD file
RUN sed -i -e "s/{build_date}/$(date)/" \
           -e "s/{build_host}/$(uname -rs)/" /etc/motd

# /entrypoint may also be a symlink…
COPY entrypoints/mariadb.entrypoint /entrypoint

# Files and perms
RUN chmod go-rwx /entrypoint

WORKDIR /
USER root
ENTRYPOINT ["/sbin/tini","/entrypoint"]