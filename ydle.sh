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
#       ===================================================================================================
#	

echo "Site path (default to /var/www/): "
read  site_path
if [[ "$site_path" == "" ]]
then
	echo -e "Setting default path to /var/www\n"
	site_path=/var/www
fi

#####################
#  DATABASE ACCESS  #
#####################
echo "Ydle login for mysql: "
read  db_ydle_login
echo "Ydle password for mysql: "
read  db_ydle_pass
echo "Name of the database: "
read db_ydle_name

if [[ "$db_ydle_login" == "" || "$db_ydle_pass" == "" || "$db_ydle_name" == "" ]]
then
	echo "You have to set correctly the login, password and name of the database before continuing"
	exit 1
fi

#####################
#  User ACCESS      #
#####################
echo "User login for the HUB : "
read  user_hub_login
echo "User password for the HUB: "
read  user_hub_pass
echo "User mail for the HUB : "
read  user_hub_mail

if [[ "$user_hub_login" == "" || "$user_hub_pass" == "" || "$user_hub_mail" == "" ]]
then
	echo "You have to set correctly the login, password and mail for the HUB before continuing"
	exit 1
fi

######################
#  DATABASE INSTALL  #
######################
echo -n "Do you want to create database ? [y/n]"
read createdb
if [[ "$createdb" == "y" || "$createdb" == "Y" ]]
then
        echo "Root password for mysql: "
        read  db_root_pass
	if [[ "$db_root_pass" == "" ]]
	then
		echo "You have to set correctly the database root password"
		exit 1
	fi

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
else
	echo -e "\nYou choose to do not create the database.\n\nWe are going to check the access to your database $db_ydle_name\n"
	mysql -u${db_ydle_login} -p${db_ydle_pass} -e "use ${db_ydle_name};"
        if [[ $? -ne 0 ]]
        then
                echo -e "\nSorry, it seems you have got an error for connecting to the database with the credentials you give.\nPlease correct it before continuing"
                echo -e "For information you have answered : \ndatabase name => $db_ydle_name,\ndatabase login => $db_ydle_login,\ndatabase password => $db_ydle_pass\n"
                exit 1
        fi
fi

#####################
#  SYMFONY INSTALL  #
#####################
cd ${site_path};
curl -s https://getcomposer.org/installer | php
YDLE_SECRET="TopSecret" YDLE_LOCALE="en" YDLE_DB_DRIVER="pdo_mysql" YDLE_DB_HOST="127.0.0.1" YDLE_DB_PORT="null" YDLE_DB_NAME="${db_ydle_name}" YDLE_DB_USER="${db_ydle_login}" YDLE_DB_PASSWORD="${db_ydle_pass}" YDLE_MAILER_TRANSPORT="smtp" YDLE_MAILER_HOST="127.0.0.1" YDLE_MAILER_USER="null" YDLE_MAILER_PASSWORD="null" php composer.phar create-project -s dev ydle/framework ydle/
fos:user:create ${user_hub_login} ${user_hub_mail} ${user_hub_pass}

###########################
#  PROJECT CONFIGURATION  #
###########################
chmod 777 ydle/app/console

#########################
#  DEPENDENCIES UPDATE  #
########################

