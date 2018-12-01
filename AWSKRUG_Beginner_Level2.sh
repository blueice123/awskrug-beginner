#!/bin/bash

function s3_config(){
  perl -pi -e "s/$storage_option = \"hd\"\;/$storage_option = \"s3\"\;/g" /var/www/html/web-demo/config.php
  perl -pi -e "s/$s3_bucket  = \"my-upload-bucket\"\;/$s3_bucket  = \"$s3_bucket_name\";/g" /var/www/html/web-demo/config.php

  sudo service httpd restart >& /dev/null
}

case "$1" in
        server)
            day=$(date +%y%m%d)

            ## NFS 설정
            sudo service nfs stop >& /dev/null

            echo "Please enter S3 bucket name(ex : aws-hands-on-beginner-syha)"
            read s3_bucket_name
            s3_config $s3_bucket_name
        ;;

        client)
            day=$(date +%y%m%d)

            ## NFS 설정
            sudo umount -f /var/www/html/web-demo/uploads

            echo "Please enter S3 bucket name(ex : aws-hands-on-beginner-syha)"
            read s3_bucket
            s3_config $s3_bucket
        ;;
        *)
            echo $"Usage: $0 {server|client}"
            exit 1
esac
