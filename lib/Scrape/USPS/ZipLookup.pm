#
# ZipLookup.pm
#
# [ $Revision: 1.5 $ ]
#
# Perl 5 module to standardize U.S. postal addresses by referencing
# the U.S. Postal Service's web site:
#
#     http://www.usps.com/ncsc/lookups/lookup_zip+4.html
#
# BE SURE TO READ AND UNDERSTAND THE TERMS OF USE SECTION IN THE
# DOCUMENTATION, WHICH MAY BE FOUND AT THE END OF THIS SOURCE CODE.
#
# Copyright (C) 1999-2002 Gregor N. Purdy. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#

package Scrape::USPS::ZipLookup;
use strict;

use vars qw($VERSION);
$VERSION = '1.1';

use LWP::UserAgent;

use Scrape::USPS::ZipLookup::Request;
use Scrape::USPS::ZipLookup::Response;


#
# new()
#

sub new
{
  my $class = shift;
  my $self = bless {
    USER_AGENT => LWP::UserAgent->new(),
    VERBOSE    => 0,
  }, $class;

  return $self;
}


#
# user_agent()
#

sub user_agent
{
  my $self = shift;

  return $self->{USER_AGENT};
}


#
# verbose()
#

sub verbose
{
  my $self = shift;

  if (@_) {
    $self->{VERBOSE} = $_[0];
    return $_[0];
  } else {
    return $self->{VERBOSE};
  }
}


#
# std_inner()
#
# The inner portion of the process, so it can be shared by
# std_addr() and std_addrs().
#

sub std_inner
{
  my $self = shift;

  my $addr = Scrape::USPS::ZipLookup::Address->new(@_);

  if ($self->verbose) {
    print ' ', '_' x 77, ' ',  "\n";
    print '/', ' ' x 77, '\\', "\n";
    print "THE INPUT WAS:\n";
    print "$addr\n";
  }

  my $req = Scrape::USPS::ZipLookup::Request->new($addr);

  if ($self->verbose) {
    print "-" x 79, "\n";
    print "THE REQUEST WAS:\n";
    print $req->content, "\n";
  }

  my $res = $req->submit($self->user_agent);

  die $res->error_as_HTML unless $res->is_success;

  if ($self->verbose) {
    print "-" x 79, "\n";
    print "THE RESPONSE WAS:\n";
    print ref $res, ":\n";
    print $res->content;
  }

  my $match = $res->first_match();

  print "-" x 79, "\n" if $self->verbose;

  if ($match) {
    if ($self->verbose) {
      print "THE OUTPUT WAS:\n";
      print "$match\n";
    }
  } else {
    print "THERE WAS NO OUTPUT (ERROR).\n" if $self->verbose;
  }

  print '\\', '_' x 77, '/',  "\n" if $self->verbose;

  if ($match) {
    return $match->to_array;
  } else {
    return;
  }
}


#
# std_addr()
#

sub std_addr
{
  my $self = shift;

  return $self->std_inner(@_);
}


#
# std_addrs()
#

sub std_addrs
{
  my $self = shift;

  my @result;

  foreach my $addr (@_) {
    my @addr = $self->std_inner(@$addr);

    push @result, [ @addr ];
  }

  return @result;
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

Scrape::USPS::ZipLookup - Standardize U.S. postal addresses.

=head1 SYNOPSIS

Use the old interface based on Data::Address::Standardize module:

  use Scrape::USPS::ZipLookup;
  my $zlu = Scrape::USPS::ZipLookup->new();
  ($street, $city, $state, $zip) = $zlu->std_addr($street, $city, $state, $zip);

or,

  use Scrape::USPS::ZipLookup;
  my $zlu = Scrape::USPS::ZipLookup->new();
  # Read in a pipe-delimited data set like a filter.
  while(<>) {
      chomp;
      my @addr = split('\|');
      push @addr_list, [ @addr ];
  }
  my @std_list = $zlu->std_addrs(@addr_list);
  # Write a pipe-delimited data set to standard output.
  foreach (@std_list) {
      print join('|', @$_), "\n";
  }

Or, use the new interface:

  use Scrape::USPS::ZipLookup::Address;
  use Scrape::USPS::ZipLookup;

  my $addr = Scrape::USPS::ZipLookup::Address->new(
    'Firm'             => 'Focus Research, Inc.',
    'Urbanization'     => '',
    'Delivery Address' => '8080 Beckett Center Drive Suite 203',
    'City'             => 'West Chester',
    'State'            => 'OH',
    'ZIP Code'         => '45069-5001'
  );

  my $zlu = Scrape::USPS::ZipLookup->new();

  my @matches = $zlu->lookup($addr);

  die "No matches!" unless @matches;


=head1 DESCRIPTION

The United States Postal Service (USPS) has on its web site an HTML form at
C<http://www.usps.com/ncsc/lookups/lookup_zip+4.html>
for standardizing an address. Given a firm, urbanization, street address,
city, state, and zip, it will put the address into standard form (provided
the address is in their database) and display a page with the resulting
address.

This Perl module provides a programmatic interface to this service, so you
can write a program to process your entire personal address book without
having to manually type them all in to the form.

Because the USPS could change or remove this functionality at any time,
be prepared for the possibility that this code may fail to function. In
fact, as of this version, there is no error checking in place, so if they
do change things, this code will most likely fail in a noisy way. If you
discover that the service has changed, please email the author your findings.

If an error occurs in trying to standardize the address, then no array
will be returned. Otherwise, a four-element array will be returned.

To see debugging output, call C<$zlu-E<gt>verbose(1)>.


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

