#
# ZipLookup.pm
#
# Perl 5 module to standardize U.S. postal addresses by referencing
# the U.S. Postal Service's web site:
#
#     http://www.usps.com/zip4/
#
# BE SURE TO READ, UNDERSTAND, AND ABIDE BY THE TERMS OF USE FOR THE
# USPS WEB SITE. LINKS ARE PROVIDED IN THE TERMS OF USE SECTION IN THE
# DOCUMENTATION OF THIS PROGRAM, WHICH MAY BE FOUND AT THE END OF THIS
# SOURCE CODE FILE.
#
# Copyright (C) 1999-2004 Gregor N. Purdy. All rights reserved.
# This program is free software. It is subject to the same license as Perl.
# [ $Revision: 1.8 $ ]
#

package Scrape::USPS::ZipLookup;

use strict;
use warnings;

our $VERSION = '2.3';

use WWW::Mechanize;         # To communicate with USPS and get HTML

use Scrape::USPS::ZipLookup::Address;

my $start_url = 'http://zip4.usps.com/zip4/welcome.jsp';
my $form_id   = 'frmzip';


#
# new()
#

sub new
{
  my $class = shift;
  my $self = bless {
    USER_AGENT => WWW::Mechanize->new(agent => ''),
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

  #
  # Turn the input into an Address instance:
  #

  my $addr = Scrape::USPS::ZipLookup::Address->new(@_);

  if ($self->verbose) {
    print ' ', '_' x 77, ' ',  "\n";
    print '/', ' ' x 77, '\\', "\n";
    $addr->dump("Input");
    print "\n";
  }

  #
  # Submit the form to the USPS web server:
  #
  # Unless we are in verbose mode, we make the WWW::Mechanize user agent be
  # quiet. At the time this was written [2003-01-28], it generates a warning
  # about the "address" form field being read-only if its not in quiet mode.
  #
  # We set the form's Selection field to "1" to indicate that we are doing
  # regular zip code lookup.
  #

  my $agent = $self->user_agent;
  $agent->quiet(not $self->verbose);

  my $response = $agent->get($start_url);

  die "Error communicating with server" unless $response;

  my $content = $agent->{content};

  if ($self->verbose) {
    print "-" x 79, "\n";
    print "Initial Page HTTP Response:\n";
    print $response->as_string;
  }

  $agent->form($form_id);

  $agent->field(Selection => 1);

  { # TODO: Stupid hack because HTML::Form does a Carp::carp when we set this!
    no strict;
    no warnings;
    open SAVE_STDERR, ">&STDERR";
    close STDERR;
    $agent->field(address   => uc $addr->delivery_address);
    $agent->field(address1  => uc $addr->delivery_address);
    open STDERR, ">&SAVE_STDERR";
  }

  $agent->field(city      => uc $addr->city);
  $agent->field(state     => uc $addr->state);
  $agent->field(zipcode   => uc $addr->zip_code);

  $response = $agent->click; # An HTTP::Response instance

#
# NOTE 2003-12-12: Can't do anymore. req() method is gone in 0.7 WWW::Mechanize!
#  if ($self->verbose) {
#    print "-" x 79, "\n";
#    print "HTTP Request:\n";
#    print $agent->req->as_string;
#  }
#

  die "Error communicating with server" unless $response;

  $content = $agent->{content};

  if ($self->verbose) {
    print "-" x 79, "\n";
    print "HTTP Response:\n";
    print $response->as_string;
  }

  #
  # Time to Parse:
  #
  # The results look like this:
  #
  #   <td width="312" background="images/light_blue_bg2.gif" class="mainText">6216 EDDINGTON ST <br>LIBERTY TOWNSHIP&nbsp;OH&nbsp;45044-9761 <br>
  #
  # 1. We find <td header ...> ... </td> to find the data fields.
  # 2. We strip out <font> and <a>
  # 3. We replace &nbsp; with space
  # 4. We strip out leading "...: "
  # 5. We find <!--< ... />--> to get the field id
  # 6. We standardize the field id (upper case, alpha only)
  # 7. We standardize the value (trimming and whitespace coalescing)
  #
  # We end up with something like this:
  #
  #   ADDRESSLINE:  6216 EDDINGTON ST
  #   CITYSTATEZIP: LIBERTY TOWNSHIP OH  45044-9761
  #   CARRIERROUTE: R007
  #   COUNTY: BUTLER
  #   DELIVERYPOINT: 16
  #   CHECKDIGIT: 3
  #

  my @matches;

  my @raw_matches = map { trim($_) } $content =~ m{<td\s+[^>]*background=['"]images/light_blue_bg2.gif['"][^>]*class="mainText"[^>]*>(.*?)</td>}gsi;

  foreach my $raw_match (@raw_matches) {
    my $carrier_route  = undef;
    my $county         = undef;
    my $delivery_point = undef;
    my $check_digit    = undef;

#    if ($cell =~ m/mail_info_pop2.jsp\?carrier=(\w*)&county=(\w*)&dpoint=(\w*)&cdigit=(\w*)&lac=&elot=0176&elotind=A&rectype=S&pmbdes=&pmbnum=&dflag=&ews="

    if ($raw_match =~ m/mail_info_pop2.jsp\?carrier=(\w*)&county=(\w*)&dpoint=(\w*)&cdigit=(\w*)/i) {
      $carrier_route  = $1;
      $county         = $2;
      $delivery_point = $3;
      $check_digit    = $4;
    }

    $raw_match =~ s{</?font.*?>}{}g;
    $raw_match =~ s{</?span.*?>}{}g;
    $raw_match =~ s{</?a.*?>}{}g;
    $raw_match =~ s{&nbsp;}{ }g;
    $raw_match =~ s{^.*?:\s*}{}g;
    $raw_match =~ s{<!--<(.*?)/>-->}{}g;

    my ($address, $city_state_zip) = split( /\s*<br\s*\/?>\s*/, $raw_match);

    next unless $city_state_zip;
    next unless ($city_state_zip =~ m/^(.*)\s+(\w\w)\s+(\d{5}(-\d{4})?)/);

    my ($city, $state, $zip) = ($1, $2, $3);

#    print("-" x 70, "\n");
#    print "Address:        $address\n";
#    print "City:           $city\n";
#    print "State:          $state\n";
#    print "Zip:            $zip\n";
#    print "Carrier Route:  $carrier_route\n";
#    print "County:         $county\n";
#    print "Delivery Point: $delivery_point\n";
#    print "Check Digit:    $check_digit\n";
#    print "\n";

    my $match = Scrape::USPS::ZipLookup::Address->new($address, $city, $state, $zip);

    $match->carrier_route($carrier_route);
    $match->county($county);
    $match->delivery_point($delivery_point);
    $match->check_digit($check_digit);

    push @matches, $match;
  }

  print('\\', '_' x 77, '/', "\n") if $self->verbose;

  return @matches;
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
# trim()
#
# A purely internal utility subroutine.
#

sub trim
{
  my $string = shift;
  $string =~ s/\x{a0}/ /sg;   # Remove this odd character.
  $string =~ s/^\s+//s;       # Trim leading whitespace.
  $string =~ s/\s+$//s;       # Trim trailing whitespace.
  $string =~ s/\s+/ /sg;      # Coalesce interior whitespace.
  return $string;
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
  
  #!/usr/bin/perl
  
  use Scrape::USPS::ZipLookup::Address;
  use Scrape::USPS::ZipLookup;
  
  my $addr = Scrape::USPS::ZipLookup::Address->new(
    'Focus Research, Inc.',                # Firm
    '',                                    # Urbanization
    '8080 Beckett Center Drive Suite 203', # Delivery Address
    'West Chester',                        # City
    'OH',                                  # State
    '45069-5001'                           # ZIP Code
  );
  
  my $zlu = Scrape::USPS::ZipLookup->new();
  
  my @matches = $zlu->std_addr($addr);
  
  if (@matches) {
    printf "\n%d matches:\n", scalar(@matches);
    foreach my $match (@matches) {
      print "-" x 39, "\n";
      print $match->to_string;
      print "\n";
    }
    print "-" x 39, "\n";
  }
  else {
    print "No matches!\n";
  }
  
  exit 0;


=head1 DESCRIPTION

The United States Postal Service (USPS) has on its web site an HTML form at
C<http://www.usps.com/zip4/>
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

To see debugging output, call C<< $zlu->verbose(1) >>.


=head1 TERMS OF USE

BE SURE TO READ AND FOLLOW THE UNITED STATES POSTAL SERVICE TERMS OF USE
PAGE (AT C<http://www.usps.com/homearea/docs/termsofuse.htm> AT THE TIME
THIS TEXT WAS WRITTEN). IN PARTICULAR, NOTE THAT THEY
DO NOT PERMIT THE USE OF THEIR WEB SITE'S FUNCTIONALITY FOR COMMERCIAL
PURPOSES. DO NOT USE THIS CODE IN A WAY THAT VIOLATES THE TERMS OF USE.

The author believes that the example usage given above does not violate
these terms, but sole responsibility for conforming to the terms of use
belongs to the user of this code, not the author.


=head1 AUTHOR

Gregor N. Purdy, C<gregor@focusresearch.com>.


=head1 COPYRIGHT

Copyright (C) 1999-2004 Gregor N. Purdy. All rights reserved.

This program is free software. It is subject to the same license as Perl.

=cut


#
# End of file.
#

