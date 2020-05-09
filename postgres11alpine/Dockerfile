FROM library/postgres:11-alpine

ENV PGDATA /var/lib/pgsql/data
#/var/lib/postgresql/data
ENV PGADMINPASS postgres
ENV PGPGPASS postgres

RUN apk add --update freetds-dev && \
    apk add git gcc clang llvm libc-dev make && \
    apk add postgresql-dev postgresql-contrib && \
    git clone https://github.com/tds-fdw/tds_fdw.git && \
    cd tds_fdw && \
    make USE_PGXS=1 && \
    make USE_PGXS=1 install && \
    apk del git gcc clang llvm libc-dev make && \
    cd ..  && \
    rm -rf tds_fdw

RUN mkdir -p $PGDATA
RUN chmod 0700 $PGDATA
RUN chown postgres. $PGDATA
RUN su postgres -c "initdb ${PGDATA}"
RUN su - postgres -c "pg_ctl -w start -D $PGDATA \
	&& echo create role docker SUPERUSER LOGIN PASSWORD \'docker\' | psql \
        && echo CREATE ROLE admin SUPERUSER CREATEDB CREATEROLE INHERIT REPLICATION LOGIN ENCRYPTED PASSWORD \'${PGADMINPASS}\' | psql \
        && echo ALTER USER postgres PASSWORD \'${PGPGPASS}\' | psql \
        && echo CREATE DATABASE ggc_sr OWNER postgres | psql \
        && pg_ctl -w stop -D $PGDATA"


#RUN mkdir /run/postgresql/
RUN chown postgres. /run/postgresql/

### CONFIGURE ENGINE LOGIN
RUN echo "listen_addresses = '*'" >> $PGDATA/postgresql.conf
RUN echo "host    all             all          0.0.0.0/0               trust" >> $PGDATA/pg_hba.conf
RUN echo "host    all             all          10.0.0.0/24             password" >> $PGDATA/pg_hba.conf

EXPOSE 5432
CMD ["su", "postgres", "-c", "postgres -i -c config_file=$PGDATA/postgresql.conf"]

#su postgres -c 'pg_ctl start -D /var/lib/postgresql/data "-o -c listen_addresses=\"\""'
