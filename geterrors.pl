#!/usr/bin/perl
use cPanelUserConfig;
use MIME::Base64 qw( decode_base64 );

use CGI qw(:standard);
use LWP::UserAgent;
use JSON qw( decode_json );
use DBI;
use Text::CSV;

$query = CGI->new();
$storeHash = $query->param('storeHash');
$userID = $query->param('userID');

$db = "sevillas_imageoptimizer";
$host = "localhost";
$user = "sevillas_admin";
$password = '';
$dbh   = DBI->connect ("DBI:mysql:database=$db:host=$host", $user, $password) or die "Can't connect to database: $DBI::errstr\n";
$selectStatement = "SELECT productID, imageID, imageURL, errorMessage FROM apiImages WHERE isProcessed = 0 AND storehash = ?";
$selectStatement = $dbh->prepare($selectStatement);
$selectStatement->execute($storeHash);

$fileLocation = '/home/sevillas/public_html/imageoptimizer/errormessages/'.$storeHash.'_errors.csv';
$fileName = $storeHash.'_errors.csv';

open(FILEHANDLER,'>',"$fileLocation") or die "$fileLocation: $!";
print FILEHANDLER "productID,imageID,imageURL,errorMessage\n";
while (@row = $selectStatement->fetchrow_array) {
    print FILEHANDLER $row[0].",".$row[1].",".$row[2].",".$row[3]."\n";
}
close(FILEHANDLER);

#read the contents
open(FILEHANDLER,'<',"$fileLocation") or die "$fileLocation: $!";
@contentsOfFile = <FILEHANDLER>;
close(FILEHANDLER);

print "Content-Type:application/x-download\n";     
print "Content-Disposition:attachment;filename=$fileName\n\n";
print @contentsOfFile