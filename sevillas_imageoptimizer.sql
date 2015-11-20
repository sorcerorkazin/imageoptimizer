-- phpMyAdmin SQL Dump
-- version 4.0.10.7
-- http://www.phpmyadmin.net
--
-- Host: localhost:3306
-- Generation Time: Nov 19, 2015 at 07:06 PM
-- Server version: 5.5.42-cll-lve
-- PHP Version: 5.4.31

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;

--
-- Database: `sevillas_imageoptimizer`
--

-- --------------------------------------------------------

--
-- Table structure for table `activeSessions`
--

CREATE TABLE IF NOT EXISTS `activeSessions` (
  `userID` int(11) NOT NULL,
  `pageNumber` int(11) NOT NULL,
  `batchNumber` int(11) NOT NULL,
  `storeHash` text NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `apiImages`
--

CREATE TABLE IF NOT EXISTS `apiImages` (
  `isProcessed` tinyint(1) NOT NULL,
  `batchNumber` int(11) NOT NULL,
  `productID` int(11) NOT NULL,
  `imageID` int(11) NOT NULL,
  `imageURL` text NOT NULL,
  `storeHash` text NOT NULL,
  `attempted` int(11) NOT NULL,
  `errorMessage` text NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `authentication`
--

CREATE TABLE IF NOT EXISTS `authentication` (
  `userID` int(11) NOT NULL,
  `userEmail` text NOT NULL,
  `apiToken` text NOT NULL,
  `overallSizeSaved` int(11) NOT NULL,
  `lastImgID` int(11) NOT NULL,
  `storeHash` text NOT NULL,
  `lastPagePulled` int(11) NOT NULL DEFAULT '1',
  `compressionLevel` int(11) NOT NULL DEFAULT '0',
  KEY `userID` (`userID`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `optimizedImages`
--

CREATE TABLE IF NOT EXISTS `optimizedImages` (
  `imageID` int(11) NOT NULL,
  `originalImageURL` text NOT NULL,
  `optimizedImageURL` text NOT NULL,
  `pageNumber` int(11) NOT NULL,
  `storeHash` text NOT NULL,
  `originalSize` int(11) NOT NULL,
  `newSize` int(11) NOT NULL,
  `changedImage` tinyint(1) NOT NULL DEFAULT '0',
  `isSent` tinyint(1) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
