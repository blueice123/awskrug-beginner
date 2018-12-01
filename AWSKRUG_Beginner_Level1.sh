#!/bin/bash

function RDS_memcache_setting(){
  ## RDS, memcache 설정 전 파일 백업
  echo $rds_endpoint $rds_username $rds_password $memcache_endpoint
  cp -rp /var/www/html/web-demo/config.php /var/www/html/web-demo/config.php.$day

  ## RDS 설정
  RDS_check_con=$(nc -z -w5 $rds_endpoint 3306 | grep "succeeded")
  if  [ -n "$RDS_check_con" ];then  ## DB dump insert
    mysql -h $rds_endpoint -u $rds_username -p''$rds_password'' web_demo < /var/www/html/web-demo/web_demo.sql  >& /dev/null
    rds_check=$(mysql -h $rds_endpoint -u $rds_username -p''$rds_password'' web_demo -e "select * from upload_images" | wc -l)

    if [ $rds_check -eq 11 ];then  ## row 수 확인
      perl -pi -e "s/$db_hostname = \"localhost\"\;/$db_hostname = \"$rds_endpoint\"\;/g" /var/www/html/web-demo/config.php
      perl -pi -e "s/$db_username = \"username\"\;/$db_username = \"$rds_username\"\;/g" /var/www/html/web-demo/config.php
      perl -pi -e "s/$db_password = \"password\"\;/$db_password = \"$rds_password\"\;/g" /var/www/html/web-demo/config.php
      echo "RDS setup is completed."
    else
      echo "Please check the RDS username and password"
    fi
  else
    echo "Can not access RDS endpoint"
  fi

  ## memcache 설정
  memcache=$(echo  $memcache_endpoint | awk -F":" '{print $1}')  ## port number 분리
  memcache_check_con=$(nc -z -w5 $memcache 11211 | grep "succeeded" )  ## memcache 접근 체크
  if  [ -n "$memcache_check_con" ];then  ## php.ini 변경
        cp -rp /etc/php.ini /etc/php.ini.$day ## backup
        perl -pi -e "s/session.save_handler = files/session.save_handler = memcache/g" /etc/php.ini
        perl -pi -e "s/session.save_path = \"\/var\/lib\/php\/session\"/session.save_path = $memcache_endpoint/g" /etc/php.ini
        perl -pi -e "s/;date.timezone =/date.timezone = America\/New_York/g" /etc/php.ini
        echo "memcache setup is completed."
  else
    echo "Can not access memcache endpoint"
  fi

  ## config.php 설정 완료 후 아파치 재시작
  sudo service httpd restart >& /dev/null
}

## 필수 패키지 설치
sudo yum update -y  >& /dev/null
sudo yum install -y httpd php-5.3.29 php-mysql-5.3.29 mysql-server-5.5 telnet git curl php-pecl-memcache >& /dev/null

# PHP date timezone 정의
perl -pi -e "s/\;date.timezone =/date.timezone = Asia\/Seoul/g" /etc/php.ini

## 소스파일 다운 로드
sudo chown -R ec2-user:ec2-user /var/www
cd /var/www/html
git clone https://github.com/blueice123/awskrug-beginner  >& /dev/null
mv /var/www/html/awskrug-beginner /var/www/html/web-demo >& /dev/null

## Apache 시작
sudo service httpd start >& /dev/null
sudo chkconfig httpd on




case "$1" in
        server)
            ## NFS 서버에서만 uploads 파일 권한 변경
            sudo chown -R apache:apache /var/www/html/web-demo/uploads >& /dev/null

            ## RDS 관련 설정
            echo "Please enter RDS endpoint(ex: web-demo.c6gradmwj7dj.ap-northeast-2.rds.amazonaws.com)"
            read rds_endpoint
            echo "Please enter RDS username(ex: username)"
            read rds_username
            echo "Please enter RDS password(ex: password)"
            read rds_password
            ## memcache 설정
            echo "Please enter Memcache endpoint(ex : aws-hands-on.ndzwq5.cfg.apn2.cache.amazonaws.com:11211)"
            read memcache_endpoint

            day=$(date +%y%m%d)

            ## NFS 설정
            cp -rp /etc/exports /etc/exports.$day #backup
            cp -rp /etc/hosts.allow /etc/hosts.allow.$day #backup
            echo "/var/www/html/web-demo/uploads/ 10.100.0.0/16(rw,fsid=0,insecure,no_subtree_check,async)" >> /etc/exports
            echo "portmap:ALL" >> /etc/hosts.allow
            echo "lockd:ALL" >> /etc/hosts.allow
            echo "mountd:ALL" >> /etc/hosts.allow
            echo "rquotad:ALL" >> /etc/hosts.allow
            echo "statd:ALL" >> /etc/hosts.allow
            sudo service rpcbind restart >& /dev/null
            sudo service nfs start >& /dev/null
            sudo service nfslock restart >& /dev/null

            RDS_memcache_setting $rds_endpoint $rds_username $rds_password $memcache_endpoint

            echo "NFS Server setup is complete"
        ;;

        client)
            ## RDS 관련 설정
            echo "Please enter RDS endpoint(ex: web-demo.c6gradmwj7dj.ap-northeast-2.rds.amazonaws.com)"
            read rds_endpoint
            echo "Please enter RDS username(ex: username)"
            read rds_username
            echo "Please enter RDS password(ex: password)"
            read rds_password
            ## memcache 설정
            echo "Please enter Memcache endpoint(ex : aws-hands-on.ndzwq5.cfg.apn2.cache.amazonaws.com:11211)"
            read memcache_endpoint

            day=$(date +%y%m%d)

            ## NFS 설정
            sudo service rpcbind restart  >& /dev/null
            sudo service nfslock restart  >& /dev/null
            echo "Please enter NFS Server Private IP(ex: 10.100.128.22)"
            read NFS_SERVER_IP
            if  [ -n "$NFS_SERVER_IP" ];then
              mv /var/www/html/web-demo/uploads/ /var/www/html/web-demo/uploads.$day
              mkdir /var/www/html/web-demo/uploads/
              sudo mount -t nfs -o retrans=1 -o timeo=10 -o retry=0 $NFS_SERVER_IP:/var/www/html/web-demo/uploads/ /var/www/html/web-demo/uploads/
              nfs_mount_check=$(df -h | grep "/var/www/html/web-demo/uploads/")
              if [ -n "$nfs_mount_check" ];then
                RDS_memcache_setting $rds_endpoint $rds_username $rds_password $memcache_endpoint
                echo "NFS Client setup is complete"
              else
                echo "Check communication with NFS Server"
              fi
            else
              echo "Please check NFS Server IP again"
            fi

        ;;
        *)
            echo $"Usage: $0 {server|client}"
            exit 1
esac
