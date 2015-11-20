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
print "Content-Type: application/json\n";
print 'Access-Control-Allow-Origin: *'."\n\n";

$response = '{"content": "';

while (@row = $statement->fetchrow_array) {
    #the HTML code
    $row[1] =~ /.*\/(.*?)\.(.*)/;
    ($filename, $ext) = ($1,$2);
    #calculate bytes to KB or MB or GB?
    $oldImageSize = $row[3];
    $newImageSize = $row[4];
    
    if ($oldImageSize > 1024) {
        $oldImageSize = sprintf("%.2f", $oldImageSize/ 1024);
        if ($oldImageSize > 1024) {
            $oldImageSize = sprintf("%.2f", $oldImageSize/ 1024) . 'MB';
        }
        else {
            $oldImageSize .= 'KB';
        }
    }
    if ($newImageSize > 1024) {
        $newImageSize = sprintf("%.2f", $newImageSize/ 1024);
        if ($newImageSize > 1024) {
            $newImageSize = sprintf("%.2f", $newImageSize/ 1024) . 'MB';
        }
        else {
            $newImageSize .= 'KB';
        }
    }
    $fullFileName = $filename.$ext;
    
    $response .= '<h3>'.$filename.'.'.$ext.'</h3>';
    $response .= '<div class=\"preview\">';
    $response .= '    <div id=\"oldImage\"><img src=\"'.$row[1].'\"></div>';
    $response .= '    <div class=\"imgData\">';
    $response .= '        <a href=\"'.$row[1].'\" download=\"'.$fullFileName.'\"><span class=\"glyphicon glyphicon-download\" aria-hidden=\"true\"></span></a>';
    $response .= '        <p> Original Image - '.$oldImageSize.'</p>';
    $response .= '    </div>';
    $response .= '</div>';
    $response .= '<div class=\"preview\">';
    $response .= '    <div id=\"newImage\"><img src=\"'.$row[2].'\"></div>';
    $response .= '    <div class=\"imgData optimized\"><p> Optimized Image - '.$newImageSize.'</p></div>';
    $response .= '</div>';
    $response .= '<div class =\"options\">';
    $response .= '    <div class=\"radio\">';
    $response .= '        <label>';
    $response .= '            <input type=\"radio\" name=\"userOption-'.$row[0].'\" id=\"oldImg\" value=\"oldImg\" checked=\"checked\">';
    $response .= '            Keep original image.';
    $response .= '        </label>';
    $response .= '    </div>';
    $response .= '    <div class=\"radio\">';
    $response .= '        <label>';
    $response .= '            <input type=\"radio\" name=\"userOption-'.$row[0].'\" id=\"newImg\" value=\"newImg\">';
    $response .= '            Apply optimized image.';
    $response .= '        </label>';
    $response .= '    </div>';
    $response .= '</div>';
    $updateIsSent->execute($hash, $row[0]);
}


$checkAttempted = "SELECT COUNT(*) FROM apiImages WHERE attempted = 0 AND batchNumber = ? AND storeHash = ?";
$checkAttempted = $dbh->prepare($checkAttempted);
$checkAttempted->execute($page,$hash);
($totalCount) = $checkAttempted->fetchrow_array;

$checkCurrentProcessed = "SELECT COUNT(*) FROM optimizedImages WHERE isSent = 1 AND pageNumber <= ? AND storeHash = ?";
$checkCurrentProcessed = $dbh->prepare($checkCurrentProcessed);
$checkCurrentProcessed->execute($page, $hash);
($processedCount) = $checkCurrentProcessed->fetchrow_array;

if ($totalCount == 0) {
        $response .= '<input class=\"btn btn-default\" id=\"submitbutton\" type=\"submit\" value=\"Apply Selected Changes\">';
       
}
$response .= '", "count":'.$processedCount.'}';
print $response;