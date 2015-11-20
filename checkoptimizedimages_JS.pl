#!/usr/bin/perl
use cPanelUserConfig;

use CGI qw(:standard);
use LWP::UserAgent;
use JSON qw( decode_json );
use DBI;
use HTML::Template;

$query = CGI->new();

$page = $query->param('page');
$hash = $query->param('hash');

$db = "sevillas_imageoptimizer";
$host = "localhost";
$user = "sevillas_admin";
$password = '';
$dbh = DBI->connect ("DBI:mysql:database=$db:host=$host", $user, $password) or die "Can't connect to database: $DBI::errstr\n";
$selectStatement = "SELECT imageID, originalImageURL, optimizedImageURL, originalSize, newSize FROM optimizedImages WHERE pageNumber = ? AND storeHash = ? AND isSent = 0";
$updateIsSent = "UPDATE optimizedImages SET isSent = 1 WHERE storeHash = ? AND imageID = ?";
$updateIsSent = $dbh->prepare($updateIsSent);
$statement = $dbh->prepare($selectStatement);
$statement->execute($page, $hash);
print "Content-Type: text/html\n";
print 'Access-Control-Allow-Origin: *'."\n\n";

while (@row = $statement->fetchrow_array) {
    #the HTML code
    $row[1] =~ /.*\/(.*?)\.(.*)/;
    ($filename, $ext) = ($1,$2);
    print '<h3>'.$filename.'.'.$ext.'</h3>';
    print '<div class="preview">';
    print '    <div><img src="'.$row[1].'"></div>';
    print '    <div class="imgData">';
    print '        <span class="glyphicon glyphicon-download" aria-hidden="true"></span>';
    print '        <p> Original Image - '.$row[3].' bytes</p>';
    print '    </div>';
    print '</div>';
    print '<div class="preview">';
    print '    <div><img src="'.$row[2].'"></div>';
    print '    <div class="imgData"><p> Optimized Image - '.$row[4].' bytes</p></div>';
    print '</div>';
    print '<div class ="options">';
    print '    <div class="radio">';
    print '        <label>';
    print '            <input type="radio" name="userOption-'.$row[0].'" id="oldImg" value="oldImg">';
    print '            Keep original image.';
    print '        </label>';
    print '    </div>';
    print '    <div class="radio">';
    print '        <label>';
    print '            <input type="radio" name="userOption-'.$row[0].'" id="newImg" value="newImg">';
    print '            Apply optimized image.';
    print '        </label>';
    print '    </div>';
    print '</div>';
    $updateIsSent->execute($hash, $row[0]);
}

$checkAttempted = "SELECT COUNT(*) FROM apiImages WHERE attempted = 0 AND batchNumber = ? AND storeHash = ?";
$checkAttempted = $dbh->prepare($checkAttempted);
$checkAttempted->execute($page,$hash);
($totalCount) = $checkAttempted->fetchrow_array;
if ($totalCount == 0) {
        print '<input class="btn btn-default" id="submitbutton" type="submit" value="Apply Selected Changes">';
    }