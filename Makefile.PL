#
# Makefile.PL
#
# Copyright (C) 1999-2003 Gregor N. Purdy. All rights reserved.
# This program is free software. It is subject to the same license as Perl.
#
# [ $Revision: 1.4 $ ]
#

use ExtUtils::MakeMaker;

WriteMakefile (
  NAME         => 'Scrape::USPS::ZipLookup',
  VERSION_FROM => 'lib/Scrape/USPS/ZipLookup.pm',
  PREREQ_PM    => {
    WWW::Mechanize         => 0.70, # To communicate with USPS and get HTML
  },
  EXE_FILES    => [
    'script/stdaddr'
  ],
  AUTHOR       => 'Gregor N. Purdy (gregor@focusresearch.com)',
  ABSTRACT     => 'Programmatic interaction with the USPS Zip Code Lookup web application',
  dist         => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' }
);

#
# End of file.
#
