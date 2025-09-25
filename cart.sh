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

dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "Disabling NodeJS"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "Enabling NodeJS 20"

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "Installed NodeJS"

useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
VALIDATE $? "Creating system user"

mkdir /app &>>$LOG_FILE
VALIDATE $? "Creating app directory"


curl -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading cart application source code"

cd /app 
VALIDATE $? "Changing to app directory"
unzip /tmp/cart.zip &>>$LOG_FILE
VALIDATE $? "unzip the cart code"
npm install &>>$LOG_FILE
VALIDATE $? "Install Dependencies"

cp $SCRIPT_DIR/cart.service /etc/systemd/system/cart.service &>>$LOG_FILE
VALIDATE $? "copy systemctl service"
systemctl daemon-reload
systemctl enable cart &>>$LOG_FILE
VALIDATE $? "Enable cart Service"
systemctl restart cart &>>$LOG_FILE
VALIDATE $? "Restarted cart Service"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))
echo -e "Script executed in: $Y $TOTAL_TIME Seconds $N"