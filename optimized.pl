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
    $template->param(checkOptimizedURL => '../imageoptimizer/checkoptimizedimages.pl');
    $template->param(userID => $userID);
    print $template->output;
    end_html;
    #start the process for the first batch
    #first thing we need to pull from the apiImages database
    #necessary variables preconstructed
    $url = 'https://api.bigcommerce.com/stores/'.$storeHash.'/v2/products/images?limit=249&';
    $domainName = 'http://store-'.$storeHash.'.mybigcommerce.com';
    $insertImageStatement = "INSERT INTO apiImages (batchNumber,imageID,imageURL,isProcessed,productID,storeHash) VALUES(?,?,?,?,?,?)";
    $inserRecord = $dbh->prepare($insertImageStatement);
    $clientID = "25ixngxr1cj720nz1lzdpi4wtvj9ipg";

    #the count
    $pages = int($count / 249) + 1;
    if ($count == 0) {
        $pages = 0;
    }
    
    #now the pull
    $currentJSON = 1;
    for($counter = 1; $counter <= $pages; $counter++) {
        $response = $userAgent->get($url."page=".$counter,@headers);
        #change it to an array
        @jsonArray = @{decode_json($response->decoded_content())};
        foreach $jsonObject (@jsonArray) {
            $batchNumber = int($currentJSON/26) + 1;
            $inserRecord->execute($batchNumber, $jsonObject->{'id'}, $domainName.'/product_images/'.$jsonObject->{'image_file'}, 0, $jsonObject->{'product_id'}, $storeHash);
            $currentJSON++;
        }
    }

}