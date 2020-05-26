FROM library/postgres:11-alpine

ARG PGADMINPASS=postgres
ARG PGPGPASS=postgres
ARG PGDBNAME=workspace

ARG IMPORT_SCHEMA=import_schema
ARG IMPORT_SERVER=import_server

ARG MSSQL_SERVER=mssql
ARG MSSQL_DB=master
ARG MSSQL_USER=sa
ARG MSSQL_PASS=P4ssw0rD
ARG MSSQL_SCHEMA=dbo


ENV PGDATA /var/lib/pgsql/data
#ENV PGDATA /var/lib/postgresql/data

RUN apk add --update freetds-dev && \
    apk add nmap git gcc clang llvm libc-dev make && \
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
    && echo CREATE ROLE admin SUPERUSER CREATEDB CREATEROLE INHERIT REPLICATION LOGIN ENCRYPTED PASSWORD \'${PGADMINPASS}\' | psql \
    && echo ALTER USER postgres PASSWORD \'${PGPGPASS}\' | psql \
    && echo CREATE DATABASE ${PGDBNAME} OWNER postgres | psql \
    && echo CREATE EXTENSION tds_fdw | psql -d ${PGDBNAME} \
    && echo CREATE SCHEMA ${IMPORT_SCHEMA} | psql -d ${PGDBNAME} \ 
    && echo CREATE SERVER ${IMPORT_SERVER} FOREIGN DATA WRAPPER tds_fdw OPTIONS \(servername \'${MSSQL_SERVER}\', database \'${MSSQL_DB}\', msg_handler \'notice\'\) | psql -d ${PGDBNAME} \ 
    && echo CREATE USER MAPPING FOR postgres SERVER ${IMPORT_SERVER} OPTIONS \(username \'${MSSQL_USER}\', password \'${MSSQL_PASS}\'\) | psql -d ${PGDBNAME} \ 
    && echo IMPORT FOREIGN SCHEMA ${MSSQL_SCHEMA} FROM SERVER ${IMPORT_SERVER} INTO ${IMPORT_SCHEMA} OPTIONS \(import_default \'true\'\) | psql -d ${PGDBNAME} \ 
    && pg_ctl -w stop -D $PGDATA"

RUN chown postgres. /run/postgresql/

RUN echo "listen_addresses = '*'" >> $PGDATA/postgresql.conf
RUN echo "host    all             all          0.0.0.0/0               trust" >> $PGDATA/pg_hba.conf
RUN echo "host    all             all          10.0.0.0/24             password" >> $PGDATA/pg_hba.conf

EXPOSE 5432
ENTRYPOINT ["su", "postgres", "-c", "postgres -i -c config_file=$PGDATA/postgresql.conf"]
#CMD ["psql -U postgres -a -f /var/data/pg/setup-fdw.sql"]
