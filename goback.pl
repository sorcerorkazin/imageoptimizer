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
$storeHash = $query->param('storeHash');
$userID = $query->param('userID');
$db = "sevillas_imageoptimizer";
$host = "localhost";
$user = "sevillas_admin";
$password = '';
$dbh   = DBI->connect ("DBI:mysql:database=$db:host=$host", $user, $password) or die "Can't connect to database: $DBI::errstr\n";


$deleteApiImages = "DELETE FROM apiImages WHERE storeHash = ?";
$deleteOptimizedImages = "DELETE FROM optimizedImages WHERE storeHash = ?";
$deleteApiImages = $dbh->prepare($deleteApiImages);
$deleteOptimizedImages = $dbh->prepare($deleteOptimizedImages);
$deleteApiImages->execute($storeHash);
$deleteOptimizedImages->execute($storeHash);

print "Content-Type: text/html\n\n";
$template = HTML::Template->new(filename => 'templates/index.tmpl');
$template->param(userID => $userID);
$template->param(storeHash => 'stores/'.$storeHash);
print $template->output;