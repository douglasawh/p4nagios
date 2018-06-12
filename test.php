<?php


#example: php test.php -w 300 -c 400 -v price -u ontariobeerapi.ca/products/2139068/
#requires utils.php from http://doug.warner.fm/nagios-utilsphp-script-for-php-plugins.html


$options = getopt("w:c:v:u:");

$ch = curl_init();
curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
curl_setopt($ch, CURLOPT_URL, $options["u"]); 
$chData=curl_exec($ch);

$chDataArray=json_decode($chData,true);
curl_close($ch);

include 'utils.php';
#echo $chDataArray[$options["v"]];

$warning = new Nagios_Plugin_Range($options["w"]);
$critical = new Nagios_Plugin_Range($options["c"]);


if($critical->check_range($chDataArray[$options["v"]])){
	echo "CRITICAL!\n";
	return 2;
}


if($warning->check_range($chDataArray[$options["v"]])){
	echo "WARNING!\n";
	return 1; 
}

echo "OK!\n";
return 0;

?>

