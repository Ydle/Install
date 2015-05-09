#!/bin/bash
#
#	Nom 		: ydle.sh 
#	Auteur 		: Yaug
#	Date 		: 01/07/2014
#
#	Description	: script de création de la base de données et d'installation du framework et du hub
#
#	Usage		: bash ydle.sh
#
#	Mofidications
#	Nom		: Date		: Raison
#	===================================================================================================
#	EricDele	: 02/08/2014	: Ajout des tests sur les saisies de variables, correction variable
#			:		: nom de la base, ajout des messages d'erreur
#	===================================================================================================
#	Dormeur : 01/09/2014 : Ajout de la creation d'un utilisateur pour l'interface
#   ===================================================================================================
#	Yaug : 05/09/2014 : Correction script utilisateur + améliorations diverses
#   ===================================================================================================
#	

# Default values
default_site_path=/var/www/
default_site_dir=ydle
default_db_ydle_login=ydle
default_db_ydle_pass=ydle
default_db_ydle_name=ydle

default_db_host=localhost

default_user_hub_login=admin
default_user_hub_password=password
default_user_hub_mail=admin@localhost

default_db_root_user=root
default_db_root_pass=

ask_value() {
	echo -n $1
	read value
	if [[ "$value" == "" ]]
	then
		#site_path=/var/www
		RETURN=$2
	else
		RETURN=$value
	fi
}

get_parameters (){
	#####################
	#  Application path #
	#####################


	ask_value "Site path (default to $default_site_path): " $default_site_path
	site_path=$RETURN
	ask_value "Site directory (default to $default_site_dir): " $default_site_dir
	site_dir=$RETURN
	#####################
	#  DATABASE ACCESS  #
	#####################

	ask_value "Database username : (default $default_db_ydle_login): " $default_db_ydle_login
	db_ydle_login=$RETURN

	ask_value "Database password : (default $default_db_ydle_pass): " $default_db_ydle_pass
	db_ydle_pass=$RETURN

	ask_value "Database name  : (default $default_db_ydle_pass): " $default_db_ydle_name
	db_ydle_name=$RETURN

	ask_value "Server hostname/ip  : (default $default_db_host): " $default_db_host
	db_host=$RETURN

	#####################
	#  User ACCESS      #
	#####################

	ask_value "Default user for HUB UI  : (default $default_user_hub_login): " $default_user_hub_login
	user_hub_login=$RETURN

	ask_value "Default password for HUB UI  : (default $default_user_hub_password): " $default_user_hub_password
	user_hub_password=$RETURN

	ask_value "Default mail HUB UI  : (default $default_user_hub_mail): " $default_user_hub_mail
	user_hub_mail=$RETURN
}
answer='n'
while [[ $answer == 'n' ]]
do
	get_parameters
	clear
	echo -e "Settings review:"
	echo "--------------------"
	echo "Application path : $site_path"
	echo "Application directory : $site_dir"
	echo "--------------------"
	echo "Ydle Database :"
	echo "Database host : $db_host"
	echo "User : $db_ydle_login"
	echo "Password : $db_ydle_pass"
	echo "Database name : $db_ydle_name"
	echo "--------------------"
	echo "HUB UI "
	echo "User : $user_hub_login"
	echo "Password : $user_hub_password"
	echo "E-Mail : $user_hub_mail"
	echo "--------------------"

	ask_value "All the parameters are ok ? (Y/n)" 
	answer=$RETURN
done

######################
#  DATABASE INSTALL  #
######################
echo -n "Do you want to create database ? [y/n]"
read createdb
if [[ "$createdb" == "y" || "$createdb" == "Y" ]]
then
    echo "Root password for mysql: "
    read  db_root_pass
    
    echo "CREATE DATABASE ${db_ydle_name} DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
    CREATE USER '${db_ydle_login}'@'localhost' IDENTIFIED BY '${db_ydle_pass}';
    GRANT ALL ON ${db_ydle_name}.* TO '${db_ydle_login}';
    quit;"

    mysql -uroot -p${db_root_pass} -e "CREATE DATABASE ${db_ydle_name} DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
    CREATE USER '${db_ydle_login}'@'localhost' IDENTIFIED BY '${db_ydle_pass}';
    GRANT ALL ON ${db_ydle_name}.* TO '${db_ydle_login}';
    "

	if [[ $? -ne 0 ]]
	then
		echo -e "\nSorry, it seems you have got an error during database creation process.\nPlease correct it before continuing"
		echo -e "For information you have answered : \ndatabase name => $db_ydle_name, \ndatabase root password => $db_root_pass\n"
		exit 1
	fi
fi

#####################
#  SYMFONY INSTALL  #
#####################
cd ${site_path};
curl -s https://getcomposer.org/installer | php
YDLE_SECRET="TopSecret" YDLE_LOCALE="en" YDLE_DB_DRIVER="pdo_mysql" YDLE_DB_HOST="${db_host}" YDLE_DB_PORT="null" YDLE_DB_NAME="${db_ydle_name}" YDLE_DB_USER="${db_ydle_login}" YDLE_DB_PASSWORD="${db_ydle_pass}" YDLE_MAILER_TRANSPORT="smtp" YDLE_MAILER_HOST="127.0.0.1" YDLE_MAILER_USER="null" YDLE_MAILER_PASSWORD="null" php composer.phar create-project -s dev ydle/framework ${site_dir}/
cd ${site_dir};
app/console doctrine:schema:update --force --env=prod
app/console doctrine:fixtures:load --env=prod
app/console fos:user:create ${user_hub_login} ${user_hub_mail} ${user_hub_password}

###########################
#  PROJECT CONFIGURATION  #
###########################
chmod 777 app/console
chown -R pi:pi ./*
cp ../composer.phar ./

#########################
#  DEPENDENCIES UPDATE  #
########################


