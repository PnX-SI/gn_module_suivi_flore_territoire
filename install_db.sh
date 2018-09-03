#!/bin/bash


. config/settings.ini

if [-f 'var/log/install_sft.log' ]
then
  rm var/log/install_sft.log
fi

cp data/SFT.sql /tmp/suivi_territoire.sql
cp data/SFT_data.sql /tmp/data_suivi_territoire.sql
# copie le fichier SFT.sql et SFT_data.sql dans tmp

sudo sed -i "s/MY_ID_MODULE/$id_application/g" /tmp/data_suivi_territoire.sql
# modifier une partie de la chaine de caractère, remplace la chaine MY_ID_MODULE par la variable $MY_ID_MODULE
export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f /tmp/suivi_territoire.sql &>> var/log/install_sft.log


export PGPASSWORD=$user_pg_pass;sudo -n -u postgres -s shp2pgsql -W "UTF-8" -s 2154 -D -I /tmp/mailles.shp pr_monitoring_flora_territory.maille_tmp | psql -h $db_host -U $user_pg -d $db_name &>> var/log/install_sft.log

export PGPASSWORD=$user_pg_pass;sudo -n -u postgres -s shp2pgsql -W "UTF-8" -s 2154 -D -I /tmp/zp.shp pr_monitoring_flora_territory.zp_tmp | psql -h $db_host -U $user_pg -d $db_name &>> var/log/install_sft.log


export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f /tmp/data_suivi_territoire.sql &>>  var/log/install_sft.log


rm /tmp/suivi_territoire.sql
rm /tmp/data_suivi_territoire.sql

