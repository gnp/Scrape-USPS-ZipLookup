#
# ZipLookup.pm
#
# Perl 5 module to standardize U.S. postal addresses by referencing
# the U.S. Postal Service's web site:
#
#     http://www.usps.com/ncsc/lookups/lookup_zip+4.html
#
# BE SURE TO READ AND UNDERSTAND THE TERMS OF USE SECTION IN THE
# DOCUMENTATION, WHICH MAY BE FOUND AT THE END OF THIS SOURCE CODE.
#
#
# Copyright (C) 1999-2003 Gregor N. Purdy. All rights reserved.
# This program is free software. It is subject to the same license as Perl.
# [ $Revision: 1.6 $ ]
#

package Scrape::USPS::ZipLookup;

use strict;
use warnings;

our $VERSION = '2.0';

use WWW::Mechanize;         # To communicate with USPS and get HTML
use XML::Driver::HTML;      # To generate SAX events from HTML
use XML::Handler::YAWriter; # To generate XML from SAX events
use XML::XPath;             # To extract information from XML

use Scrape::USPS::ZipLookup::Address;

my $start_url = 'http://www.usps.com/zip4/';


#
# new()
#

sub new
{
  my $class = shift;
  my $self = bless {
    USER_AGENT => WWW::Mechanize->new,
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
  # about the "address" form field being read-only if its not it quiet mode.
  #
  # We set the form's Selection field to "1" to indicate that we are doing
  # regular zip code lookup.
  #

  my $agent = $self->user_agent;
  $agent->quiet(not $self->verbose);

  $agent->get($start_url);
  $agent->form(1); # The first form on the page is the one we'll fill out.

  $agent->field(Selection => 1);
  $agent->field(address   => uc $addr->delivery_address);
  $agent->field(city      => uc $addr->city);
  $agent->field(state     => uc $addr->state);
  $agent->field(zipcode   => uc $addr->zip_code);

  my $response = $agent->click; # An HTTP::Response instance

  if ($self->verbose) {
    print "-" x 79, "\n";
    print "HTTP Request:\n";
    print $agent->req->as_string;
  }

  die "Error communicating with server" unless $response;

  my $content = $agent->{content};

#  if ($self->verbose) {
#    print "-" x 79, "\n";
#    print "HTTP Response:\n";
#    print $response->as_string;
#  }

  #
  # Convert the HTML result into XML:
  #
  # We use the Encoding "ISO-8859-1" because we were getting strange character
  # problems when we didn't specify it, or used "UTF-8".
  #

  my $ya = new XML::Handler::YAWriter( 
    AsString => 1,
    Pretty   => {
      NoWhiteSpace       => 1,
      NoComments         => 1,
      PrettyWhiteIndent  => 1,
      PrettyWhiteNewline => 1,
    },
  );

  my $html = new XML::Driver::HTML(
    Handler => $ya,
    Source  => {
      String             => $content,
      Encoding           => 'ISO-8859-1',
    }
  );
    
  my $in_xml = $html->parse();

  if ($self->verbose) {
    print "-" x 79, "\n";
    print "Response as XML:\n";
    print $in_xml;
  }

  #
  # Use XPath to extract the result addresses:
  #
  # Of course, this is the fragile part of the code. These XPath expressions
  # work great right now (2003-01-28), but there is no guarantee they will
  # continue to work well going forward, but that is the cost (risk) of
  # scraping a service not under our control.
  #
  # We'd rather pass in the XML::Driver::HTML instance. Above we convert an
  # HTML string to an XML string by parsing and re-rendering. Now, we are
  # going to parse the XML string again.
  #

  my @matches;

  my $xp = XML::XPath->new(xml => $in_xml);

  my $main_path = "/html/body/table[2]/tr[3]/td[3]/table[2]/tr[1]/td[1]/table[2]/tr";
  my $nodeset   = $xp->find($main_path); # Find all addresses

  foreach my $node ($nodeset->get_nodelist) {
#    my @foo_nodes      = $xp->findnodes('td[1]/table[1]/tr[1]', $node);
    my @addr_nodes     = $xp->findnodes('td[1]/table[1]/tr[2]', $node);
    my @city_nodes     = $xp->findnodes('td[1]/table[1]/tr[3]', $node);

    my @route_nodes    = $xp->findnodes('td[2]/table[1]/tr[1]', $node);
    my @county_nodes   = $xp->findnodes('td[2]/table[1]/tr[2]', $node);
    my @delivery_nodes = $xp->findnodes('td[2]/table[1]/tr[3]', $node);
    my @check_nodes    = $xp->findnodes('td[2]/table[1]/tr[4]', $node);
#    my @bar_nodes      = $xp->findnodes('td[2]/table[1]/tr[5]', $node);

    #
    # Check and parse the address result:
    #

    next unless @addr_nodes;
    next unless @city_nodes;

    my $address        = trim($addr_nodes[0]->string_value);
    my $city_state_zip = trim($city_nodes[0]->string_value);

    next unless ($city_state_zip =~ m/^(.*)\s+(\w\w)\s+(\d\d\d\d\d-\d\d\d\d)$/);
    my ($city, $state, $zip) = ($1, $2, $3);

    #
    # Check and parse the additional information:
    #

    next unless @route_nodes;
    next unless @county_nodes;
    next unless @delivery_nodes;
    next unless @check_nodes;

    my $route    = trim($route_nodes[0]->string_value);
    my $county   = trim($county_nodes[0]->string_value);
    my $delivery = trim($delivery_nodes[0]->string_value);
    my $check    = trim($check_nodes[0]->string_value);

    $route    =~ s/^.*: ?//; # Remove any leading field name
    $county   =~ s/^.*: ?//; # Remove any leading field name
    $delivery =~ s/^.*: ?//; # Remove any leading field name
    $check    =~ s/^.*: ?//; # Remove any leading field name

    #
    # Create an Address object to represent the above, and remember it:
    #

    my $match = Scrape::USPS::ZipLookup::Address->new($address, $city, $state, $zip);

    $match->carrier_route($route);
    $match->county($county);
    $match->delivery_point($delivery);
    $match->check_digit($check);

    push @matches, $match;
  }

  print '\\', '_' x 77, '/',  "\n" if $self->verbose;

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

  my @matches = $zlu->std_addr($addr);

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

To see debugging output, call C<< $zlu->verbose(1) >>.


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

Copyright (C) 1999-2003 Gregor N. Purdy. All rights reserved.

This program is free software. It is subject to the same license as Perl.

=cut


#
# End of file.
#

