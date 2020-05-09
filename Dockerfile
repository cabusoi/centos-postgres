FROM centos:7

ENV PGDATA /var/lib/pgsql/data
ENV PGADMINPASS postgres
ENV PGPGPASS postgres

### INSTALL POSTGRES AND CREATE DB

#RUN yum install -y python-psycopg2 postgresql-server postgresql-contrib postgresql-devel 
#RUN	postgresql-setup initdb  -D $PGDATA 
RUN \
    yum -y update && \
    yum install -y http://yum.postgresql.org/9.4/redhat/rhel-7.1-x86_64/pgdg-centos94-9.4-3.noarch.rpm \
                   http://yum.postgresql.org/9.4/redhat/rhel-7.1-x86_64/postgresql94-libs-9.4.26-1PGDG.rhel7.x86_64.rpm \
                   http://yum.postgresql.org/9.4/redhat/rhel-7.1-x86_64/postgresql94-9.4.26-1PGDG.rhel7.x86_64.rpm \
                   http://yum.postgresql.org/9.4/redhat/rhel-7.1-x86_64/postgresql94-server-9.4.26-1PGDG.rhel7.x86_64.rpm \
                   http://yum.postgresql.org/9.4/redhat/rhel-7.1-x86_64/postgresql94-contrib-9.4.26-1PGDG.rhel7.x86_64.rpm  \
                   http://yum.postgresql.org/9.4/redhat/rhel-7.1-x86_64/postgresql94-devel-9.4.26-1PGDG.rhel7.x86_64.rpm  && \
        rm -r  /var/tmp/*  && \
        yum clean all 

#RUN	systemctl enable postgresql && systemctl start postgresql

RUN su - postgres -c "/usr/pgsql-9.4/bin/initdb -E UTF8 -D $PGDATA"

RUN echo "port = 5432" >> $PGDATA/postgresql.conf

RUN su - postgres -c "/usr/pgsql-9.4/bin/pg_ctl -w start -D $PGDATA \
	&& echo create role docker SUPERUSER LOGIN PASSWORD \'docker\' | psql \
        && echo CREATE ROLE admin SUPERUSER CREATEDB CREATEROLE INHERIT REPLICATION LOGIN ENCRYPTED PASSWORD \'${PGADMINPASS}\' | psql \
        && echo ALTER USER postgres PASSWORD \'${PGPGPASS}\' | psql \
        && echo CREATE DATABASE ggc_sr OWNER postgres | psql \
        && /usr/pgsql-9.4/bin/pg_ctl -w stop -D $PGDATA"

### CONFIGURE ENGINE LOGIN
### adjust listen_addresses line /var/lib/pgsql/data/postgresql.conf
RUN echo "listen_addresses = '*'" >> $PGDATA/postgresql.conf

### adjust authentication /var/lib/pgsql/data/pg_hba.conf
RUN echo "host    all             all          0.0.0.0/0               trust" >> $PGDATA/pg_hba.conf
RUN echo "host    all             all          10.0.0.0/24             password" >> $PGDATA/pg_hba.conf

### ADJUST REDHAT FIREWALL
#RUN firewall-cmd --permanent --zone=trusted --add-source=10.0.0.0/24
#RUN firewall-cmd --reload

### INSTALL TDS:
RUN yum install -y wget git make gcc #postgresql-devel

RUN	wget http://dl.fedoraproject.org/pub/epel/7/x86_64/Packages/f/freetds-doc-1.1.20-1.el7.noarch.rpm && \
	wget http://dl.fedoraproject.org/pub/epel/7/x86_64/Packages/f/freetds-1.1.20-1.el7.x86_64.rpm && \
	wget http://dl.fedoraproject.org/pub/epel/7/x86_64/Packages/f/freetds-devel-1.1.20-1.el7.x86_64.rpm && \
	wget http://dl.fedoraproject.org/pub/epel/7/x86_64/Packages/f/freetds-libs-1.1.20-1.el7.x86_64.rpm && \
	yum install -y ./freetds*

# tsql -C
# cat /etc/freetds.conf


RUN export PATH=/usr/pgsql-9.4/bin:$PATH
RUN	git clone https://github.com/tds-fdw/tds_fdw.git
RUN	PATH=/usr/pgsql-9.4/bin:$PATH && cd tds_fdw/ && make USE_PGXS=1 install

EXPOSE 5432
CMD ["su", "postgres", "-c", "/usr/pgsql-9.4/bin/postgres -i -c config_file=$PGDATA/postgresql.conf"]

# sudo -u postgres psql -U postgres -h localhost -p 5432 -d ggc_sr -c "CREATE EXTENSION tds_fdw;"
