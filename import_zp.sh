#!/bin/bash
DATABASE_SCHEMA="pr_monitoring_flora_territory"

. config/settings.ini

# Remove previous log file

rm var/log/sft_zp.log

echo -n "Chemin complet de votre shape ?"
read MYPATH
echo -n "Quel est le nom de votre shape ?"
read DATABASE_TABLE

# Copy SQL files into /tmp system folder in order to edit it with variables

cp data/import_zp.sql /tmp/import_zp.sql

sudo sed -i "s/MY_SRID_LOCAL/$srid_local/g" /tmp/import_zp.sql
sudo sed -i "s/MY_SRID_WORLD/$srid_world/g" /tmp/import_zp.sql
sudo sed -i "s/DATABASE_SCHEMA/$DATABASE_SCHEMA/g" /tmp/import_zp.sql
sudo sed -i "s/DATABASE_TABLE/$DATABASE_TABLE/g" /tmp/import_zp.sql

# Export SHP maille to PostGis and create table zp

sudo -n -u postgres shp2pgsql -s 2154 -c "$MYPATH/$DATABASE_TABLE.shp" $DATABASE_SCHEMA.$DATABASE_TABLE | psql -d $db_name -h localhost -U $user_pg &>> var/log/sft_zp.log

# Insert data into ref_geo.l_areas

export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f /tmp/import_zp.sql &>> var/log/sft_zp.log

# Remove SQL temporary file

rm /tmp/import_zp.sql