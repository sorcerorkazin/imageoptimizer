#!/usr/bin/perl
use cPanelUserConfig;
use MIME::Base64 qw( decode_base64 );

use CGI qw(:standard);
use LWP::UserAgent;
use JSON qw( decode_json );
use DBI;
use URI::Escape;
use HTML::Template;
use HTTP::Request;

$query = CGI->new();
$storeHash = $query->param('storehash');
$currentBatch = $query->param('currentBatch');
$compressionLevel = $query->param('compressionLevel');

print 'Access-Control-Allow-Origin: *'."\n\n";
$db = "sevillas_imageoptimizer";
$host = "localhost";
$user = "sevillas_admin";
$password = '';
$dbh   = DBI->connect ("DBI:mysql:database=$db:host=$host", $user, $password) or die "Can't connect to database: $DBI::errstr\n";
$userAgent = LWP::UserAgent->new;
$unoptomizedImagesStatement = "SELECT imageID, imageURL FROM apiImages WHERE storeHash = ? AND batchNumber = ?";
$optimizedInsertStatement = "INSERT INTO optimizedImages (imageID, originalImageURL, optimizedImageURL, originalSize, newSize, pageNumber, storeHash) VALUES(?,?,?,?,?,?,?)";
$changeAttempted = "UPDATE apiImages SET attempted = 1 WHERE imageID = ? AND storeHash = ?";
$updateIsProcessed = "UPDATE apiImages SET isProcessed = 1 WHERE imageID = ? AND storeHash = ?";
$updateErrorMessage = "UPDATE apiImages SET errorMessage = ? WHERE imageID = ? AND storeHash = ?";
$updateErrorMessage = $dbh->prepare($updateErrorMessage);
$updateIsProcessed = $dbh->prepare($updateIsProcessed);
$optimizedInsert = $dbh->prepare($optimizedInsertStatement);
$optimizingStatement = $dbh->prepare($unoptomizedImagesStatement);
$changeAttempted = $dbh->prepare($changeAttempted);
$optimizingStatement->execute($storeHash,$currentBatch);
$imageAPIUrl = 'https://bc-image-compressor.herokuapp.com/compress';
@imageAPIHeaders = (
    'Authorization' => 'Token token=',
    'Content-Type' => 'application/json'
);
$req = HTTP::Request->new("POST", $imageAPIUrl);
$req->header(@imageAPIHeaders);
while (@row = $optimizingStatement->fetchrow_array) {
    $imageObject = '{"image_url":"'.$row[1].'","options":{"percentage":'.$compressionLevel.'}}';
    $req->content($imageObject);
    $response = $userAgent->request($req);
    $jsonObject = decode_json $response->decoded_content();
    if ($jsonObject->{'status'} == 500) {
        #failed
        $changeAttempted->execute($row[0],$storeHash);
        $updateErrorMessage->execute($jsonObject->{'error'}, $row[0], $storeHash);
    }
    else {
        $optimizedInsert->execute($row[0],$row[1],$jsonObject->{'compressed_url'}, $jsonObject->{'original_bytes'}, $jsonObject->{'compressed_bytes'}, $currentBatch, $storeHash);
        $updateIsProcessed->execute($row[0],$storeHash);
        $changeAttempted->execute($row[0],$storeHash);
    }
}
