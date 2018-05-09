<?php
/* Args:
0 => makedb.php,
1 => "$MOODLE_DOMAIN",
2 => "$MOODLE_DB_HOST",
3 => "$MOODLE_DB_USER",
4 => "$MOODLE_DB_PASSWORD",
5 => "$MOODLE_DB_NAME",
*/
$stderr = fopen('php://stderr', 'w');

fwrite($stderr, "\nWriting initial Moodle config\n");

$domain = $argv[1];
// Figure out if we have a port in the database host string
if (strpos($argv[2], ':') !== false) {
	list($host, $port) = explode(':', $argv[2], 2);
}
else {
  $host = $argv[2];
	$port = 3306;
}
$user = $argv[3];
$password = addslashes($argv[4]);
$dbname = $argv[5];

$string = "<?php\n";
$string .= "unset(\$CFG);\n";
$string .= "global \$CFG;\n";
$string .= "\$CFG = new stdClass();\n";
$string .= "\$CFG->wwwroot = '".$domain."';\n";
$string .= "\$CFG->dataroot = '/var/www/html/moodledata';\n";
$string .= "\$CFG->directorypermissions = 02777;\n";
$string .= "\$CFG->admin = 'admin';\n";
$string .= "\$CFG->dbtype = 'mysqli';\n";
$string .= "\$CFG->dblibrary = 'native';\n";
$string .= "\$CFG->dbhost = '".$host."';\n";
$string .= "\$CFG->dbuser = '".$user."';\n";
$string .= "\$CFG->dbpass = '".$password."';\n";
$string .= "\$CFG->dbname = '".$dbname."';\n";
$string .= "\$CFG->prefix = 'mdl_';\n";
$string .= "\$CFG->dboptions = array(\n";
$string .= "    'dbpersist' => false,\n";
$string .= "    'dbsocket' => false,\n";
$string .= "    'dbport' => $port,\n";
$string .= "    'dbcollation' => 'utf8mb4_unicode_ci',\n";
$string .= ");\n";
$string .= "require_once(__DIR__ . '/lib/setup.php'); // Do not edit\n";

$path     = '/var/www/html/config.php';

$status = file_put_contents($path, $string);

if ($status === false) {
	fwrite($stderr, "\nCould not write configuration file to $path, you can create this file with the following contents:\n\n$string\n");
}
