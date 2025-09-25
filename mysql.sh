#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[37m"

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$(echo $0 |cut -d '.' -f1)
SCRIPT_DIR=$PWD
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
START_TIME=$(date +%s)

mkdir -p $LOGS_FOLDER
echo "Script started executed at:$(date)" |tee -a $LOG_FILE

if [ $USERID -ne 0 ]; then
    echo "ERROR:: please run the script with root privelege" |tee -a $LOG_FILE
    exit 1  #failure mean other then Zero
fi

VALIDATE() {
if [ $1 -ne 0 ]; then
    echo -e " $2 is $R FAILURE $N" |tee -a $LOG_FILE
    exit 1
else 
    echo -e " $2 is $G SUCCESS $N" |tee -a $LOG_FILE
fi
}

dnf install mysql-server -y  &>>$LOG_FILE
VALIDATE $? "Installing Mysql"
systemctl enable mysqld  &>>$LOG_FILE
VALIDATE $? "Enabling Mysql"
systemctl start mysqld  &>>$LOG_FILE
VALIDATE $? "Started Mysql"
mysql_secure_installation --set-root-pass RoboShop@1 &>>$LOG_FILE
VALIDATE $? "Setting up Root password"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))
echo -e "Script executed in: $Y $TOTAL_TIME Seconds $N"