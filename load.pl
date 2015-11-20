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

$signedPayload = $query->param('signed_payload');
($jsonObject,$hmac) = split(/\./, $signedPayload);
$jsonObject = decode_base64(uri_unescape($jsonObject));
$convertedJSONObject = decode_json($jsonObject);
$db = "sevillas_imageoptimizer";
$host = "localhost";
$user = "sevillas_admin";
$password = '';
$dbh   = DBI->connect ("DBI:mysql:database=$db:host=$host", $user, $password) or die "Can't connect to database: $DBI::errstr\n";
$selectStatement = "SELECT userID, storeHash, lastPagePulled FROM authentication WHERE userID = ? AND storeHash = ?";
$statement = $dbh->prepare($selectStatement);
$statement->execute($convertedJSONObject->{'user'}{'id'}, $convertedJSONObject->{'context'});

if ($statement->rows == 1) {
    ($userID, $storeHash, $lastPagePulled) = $statement->fetchrow_array;
    if ($lastPagePulled == 1) {
    $deleteApiImages = "DELETE FROM apiImages WHERE storeHash = ?";
$deleteOptimizedImages = "DELETE FROM optimizedImages WHERE storeHash = ?";
$deleteApiImages = $dbh->prepare($deleteApiImages);
$deleteOptimizedImages = $dbh->prepare($deleteOptimizedImages);
($trash,$pureHash) = split /\//, $storeHash;
$deleteApiImages->execute($pureHash);
$deleteOptimizedImages->execute($pureHash);
        print "Content-Type: text/html\n\n";
        $template = HTML::Template->new(filename => 'templates/index.tmpl');
        $template->param(userID => $convertedJSONObject->{'user'}{'id'});
        $template->param(storeHash => $convertedJSONObject->{'context'});
        print $template->output;
    }
    else {
        print "Content-Type: text/html\n\n";
        $template = HTML::Template->new(filename => 'templates/resume.tmpl');
        $template->param(userID => $convertedJSONObject->{'user'}{'id'});
        $template->param(storeHash => $convertedJSONObject->{'context'});
        $template->param(batchNumber => $lastPagePulled); 
        print $template->output;
    }
}
else {
    print "Found nothing";
}