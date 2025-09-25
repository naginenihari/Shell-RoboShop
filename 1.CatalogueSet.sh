#!/bin/bash

set -euo pipefail
USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[37m"

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$(echo $0 |cut -d '.' -f1)
MONGODB_HOST=mongodb.naginenihariaws.store
SCRIPT_DIR=$PWD
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"

trap 'echo "There is an error in $LINENO, Command is: $BASH_COMMAND"' ERR
mkdir -p $LOGS_FOLDER
echo "Script started executed at:$(date)" |tee -a $LOG_FILE

if [ $USERID -ne 0 ]; then
    echo "ERROR:: please run the script with root privelege" |tee -a $LOG_FILE
    exit 1  #failure mean other then Zero
fi

##### NodeJS ####
dnf module disable nodejs -y &>>$LOG_FILE
dnf module enable nodejs:20 -y &>>$LOG_FILE
dnf install nodejs -y &>>$LOG_FILE
id roboshop &>>$LOG_FILE

if [ $? -ne 0 ]; then
 useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
else
 echo -e "User is Already exist ..$Y SKIPPING $N"
fi

mkdir -p /app &>>$LOG_FILE
rm -rf /app/*
curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOG_FILE
cd /app 
unzip /tmp/catalogue.zip &>>$LOG_FILE
npm install &>>$LOG_FILE
cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service &>>$LOG_FILE
systemctl daemon-reload
systemctl enable catalogue &>>$LOG_FILE
cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo &>>$LOG_FILE
dnf install mongodb-mongoshbb -y &>>$LOG_FILE
INDEX=$(mongosh $MONGODB_HOST --quiet --eval "db.getMongo().getDBNames().indexOf('catalogue')")
if [ $INDEX -le 0 ]; then
    mongosh --host $MONGODB_HOST </app/db/master-data.js &>>$LOG_FILE
    VALIDATE $? "Load catalogue products"
else
    echo -e "Catalogue products already loaded ... $Y SKIPPING $N"
fi  

mongosh --host $MONGODB_HOST </app/db/master-data.js &>>$LOG_FILE
systemctl restart catalogue &>>$LOG_FILE
