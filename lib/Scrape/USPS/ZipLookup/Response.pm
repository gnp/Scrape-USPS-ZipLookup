#
# Response.pm
#
# [ $Revision: 1.3 $ ]
#
# Perl 5 module to standardize U.S. postal addresses by referencing
# the U.S. Postal Service's web site:
#
#     http://www.usps.com/ncsc/lookups/lookup_zip+4.html'
#
# BE SURE TO READ AND UNDERSTAND THE TERMS OF USE SECTION IN THE
# DOCUMENTATION, WHICH MAY BE FOUND AT THE END OF THIS SOURCE CODE.
#
# Copyright (C) 1999-2002 Gregor N. Purdy. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#

package Scrape::USPS::ZipLookup::Response;
use strict;

use HTTP::Response;
use vars qw(@ISA);
@ISA = qw(HTTP::Response);

use Scrape::USPS::ZipLookup::Address;


#
# matches()
#
# Output: One Scrape::USPS::ZipLookup::Address object for each
#         address returned.
#

sub matches
{
  my $self = shift;
  my $addr = $self->content;

  return unless ($addr =~ m/The standardized address is:/sm);

  #
  # First, chop out all the lines preceding and following the
  # addresses:
  #

  $addr =~ s/^.*The standardized address is:<p>(.*)<HR><center>.*$/$1/sm;

  #
  # Now, split  on <HR>
  #

  my @addrs = split(/<HR>/sm, $addr);
  my @output;

  foreach (@addrs) {
    push @output, Scrape::USPS::ZipLookup::Address->new_html($_);
  }

  return @output;
}


#
# first_match()
#

sub first_match
{
  my $self  = shift;
  my @addrs = $self->matches;

  return unless @addrs;

  return shift @addrs;
}


#
# Proper module termination:
#

1;

__END__

#
# Documentation:
#

=pod

=head1 NAME

Scrape::USPS::ZipLookup::Response - Standardize U.S. postal addresses.

=head1 SYNOPSIS

  use Scrape::USPS::ZipLookup::Request;
  use Scrape::USPS::ZipLookup::Response;

  my $req = Scrape::USPS::ZipLookup::Request->new();

  ...

  my $res = $req->submit();

  my @matches = $res->matches();


=head1 DESCRIPTION

Used to parse an HTML response to a request made via 
The United States Postal Service (USPS) HTML form at
C<http://www.usps.com/ncsc/lookups/lookup_zip+4.html>
for standardizing an address.


=head1 TERMS OF USE

BE SURE TO READ AND FOLLOW THE UNITED STATES POSTAL SERVICE TERMS OF USE
PAGE AT C<http://www.usps.com/disclaimer.html>. IN PARTICULAR, NOTE THAT THEY
DO NOT PERMIT THE USE OF THEIR WEB SITE'S FUNCTIONALITY FOR COMMERCIAL
PURPOSES. DO NOT USE THIS CODE IN A WAY THAT VIOLATES THE TERMS OF USE.

The author believes that the example usage given above does not violate
these terms, but sole responsibility for conforming to the terms of use
belongs to the user of this code, not the author.


=head1 AUTHOR

Gregor N. Purdy, C<gregor@focusresearch.com>.


=head1 COPYRIGHT

Copyright (C) 1999-2002 Gregor N. Purdy. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut


#
# End of file.
#

