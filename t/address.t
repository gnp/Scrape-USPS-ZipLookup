#!/usr/bin/perl -w
#
# address.t
#
# [ $Revision: 1.1 $ ]
#

use strict;

BEGIN {
  print "1..5\n";
}

use Scrape::USPS::ZipLookup::Address;

my @value = (
  '',
  '',
  '8080 Beckett Center Drive Suite 203',
  'West Chester',
  'OH',
  '45069-5001'
);

my @correct = (
  '',
  'Firm=&Urbanization=&Delivery+Address=&City=&State=&Zip+Code=',
  'Firm=&Urbanization=&Delivery+Address=8080+Beckett+Center+Drive+Suite+203&City=&State=&Zip+Code=',
  'Firm=&Urbanization=&Delivery+Address=8080+Beckett+Center+Drive+Suite+203&City=West+Chester&State=&Zip+Code=',
  'Firm=&Urbanization=&Delivery+Address=8080+Beckett+Center+Drive+Suite+203&City=West+Chester&State=OH&Zip+Code=',
  'Firm=&Urbanization=&Delivery+Address=8080+Beckett+Center+Drive+Suite+203&City=West+Chester&State=OH&Zip+Code=45069-5001'
);

my $addr = Scrape::USPS::ZipLookup::Address->new();
print "not " unless $addr->query eq $correct[1];
print "ok 1\n";

$addr->delivery_address($value[2]);
print "not " unless $addr->query eq $correct[2] and $addr->delivery_address eq $value[2];
print "ok 2\n";

$addr->city($value[3]);
print "not " unless $addr->query eq $correct[3] and $addr->city eq $value[3];
print "ok 3\n";

$addr->state($value[4]);
print "not " unless $addr->query eq $correct[4] and $addr->state eq $value[4];
print "ok 4\n";

$addr->zip_code($value[5]);
print "not " unless $addr->query eq $correct[5] and $addr->zip_code eq $value[5];
print "ok 5\n";

exit 0;

#
# End of file.
#
