#!/usr/bin/env bash

printf "Database password: "
read psqlroot

sudo setenforce 0

sudo yum -y install wget nano epel-release

# Install PSQL Repo
sudo yum -y install https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm

# Install PSQL
sudo yum -y install postgresql12-server postgresql12

# Init SQL DB
sudo /usr/pgsql-12/bin/postgresql-12-setup initdb

# Enable psql
sudo systemctl enable --now postgresql-12

# user for opennms
sudo -i -u postgres createuser opennms

# make database
sudo -i -u postgres createdb -O opennms opennms

# Set SQL superuser password
sudo -i -u postgres psql -c "ALTER USER postgres WITH PASSWORD '${psqlroot}';"
sudo -i -u postgres psql -c "ALTER USER opennms WITH PASSWORD '${psqlroot}';"

sudo cp pg_hba.conf /var/lib/pgsql/12/data/.
sudo chown postgres:postgres /var/lib/pgsql/12/data/pg_hba.conf
sudo chmod 600 /var/lib/pgsql/12/data/pg_hba.conf

# restart
sudo systemctl reload postgresql-12

# Download Java
wget https://download.oracle.com/java/17/latest/jdk-17_linux-x64_bin.rpm

# Install Java
sudo yum -y install ./jdk-17_linux-x64_bin.rpm

# Install OpenNMS repo & gpg key
sudo yum -y install https://yum.opennms.org/repofiles/opennms-repo-stable-rhel7.noarch.rpm
sudo rpm --import https://yum.opennms.org/OPENNMS-GPG-KEY

# Install the things
sudo yum -y install rrdtool jrrd2 jicmp jicmp6 opennms-core opennms-webapp-jetty opennms-plugin-cloud opennms-webapp-hawtio

# Add the OpenNMS psql user password
sudo -u opennms /opt/opennms/bin/scvcli set postgres opennms $psqlroot

# Config the psql root user's password
sudo -u opennms /opt/opennms/bin/scvcli set postgres-admin postgres $psqlroot

# Replace creds for users
# sudo -u opennms nano /opt/opennms/etc/opennms-datasources.xml
sudo cp opennms-datasources.xml /opt/opennms/etc/.
sudo chown opennms:opennms /opt/opennms/etc/opennms-datasources.xml
sudo chmod 664 vi /opt/opennms/etc/opennms-datasources.xml

# Autodetect best java
sudo /opt/opennms/bin/runjava -s

# Init database
sudo /opt/opennms/bin/install -dis

# Start and enable service
sudo systemctl enable --now opennms

# Open port
sudo firewall-cmd --permanent --add-port=8980/tcp
sudo firewall-cmd --reload
