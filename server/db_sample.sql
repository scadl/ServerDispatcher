-- phpMyAdmin SQL Dump
-- version 4.2.3
-- http://www.phpmyadmin.net
--
-- Host: localhost:3306
-- Generation Time: Jan 21, 2018 at 12:24 PM
-- Server version: 5.6.17
-- PHP Version: 5.5.13

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;

--
-- Database: `_personal`
--

-- --------------------------------------------------------

--
-- Table structure for table `sd_data`
--

CREATE TABLE IF NOT EXISTS `sd_data` (
`id` int(11) NOT NULL,
  `host` text NOT NULL,
  `proto` text NOT NULL,
  `port` int(11) NOT NULL,
  `state` tinyint(4) NOT NULL
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 AUTO_INCREMENT=4 ;

--
-- Dumping data for table `sd_data`
--

INSERT INTO `sd_data` (`id`, `host`, `proto`, `port`, `state`) VALUES
(1, '127.0.0.1', 'TCP', 80, 0),
(2, '127.0.0.1', 'UDP', 8080, 1),

--
-- Indexes for dumped tables
--

--
-- Indexes for table `sd_data`
--
ALTER TABLE `sd_data`
 ADD PRIMARY KEY (`id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `sd_data`
--
ALTER TABLE `sd_data`
MODIFY `id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=4;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
