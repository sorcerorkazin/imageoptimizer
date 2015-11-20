#!/usr/bin/perl
use cPanelUserConfig;
use MIME::Base64 qw( decode_base64 );

use CGI qw(:standard);
use LWP::UserAgent;
use JSON qw( decode_json );
use DBI;
use URI::Escape;

$query = CGI->new();

$signedPayload = $query->param('signed_payload');
($jsonObject,$hmac) = split(/\./, $signedPayload);

print header(-type => 'text/plain');
$db = "sevillas_imageoptimizer";
$host = "localhost";
$user = "sevillas_admin";
$password = '';
$dbh   = DBI->connect ("DBI:mysql:database=$db:host=$host", $user, $password) or die "Can't connect to database: $DBI::errstr\n";
$deleteStatement = "DELETE FROM authentication WHERE userID = ? AND storeHash = ?";
$deleteApiImages = "DELETE FROM apiImages WHERE storeHash = ?";
$deleteOptimizedImages = "DELETE FROM optimizedImages WHERE storeHash = ?";
$deleteApiImages = $dbh->prepare($deleteApiImages);
$deleteOptimizedImages = $dbh->prepare($deleteOptimizedImages);
$statement = $dbh->prepare($deleteStatement);
$jsonObject = decode_base64(uri_unescape($jsonObject));
$convertedJSONObject = decode_json($jsonObject);
($trash,$pureHash) = split /\//, $convertedJSONObject->{'context'};
$statement->execute($convertedJSONObject->{'user'}{'id'}, $convertedJSONObject->{'context'});
$deleteApiImages->execute($pureHash);
$deleteOptimizedImages->execute($pureHash);
print $jsonObject."\n";
print $hmac."\n";
$dbh->disconnect;