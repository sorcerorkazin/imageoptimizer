#!/usr/bin/perl
use cPanelUserConfig;
use MIME::Base64 qw( decode_base64 );

use CGI qw(:standard);
use LWP::UserAgent;
use JSON qw( decode_json );
use DBI;
use URI::Escape;
use HTML::Template;

$query = CGI->new();
$userID = $query->param('userID');
$currentBatch = $query->param('batchNumber');
$compressionLevel = $query->param('compressLevel');
$storeHash = $query->param('storeHash');

$db = "sevillas_imageoptimizer";
$host = "localhost";
$user = "sevillas_admin";
$password = '';
$dbh   = DBI->connect ("DBI:mysql:database=$db:host=$host", $user, $password) or die "Can't connect to database: $DBI::errstr\n";
$selectStatement = "SELECT apiToken FROM authentication WHERE userID = ? AND storehash = ?";
$statement = $dbh->prepare($selectStatement);
$statement->execute($userID, $storeHash);

if ($statement->rows > 0) {
    print "Content-Type: text/html\n";
    print 'Access-Control-Allow-Origin: *'."\n\n";
    $template = HTML::Template->new(filename => 'templates/preview.tmpl');
    ($apiToken) = $statement->fetchrow_array;
    ($trash,$storeHash) = split(/\//,$storeHash);
    @headers = (
        'Accept' => 'application/json',
        'Content-Type' => 'application/json',
        'X-Auth-Client' => $clientID,
        'X-Auth-Token' => $apiToken
        );
    $userAgent = LWP::UserAgent->new;
    $countURL = 'https://api.bigcommerce.com/stores/'.$storeHash.'/v2/products/images/count';
    $count = $userAgent->get($countURL,@headers);
    $count = $count->decoded_content();
    $count = decode_json $count;
    $count = $count->{'count'};
    $databaseCount = "SELECT COUNT(*) FROM apiImages WHERE storeHash = '".$storeHash."'";
    ($imageCount) = $dbh->selectrow_array($databaseCount);
    

    $template->param(page => $currentBatch);
    $template->param(storeHash => $storeHash);
    $template->param(storeCount => $count);
    $template->param(compressionLevel => $compressionLevel);
    $template->param(checkOptimizedURL => '../imageoptimizer/checkoptimizedimagesex.pl');
    $template->param(userID => $userID);
    print $template->output;
}