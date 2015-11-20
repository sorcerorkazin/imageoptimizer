#!/usr/bin/perl
use cPanelUserConfig;

use CGI qw(:standard);
use LWP::UserAgent;
use JSON qw( decode_json );
use DBI;
use HTML::Template;

$query = CGI->new();

#regularUser OAuth client creds
$clientID = "qfxrbya79gsib8hsyoabk8gz4yay8d2";
$clientSecret = "";

$code = $query->param('code');
$scope = $query->param('scope');
$grantType = 'authorization_code';
$redirectURL = "";
$context = $query->param('context');

$db = "sevillas_imageoptimizer";
$host = "localhost";
$user = "sevillas_admin";
$password = '';
$dbh   = DBI->connect ("DBI:mysql:database=$db:host=$host", $user, $password) or die "Can't connect to database: $DBI::errstr\n";

#print "Client ID \= $clientID\n";
#print "Client Secret \= \n";
#print "Code = $code\n";
#print "Scope = $scope\n";
#print "Grant Type = $grantType\n";
#print "Redirect URL = $redirectURL\n";
#print "Context = $context\n";

#print "-----Sending in request-----\n";
$userAgent = LWP::UserAgent->new;
$authenticationServer = "https://login.bigcommerce.com/oauth2/token";
$response = $userAgent->post($authenticationServer, {
                              'client_id' => $clientID,
                              'client_secret' => $clientSecret,
                              'code' => $code,
                              'scope' => $scope,
                              'grant_type' => $grantType,
                              'redirect_uri' => $redirectURL,
                              'context' => $context});
$content = $response->decoded_content();
$jsonObject = decode_json($content);
#print "User ID: ".$jsonObject->{'user'}{'id'}."\n";
#userID, userEmail, #apiToken, overallSizeSaved, lastImageID, storeHash
$insertStatement = "INSERT INTO authentication(userID, userEmail, apiToken, storeHash) VALUES(?, ?, ?, ?)";
$statement = $dbh->prepare($insertStatement);
$statement->execute($jsonObject->{'user'}{'id'},$jsonObject->{'user'}{'email'}, $jsonObject->{'access_token'}, $jsonObject->{'context'});
print "Content-Type: text/html\n\n";
$template = HTML::Template->new(filename => 'templates/index.tmpl');

$template->param(userID => $jsonObject->{'user'}{'id'});
$template->param(storeHash => $jsonObject->{'context'});
print $template->output;