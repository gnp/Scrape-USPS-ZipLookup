#
# Makefile.PL
#
# [ $Revision: 1.2 $ ]
#
# Copyright (C) 1999-2002 Gregor N. Purdy. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#

use ExtUtils::MakeMaker;

WriteMakefile (
	NAME         => 'Scrape::USPS::ZipLookup',
	VERSION_FROM => 'lib/Scrape/USPS/ZipLookup.pm',
	PREREQ_PM    => {
		HTTP::Request          => 0,
		HTTP::Request::Common  => 0,
		HTTP::Response         => 0,
		LWP::UserAgent         => 0,
        URI                    => 0,
	},
	AUTHOR       => 'Gregor N. Purdy (gregor@focusresearch.com)',
	ABSTRACT     => 'Programmatic interaction with the USPS Zip Code Lookup web application',
	dist         => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' }
);

#
# End of file.
#
