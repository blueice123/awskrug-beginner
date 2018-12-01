<?php
// Include the AWS SDK for PHP
require 'aws-sdk-for-php/aws-autoloader.php';
use Aws\S3\S3Client;

// Database connection parameters
$db_hostname = "localhost";
$db_database = "web_demo";
$db_username = "username";
$db_password = "password";

// Image upload options
$storage_option = "hd";
$hd_folder  = "uploads";
$s3_region  = "ap-northeast-2";
$s3_bucket  = "my-upload-bucket";
$s3_baseurl = "https://s3-ap-northeast-2.amazonaws.com/";
if ($storage_option == "s3")
{
	$s3_client = S3Client::factory(array('region' => $s3_region, 'signature' => 'v4'));
}

// Simulate latency, in seconds
$latency = 0;

// Cache configuration
$enable_cache = false;
$cache_server = "[dns-endpoint-of-your-elasticache-memcached-instance]";

// CloudFront options
$cloudfront_option = "none";
$cf_baseurl = "https://DomainName.cloudfront.net";
?>
