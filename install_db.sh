#!/bin/bash


. config/settings.ini

# Create log folder in module folders if it don't already exists
if [ ! -d 'var' ]
then
  mkdir var
fi

if [ ! -d 'var/log' ]
then
  mkdir var/log
fi

# Copy SQL files into /tmp system folder in order to edit it with variables
cp data/SFT.sql /tmp/suivi_territoire.sql
cp data/SFT_perturbations.sql /tmp/perturbations_suivi_territoire.sql
cp data/SFT_data.sql /tmp/data_suivi_territoire.sql

#Dont ask for a module ID as we dont know it...
#sudo sed -i "s/MY_ID_MODULE/$id_module_suivi_flore_territoire/g" /tmp/data_suivi_territoire.sql

sudo sed -i "s/MY_SRID_LOCAL/$srid_local/g" /tmp/data_suivi_territoire.sql

# Create SFT schema into GeoNature database
echo "--------------------" &> var/log/install_sft.log
echo "Create database structure" &>> var/log/install_sft.log
echo "--------------------" &>> var/log/install_sft.log

export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f /tmp/suivi_territoire.sql &>> var/log/install_sft.log
# Create perturbations list into nomenclatures schema
echo "--------------------" &>> var/log/install_sft.log
echo "Insert minimal data" &>> var/log/install_sft.log
echo "--------------------" &>> var/log/install_sft.log

export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f /tmp/perturbations_suivi_territoire.sql &>> var/log/install_sft.log

# Include sample data into database
if $insert_sample_data
then
    echo "--------------------" &>> var/log/install_sft.log
    echo "Add sample data" &>> var/log/install_sft.log
    echo "--------------------" &>> var/log/install_sft.log

    sudo -n -u postgres -s shp2pgsql -W "UTF-8" -s 2154 -D -I data/sample/mailles.shp pr_monitoring_flora_territory.maille_tmp | psql -h $db_host -U $user_pg -d $db_name &>> var/log/install_sft.log
    sudo -n -u postgres -s shp2pgsql -W "UTF-8" -s 2154 -D -I data/sample/zp.shp pr_monitoring_flora_territory.zp_tmp | psql -h $db_host -U $user_pg -d $db_name &>> var/log/install_sft.log
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f /tmp/data_suivi_territoire.sql &>>  var/log/install_sft.log
fi

# Remove temporary files
rm /tmp/suivi_territoire.sql
rm /tmp/data_suivi_territoire.sql
