#!/bin/bash

## 필수 패키지 설치
sudo yum update -y  >& /dev/null
sudo yum install -y httpd php-5.3.29 php-mysql-5.3.29 mysql-server-5.5 telnet git curl  >& /dev/null

# PHP date timezone 정의
perl -pi -e "s/\;date.timezone =/date.timezone = Asia\/Seoul/g" /etc/php.ini

## 소스파일 다운 로드
sudo chown -R ec2-user:ec2-user /var/www
cd /var/www/html
git clone https://github.com/blueice123/awskrug-beginner  >& /dev/null
mv /var/www/html/awskrug-beginner /var/www/html/web-demo >& /dev/null
sudo chown -R apache:apache /var/www/html/web-demo/uploads

## Apache, MySQL 시작
sudo service mysqld start >& /dev/null
sudo service httpd start >& /dev/null
sudo chkconfig httpd on

## DB 설정 및 dump insert
echo -e "\nPlease press Enter key"
mysql -u root -p'' mysql -e "CREATE DATABASE web_demo" >& /dev/null
echo -e "\nPlease press Enter key"
mysql -u root -p'' mysql -e "CREATE USER 'username'@'%' IDENTIFIED BY 'password'"  >& /dev/null
echo -e "\nPlease press Enter key"
mysql -u root -p'' mysql -e "GRANT ALL on web_demo.* to username@localhost IDENTIFIED BY 'password' with grant option"  >& /dev/null
mysql -u username -p'password' web_demo < /var/www/html/web-demo/web_demo.sql  >& /dev/null
mysql -u username -p'password' web_demo -e "select * from upload_images"
echo """select * from upload_images"" 하였을 때 10 row가 출력되면 정상입니다."

## 설정 완료 후 아파치 재시작
sudo service httpd restart >& /dev/null

## Ec2 public ip 확인 후 브라우저 안내
Publicip=$(curl http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null)
echo "URL : http://"$Publicip"/web-demo"
