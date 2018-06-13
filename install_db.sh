#!/bin/bash


. config/settings.ini

cp data/suivi_terrritoire.sql /tmp/suivi_terrritoire.sql

sudo sed -i "s/MY_ID_MODULE/$MY_ID_MODULE/g" /tmp/suivi_terrritoire

sudo -n -u postgres -s shp2pgsql -W "UTF-8" -s 2154 -D -I /tmp/zp4.shp pr_monitoring_flora_territory.zp_tmp | sudo -n -u postgres -s psql -d geonature2db

sudo -n -u postgres -s shp2pgsql -W "UTF-8" -s 2154 -D -I /tmp/maille_25m.shp pr_monitoring_flora_territory.maille_tmp | sudo -n -u postgres -s psql -d geonature2db


export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f /tmp/suivi_terrritoire.sql &>> var/log/install_sft.logs