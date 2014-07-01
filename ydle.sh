#!/bin/bash
echo "Site path (default to /var/www/): "
read  site_path;

#####################
#  DATABASE ACCESS  #
#####################
echo "Ydle login for mysql: "
read  db_ydle_login
echo "Ydle password for mysql: "
read  db_ydle_pass
echo "Name of the database: "
read db_ydle_name

######################
#  DATABASE INSTALL  #
######################
echo -n "Do you want to create database ? [Y/n]"
read createdb
if [ "$createdb" = "y" ]; then
        echo "Root password for mysql: "
        read  db_root_pass
        echo "CREATE DATABASE ${db_name} DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
        CREATE USER '${db_ydle_login}'@'localhost' IDENTIFIED BY '${db_ydle_pass}';
        GRANT ALL ON ${db_name}.* TO '${db_ydle_login}';
        quit;"
        mysql -uroot -p${db_root_pass} -e "CREATE DATABASE ${db_name} DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
        CREATE USER '${db_ydle_login}'@'localhost' IDENTIFIED BY '${db_ydle_pass}';
        GRANT ALL ON ${db_name}.* TO '${db_ydle_login}';
        "
fi

#####################
#  SYMFONY INSTALL  #
#####################
cd ${site_path};
curl -s https://getcomposer.org/installer | php
YDLE_SECRET="TopSecret" YDLE_LOCALE="fr" YDLE_DB_DRIVER="pdo_mysql" YDLE_DB_HOST="127.0.0.1" YDLE_DB_PORT="null" YDLE_DB_NAME="${db_ydle_name}" YDLE_DB_USER="${db_ydle_login}" YDLE_DB_PASSWORD="${db_ydle_pass}" YDLE_MAILER_TRANSPORT="smtp" YDLE_MAILER_HOST="127.0.0.1" YDLE_MAILER_USER="null" YDLE_MAILER_PASSWORD="null" php composer.phar create-project -s dev ydle/framework ydle/

###########################
#  PROJECT CONFIGURATION  #
###########################
chmod 777 ydle/app/console

#########################
#  DEPENDENCIES UPDATE  #
########################

