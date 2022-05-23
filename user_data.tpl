#!/bin/bash

db_username=${db_username}
db_user_password=${db_user_password}
db_name=${db_name}
db_RDS=${db_RDS}
yum update -y
yum install -y polkit git docker
cd /home/ec2-user/
git clone https://github.com/amir-akhavans/ecs-project.git
mv ecs-project/* ./
mv ./docker/web/Dockerfile ./
systemctl enable docker.service
systemctl start docker.service
docker build -t fixably .
docker run -e MYSQL_DATABASE=$db_name -e MYSQL_USERNAME=$db_username -e MYSQL_PASSWORD=$db_user_password -e MYSQL_HOST=$db_RDS --name project -p 80:80 fixably