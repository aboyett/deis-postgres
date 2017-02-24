FROM postgres:9.4

ENV LANG=en_US.utf8 \
    PGDATA=/var/lib/postgresql/data

RUN buildDeps='gcc git libffi-dev libssl-dev python3-dev python3-pip python3-wheel' && \
    localedef -i en_US -c -f UTF-8 -A /etc/locale.alias en_US.UTF-8 && \
    export DEBIAN_FRONTEND=noninteractive && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        $buildDeps \
        lzop \
        pv \
        python3 \
        util-linux \
        # swift package needs pkg_resources and setuptools
        python3-pkg-resources \
        python3-setuptools && \
    ln -sf /usr/bin/python3 /usr/bin/python && \
    ln -sf /usr/bin/pip3 /usr/bin/pip && \
    pip install \
        envdir==0.7 \
        wal-e[aws,azure,google,swift]==1.0.1 && \
    # "upgrade" boto to 2.43.0 + the patch to fix minio connections
    pip install --upgrade git+https://github.com/deis/boto@88c980e56d1053892eb940d43a15a68af4ebb5e6 && \
    # cleanup
    apt-get purge -y --auto-remove $buildDeps && \
    apt-get autoremove -y && \
    apt-get clean -y && \
    # package up license files if any by appending to existing tar
    COPYRIGHT_TAR='/usr/share/copyrights.tar' && \
    ( if [ -f $COPYRIGHT_TAR.gz ] ; then gunzip -f $COPYRIGHT_TAR.gz ; fi ) && \
    tar -rf $COPYRIGHT_TAR /usr/share/doc/*/copyright && \
    gzip $COPYRIGHT_TAR && \
    rm -rf \
        /usr/share/doc \
        /usr/share/man \
        /usr/share/info \
        /usr/share/locale \
        /var/lib/apt/lists/* \
        /var/log/* \
        /var/cache/debconf/* \
        /etc/systemd \
        /lib/lsb \
        /lib/udev \
        /usr/lib/x86_64-linux-gnu/gconv/IBM* \
        /usr/lib/x86_64-linux-gnu/gconv/EBC* && \
    bash -c "mkdir -p /usr/share/man/man{1..8}"

COPY rootfs /
ENV WALE_ENVDIR=/etc/wal-e.d/env
RUN mkdir -p $WALE_ENVDIR

CMD ["/docker-entrypoint.sh", "postgres"]
EXPOSE 5432
