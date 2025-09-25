#!/bin/bash

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

dnf module disable nginx -y &>>$LOG_FILE
VALIDATE $? "Disabling Nginx"

dnf module enable nginx:1.24 -y &>>$LOG_FILE
VALIDATE $? "Enabling Nginx 24"

dnf install nginx -y &>>$LOG_FILE
VALIDATE $? "Installed Nginx"

systemctl enable nginx 
VALIDATE $? "Enabled Nginx"

rm -rf /usr/share/nginx/html/* 

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading user application source code"

cd /usr/share/nginx/html
VALIDATE $? "Changing to app directory"
unzip /tmp/frontend.zip &>>$LOG_FILE
VALIDATE $? "unzip the user code"


cp $SCRIPT_DIR/nginx.conf /etc/nginx/nginx.conf &>>$LOG_FILE
VALIDATE $? "copy systemctl service"
systemctl daemon-reload
systemctl enable nginx &>>$LOG_FILE
VALIDATE $? "Enable nginx Service"
systemctl restart nginx &>>$LOG_FILE
VALIDATE $? "Restarted nginx Service"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))
echo -e "Script executed in: $Y $TOTAL_TIME Seconds $N"