#!/usr/bin/perl -w
#
# standardize.t - Test script.
#
# [ $Revision: 1.1 $ ]
#

use strict;
use Data::Address::Standardize;

Data::Address::Standardize::verbose(1);


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

printf "1..%d\n", int(scalar(@tries) / 2);

my $i;
my $failed = 0;


while (@tries) {
  my @in  = @{shift(@tries)};
  my @out = @{shift(@tries)};

  $i++;

  my @result = std_addr(@in);

  if ($out[0] eq '<error>') {
    if (@result) {
      print 'not ';
      $failed++;
    }
  } else {
    if (join("\n", @out) ne join("\n", @result)) {
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

foo bar
splee
quux

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

(ODD Range 2701 - 2799) DOUGLAS AVE
DES MOINES
IA
50310-5840

###############################################################################

