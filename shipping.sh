#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[37m"

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$(echo $0 |cut -d '.' -f1)
SCRIPT_DIR=$PWD
MYSQL_HOST=mysql.naginenihariaws.store
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

dnf install maven -y &>>$LOG_FILE
VALIDATE $? "Installed Maven"

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "Creating system user"
else
    echo -e "User already exist ... $Y SKIPPING $N"
fi

mkdir /app &>>$LOG_FILE
VALIDATE $? "Creating app directory"


curl -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading shipping application sourcecode"

cd /app 
VALIDATE $? "Changing to app directory"
rm -rf /app/*
VALIDATE $? "Removing existing code"

unzip /tmp/shipping.zip &>>$LOG_FILE
VALIDATE $? "unzip the shipping code"

mvn clean package &>>$LOG_FILE
VALIDATE $? "Dependences are downloading"

mv target/shipping-1.0.jar shipping.jar &>>$LOG_FILE
VALIDATE $? "Rename the application sourcefile"

cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service &>>$LOG_FILE
VALIDATE $? "copy systemctl service"

systemctl daemon-reload
systemctl enable shipping &>>$LOG_FILE
VALIDATE $? "Enable shipping Service"

dnf install mysql -y &>>$LOG_FILE
VALIDATE $? "Mysql client "

mysql -h $MYSQL_HOST -uroot -pRoboShop@1 -e 'use cities' &>>$LOG_FILE
if [ $? -ne 0 ]; then
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/schema.sql &>>$LOG_FILE
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/app-user.sql  &>>$LOG_FILE
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/master-data.sql &>>$LOG_FILE
else
    echo -e "Shipping data is already loaded ... $Y SKIPPING $N"
fi
systemctl restart shipping &>>$LOG_FILE
VALIDATE $? "Restarted shipping Service"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))
echo -e "Script executed in: $Y $TOTAL_TIME Seconds $N"