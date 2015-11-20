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
$query->delete('userID');
@names = $query->param;
print header(-type => 'text/plain');


#grab the information we need to make API calls (could be replaced for cookies?)
$db = "sevillas_imageoptimizer";
$host = "localhost";
$user = "sevillas_admin";
$password = 'APollo21@!43$#';
$dbh   = DBI->connect ("DBI:mysql:database=$db:host=$host", $user, $password) or die "Can't connect to database: $DBI::errstr\n";
$selectStatement = "SELECT apiToken, storeHash FROM authentication WHERE userID = ".$userID;
$statement = $dbh->prepare($selectStatement);
$statement->execute();

if ($statement->rows > 0) {
    $userAgent = LWP::UserAgent->new;
    ($apiToken, $storeHash) = $statement->fetchrow_array;
    $url = 'https://api.bigcommerce.com/'.$storeHash.'/v2/products/images/';
    $clientID = "qfxrbya79gsib8hsyoabk8gz4yay8d2";
    @headers = (
        'Accept' => 'application/json',
        'Content-Type' => 'application/json',
        'X-Auth-Client' => $clientID,
        'X-Auth-Token' => $apiToken
    );
    foreach $parameter (@names) {
        ($trash,$imageID) = split(/-/,$parameter);
        if ($query->param($parameter) eq "newImg") {
            #need an API call to Adam's image optimizer to get the URL
            
            
            #need to make an API call to update the image.
            $update = "{\"image_file\":\"url\"}";
            $req = HTTP::Request->new("PUT", $url.$imageID);
            $req->header(@headers);
            $req->content($update);
            print "Will change the image for ". $url.$imageID."\n";
        }
    }    
}
else {
    print "Sorry didnt find anything";
}