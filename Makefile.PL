#
# Makefile.PL
#
#
# Copyright (C) 1999-2003 Gregor N. Purdy. All rights reserved.
# This program is free software. It is subject to the same license as Perl.
# [ $Revision: 1.3 $ ]
#

use ExtUtils::MakeMaker;

WriteMakefile (
  NAME         => 'Scrape::USPS::ZipLookup',
  VERSION_FROM => 'lib/Scrape/USPS/ZipLookup.pm',
  PREREQ_PM    => {
    WWW::Mechanize         => 0.35, # To communicate with USPS and get HTML
    XML::Driver::HTML      => 0.06, # To generate SAX events from HTML
    XML::Handler::YAWriter => 0.23, # To generate XML from SAX events
    XML::XPath             => 1.12, # To extract addresses from XML
  },
  AUTHOR       => 'Gregor N. Purdy (gregor@focusresearch.com)',
  ABSTRACT     => 'Programmatic interaction with the USPS Zip Code Lookup web application',
  dist         => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' }
);

#
# End of file.
#
