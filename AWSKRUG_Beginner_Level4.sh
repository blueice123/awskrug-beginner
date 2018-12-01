#!/bin/bash

echo "Please enter Memcache endpoint(ex : aws-hands-on.ndzwq5.cfg.apn2.cache.amazonaws.com:11211)"
read memcache_endpoint

memcache=$(echo  $memcache_endpoint | awk -F":" '{print $1}')  ## port number 분리

perl -pi -e "s/$enable_cache = false\;/$enable_cache = true\;/g" /var/www/html/web-demo/config.php
perl -pi -e "s/$cache_server = \"\[dns-endpoint-of-your-elasticache-memcached-instance\]\"\;/$cache_server = \"$memcache\"\;/g" /var/www/html/web-demo/config.php


sudo service httpd restart >& /dev/null
