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


print "Content-Type: text/html\n\n";
$query = CGI->new();
$userID = $query->param('userID');
$query->delete('userID');
$currentBatch = $query->param('batchNumber');
$compressionLevel = $query->param('compressionLevel');
$storeHash = $query->param('storeHash');
$query->delete('compressionLevel');
$query->delete('batchNumber');
$query->delete('storeHash');
@names = $query->param;

#grab the information we need to make API calls (could be replaced for cookies?)
$db = "sevillas_imageoptimizer";
$host = "localhost";
$user = "sevillas_admin";
$password = '';
$dbh   = DBI->connect ("DBI:mysql:database=$db:host=$host", $user, $password) or die "Can't connect to database: $DBI::errstr\n";
$selectStatement = "SELECT apiToken FROM authentication WHERE userID = ? AND storeHash = ?";
$statement = $dbh->prepare($selectStatement);
$statement->execute($userID, 'stores/'.$storeHash);

if ($statement->rows > 0) {
    $userAgent = LWP::UserAgent->new;
    ($apiToken) = $statement->fetchrow_array;
    $url = 'https://api.bigcommerce.com/stores/'.$storeHash.'/v2/products/images/';
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
            #incase we want to do a database instead
            $imageSelectStatement = "SELECT optimizedImageURL FROM optimizedImages WHERE imageID = ? AND storeHash = ?";
            $statement = $dbh->prepare($imageSelectStatement);
            $statement->execute($imageID, $storeHash);
            ($optimizedURL) = $statement->fetchrow_array;
            
            #need to make an API call to update the image.
            $update = "{\"image_file\":\"".$optimizedURL."\"}";
            $req = HTTP::Request->new("PUT", $url.$imageID);
            $req->header(@headers);
            $req->content($update);
            $response = $userAgent->request($req);
            
            #now change the database for the apiImages
            $updateAPIImages = "UPDATE optimizedImages SET changedImage = 1 WHERE imageID = ? AND storeHash = ?";
            $statement = $dbh->prepare($updateAPIImages);
            $statement->execute($imageID,$storeHash);
        }
    }
    $countURL = 'https://api.bigcommerce.com/stores/'.$storeHash.'/v2/products/images/count';
    $count = $userAgent->get($countURL,@headers);
    $count = $count->decoded_content();
    $count = decode_json $count;
    $count = $count->{'count'};
    
    #find if it is the max batch
    $findMaxStatement = "SELECT MAX(batchNumber) FROM apiImages WHERE storeHash = ?";
    $findMaxStatement = $dbh->prepare($findMaxStatement);
    $findMaxStatement->execute($storeHash);
    ($maxBatch) = $findMaxStatement->fetchrow_array;
    if ($maxBatch >= $currentBatch + 1) {
        $updateLastPulled = "UPDATE authentication SET lastPagePulled = ? WHERE storeHash = ? AND userID = ?";
        $updateLastPulled = $dbh->prepare($updateLastPulled);
        $currentBatch++;
        $updateLastPulled->execute($currentBatch,'stores/'.$storeHash, $userID);
        $template = HTML::Template->new(filename => 'templates/preview.tmpl');
        $template->param(page => $currentBatch);
        $template->param(storeHash => $storeHash);
        $template->param(storeCount => $count);
        $template->param(compressionLevel => $compressionLevel);
        $template->param(userID => $userID);
        $template->param(checkOptimizedURL => '../imageoptimizer/checkoptimizedimages.pl');
        print $template->output;
    }
    else {
        #finish
        #get total images
        $getTotalImages = "SELECT COUNT(*) FROM optimizedImages WHERE storeHash = ? AND changedImage = 1";
        $getTotalImages = $dbh->prepare($getTotalImages);
        $getTotalImages->execute($storeHash);
        ($totalImages) = $getTotalImages->fetchrow_array;
        
        #amount saved
        $getSums = "SELECT SUM(originalSize), SUM(newSize) FROM optimizedImages WHERE storeHash=? AND changedImage = 1";
        $getSums = $dbh->prepare($getSums);
        $getSums->execute($storeHash);
        ($originalTotal,$compressedTotal) = $getSums->fetchrow_array;
        $amountSaved = $originalTotal - $compressedTotal;
        
        if ($amountSaved > 1024) {
            $amountSaved = sprintf("%.2f", $amountSaved/ 1024);
            if ($amountSaved > 1024) {
                $amountSaved = sprintf("%.2f", $amountSaved/ 1024) . 'MB';
            }
            else {
                $amountSaved .= 'KB';
            }
        }
        else {
            $amountSaved .= 'bytes';
        }
        if ($compressedTotal == 0) {
            $percentage = 0;
        }
        else {
            $percentage = int (($compressedTotal/$originalTotal) * 100);
        }
        
        #check for amount of errors
        $getErrorCount = "SELECT COUNT(*) FROM apiImages WHERE isProcessed = 0 AND storeHash =?";
        $getErrorCount = $dbh->prepare($getErrorCount);
        $getErrorCount->execute($storeHash);
        
        ($errorAmount) = $getErrorCount->fetchrow_array;
        if ($errorAmount > 0) {
            $hasErrors = 1;
        }
        else {
            $hasErrors = 0;
        }
        
        #remove all data
        $updateLastPulled = "UPDATE authentication SET lastPagePulled = ? WHERE storeHash = ? AND userID = ?";
        $updateLastPulled = $dbh->prepare($updateLastPulled);
        $updateLastPulled->execute(1,'stores/'.$storeHash, $userID);
        $deleteApiImages = "DELETE FROM apiImages WHERE storeHash = ?";
        $deleteOptimizedImages = "DELETE FROM optimizedImages WHERE storeHash = ?";
        $deleteApiImages = $dbh->prepare($deleteApiImages);
        $deleteOptimizedImages = $dbh->prepare($deleteOptimizedImages);
        #$deleteOptimizedImages->execute($storeHash);
        #$deleteApiImages->execute($storeHash);
        $template = HTML::Template->new(filename => 'templates/finish.tmpl');
        $template->param(amountSaved => $amountSaved);
        $template->param(percentage => $percentage);
        $template->param(totalImages => $totalImages);
        $template->param(storeHash => $storeHash);
        $template->param(userID => $userID);
        $template->param(hasErrors => $hasErrors);
        print $template->output;
    }
}
else {
    print "Sorry didnt find anything";
    $dbh->disconnect;
}