#!/usr/bin/perl -w
#
# address.t
#
#
# Copyright (C) 1999-2004 Gregor N. Purdy. All rights reserved.
# This program is free software. It is subject to the same license as Perl.
# [ $Revision: 1.3 $ ]
#

use strict;

BEGIN {
  print "1..1\n";
}

eval "use Scrape::USPS::ZipLookup::Address;";

print "not " if $@;
print "ok 1\n";

exit 0;

#
# End of file.
#
