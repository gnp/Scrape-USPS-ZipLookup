#!/usr/bin/perl -w
#
# standardize.t - Test script.
#
#
# Copyright (C) 1999-2004 Gregor N. Purdy. All rights reserved.
# This program is free software. It is subject to the same license as Perl.
# [ $Revision: 1.5 $ ]
#

use strict;


#
# Read in the tries:
#

my @tries = ( );

while (<DATA>) {
  chomp;

  next if m/^\s*#/; # Skip comment lines.
  next if m/^\s*$/; # Skip blank lines.

  my @address = ( $_ );

  while (<DATA>) {
    chomp;

    last if m/^\s*$/; # Blank line indicates end

    push @address, $_;
  }

  push @tries, [ @address ];
}

if (scalar(@tries) % 2) {
  die "try.pl: There must be an even number of addresses after '__DATA__' since they are used in pairs!\n";
}


#
# Perform the test cases:
#

printf "1..%d\n", 2 + (int(scalar(@tries) / 2));

eval "use Scrape::USPS::ZipLookup;";
print "not " if $@;
print "ok 1 # Importing Scrape::USPS::ZipLookup module\n";
die "Bailing out..." if $@;

my $zlu;
eval { $zlu = Scrape::USPS::ZipLookup->new(); };
print "not " if $@ or not $zlu;
print "ok 2 # Allocating a Scrape::USPS::ZipLookup instance\n";
die "Bailing out..." if $@ or not $zlu;

#$zlu->verbose(1);

my $i = 2;
my $failed = 0;

while (@tries) {
  my @in  = @{shift(@tries)};
  my @out = @{shift(@tries)};

  $i++;

  my @result = $zlu->std_addr(@in);

  if ($out[0] eq '<error>') {
    if (@result) {
      print 'not ';
      $failed++;
    }
  } else {
    if (@result) {
      my $expected = join("\n", @out);
      my $received = $result[0]->to_string;
      if ($expected ne $received) {
        print "  EXPECTED: $expected\n";
        print "  RECEIVED: $received\n";
        print 'not ';
        $failed++;
      }
    }
    else {
      print 'not ';
      $failed++;
    }
  }

  printf "ok %d\n", $i;
}


exit $failed;

#
# End of file.
#

__DATA__

###############################################################################

bar
splee
OH

<error>

###############################################################################

6216 Eddington Drive
Liberty Township
oh

6216 EDDINGTON ST
LIBERTY TOWNSHIP
OH
45044-9761

###############################################################################

3303 Pine Meadow DR SE #202
Kentwood
MI
49512

3303 PINE MEADOW DR SE APT 202
KENTWOOD
MI
49512-8325

###############################################################################

2701 DOUGLAS AVE
DES MOINES
IA
50310

2701 DOUGLAS AVE
DES MOINES
IA
50310-5840

###############################################################################

