#
# Request.pm
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

package Scrape::USPS::ZipLookup::Request;
use strict;

use URI;
use HTTP::Request;
use HTTP::Request::Common;
use LWP::UserAgent;

use vars qw(@ISA);

@ISA = qw(HTTP::Request);

my $form_url  = 'http://www.usps.com/cgi-bin/zip4/zip4inq2';
  

#
# new()
#

sub new
{
  my $class = shift;
  my $self  = bless POST($form_url), $class;

  $self->address(@_);

  return $self;
}


#
# address()
#
# Set the address.
#

sub address
{
  my $self = shift;
  my $addr;

  die "No address given!" unless @_;

  if (ref $_[0] eq 'Scrape::USPS::ZipLookup::Address') {
    $addr = shift;
  } else {
    $addr = Scrape::USPS::ZipLookup::Address->new(@_);
  }

  $self->content($addr->query);

  return;
}


#
# submit()
#
# Submit the request for processing via an instance of LWP::UserAgent.
# If no instance is passed in, then a private one-time instance is
# created and used.
#

sub submit
{
  my $self = shift;
  my $response;

  if (@_) {
    $response = shift->request($self);
  } else {
    $response = LWP::UserAgent->new()->request($self);
  }

  return bless $response, 'Scrape::USPS::ZipLookup::Response';
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

Scrape::USPS::ZipLookup::Request - Standardize U.S. postal addresses.


=head1 SYNOPSIS

  use Scrape::USPS::ZipLookup::Address;
  use Scrape::USPS::ZipLookup::Request;

  my $addr = Scrape::USPS::ZipLookup::Address->new();
  ...
  my $req = Scrape::USPS::ZipLookup::Request->new($addr);
  my $res = $req->submit();
  ...


=head1 DESCRIPTION

This subclass of HTTP::Request is used to form requests of The United
States Postal Service (USPS) HTML form at
C<http://www.usps.com/ncsc/lookups/lookup_zip+4.html> for standardizing
an address.


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

