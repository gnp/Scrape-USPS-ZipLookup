#
# Address.pm
#
# Perl 5 module to represent U.S. postal addresses for the purpose of
# standardizing via the U.S. Postal Service's web site:
#
#     http://www.usps.com/zip4/
#
# BE SURE TO READ AND UNDERSTAND THE TERMS OF USE SECTION IN THE
# DOCUMENTATION, WHICH MAY BE FOUND AT THE END OF THIS SOURCE CODE.
#
# Copyright (C) 1999-2006 Gregor N. Purdy. All rights reserved.
#
# This program is free software. It is subject to the same license as Perl.
#
# [ $Id$ ]
#

package Scrape::USPS::ZipLookup::Address;
use strict;

use Carp;

use vars qw($VERBOSE);
$VERBOSE = 0;

use Carp;

use URI;

my @input_fields = (
  'Firm',
  'Urbanization',
  'Delivery Address',
  'City',
  'State',
  'Zip Code'
);
my %input_fields = map { ($_, 1) } @input_fields;

my @output_fields = (
  'Carrier Route',
  'County',
  'Delivery Point',
  'Check Digit',
  'LAC Indicator',
  'eLOT Sequence',
  'eLOT Indicator',
  'Record Type',
  'PMB Designator',
  'PMB Number',
  'Default Address',
  'Early Warning',
  'Valid',
);
my %output_fields = map { ($_, 1) } @output_fields;


my @all_fields = (
   @input_fields,
   @output_fields
);
my %all_fields = map { ($_, 1) } @all_fields;
  

#
# new()
#

sub new
{
  my $class  = shift;
  my %fields = map { ($_, undef) } @all_fields;
  my $self   = bless { %fields }, $class;

  return $_[0] if @_ and ref($_[0]) eq $class;
  
  if (@_) {
    $self->input_fields(@_);
  }
  else {
    confess "Cannot create empty $class!";
  }

  return $self;
}


#
# dump()
#

sub dump
{
  my $self = shift;
  my $message = shift;

  confess "Expected message" unless $message;

  print "ADDRESS: $message\n";

  foreach my $key (sort @all_fields) {
    next unless defined $self->{$key};
    printf "  %s => '%s'\n", $key, $self->{$key};
  }

  print "\n";
}


#
# _field()
#
#   * firm()
#   * urbanization()
#   * delivery_address()
#   * city()
#   * state()
#   * zip_code()
#
#   * carrier_route()
#   * county()
#   * delivery_point()
#   * check_digit()
#

sub _field
{
  my $self  = shift;
  my $field = shift;

  die "Undefined field!" unless defined $field;
  die "Illegal field!" unless $all_fields{$field};

  if (@_) {
    my $value = shift;
    $self->{$field} = $value;
    return $value;
  } else {
    return $self->{$field};
  }
}


sub firm             { my $self = shift; $self->_field('Firm',             @_); }
sub urbanization     { my $self = shift; $self->_field('Urbanization',     @_); }
sub delivery_address { my $self = shift; $self->_field('Delivery Address', @_); }
sub city             { my $self = shift; $self->_field('City',             @_); }
sub state            { my $self = shift; $self->_field('State',            @_); }
sub zip_code         { my $self = shift; $self->_field('Zip Code',         @_); }

sub carrier_route    { my $self = shift; $self->_field('Carrier Route',    @_); }
sub county           { my $self = shift; $self->_field('County',           @_); }
sub delivery_point   { my $self = shift; $self->_field('Delivery Point',   @_); }
sub check_digit      { my $self = shift; $self->_field('Check Digit',      @_); }

sub lac_indicator    { my $self = shift; $self->_field('LAC Indicator',    @_); }
sub elot_sequence    { my $self = shift; $self->_field('eLOT Sequence',    @_); }
sub elot_indicator   { my $self = shift; $self->_field('eLOT Indicator',   @_); }
sub record_type      { my $self = shift; $self->_field('Record Type',      @_); }
sub pmb_designator   { my $self = shift; $self->_field('PMB Designator',   @_); }
sub pmb_number       { my $self = shift; $self->_field('PMB Number',       @_); }
sub default_address  { my $self = shift; $self->_field('Default Address',  @_); }
sub early_warning    { my $self = shift; $self->_field('Early Warning',    @_); }
sub valid            { my $self = shift; $self->_field('Valid',            @_); }


#
# input_fields()
#
# Set or get all input fields simultaneously. When setting, any unspecified
# fields are set to undef and all output fields are set to the undef as well.
#

sub input_fields
{
  my $self  = shift;

  unless (@_) {
    my %fields = map { ($_, $self->{$_}) } @input_fields;
    print join("\n", %fields), "\n";
    return %fields;
  }

  my %fields = map { ($_, undef) } @input_fields;
  my %input;

  if (@_ == 1 and ref $_[0] and UNIVERSAL::isa($_[0], "Scrape::USPS::ZipLookup::Address")) {
    return $_[0];
  } elsif (@_ == 1 and ref $_[0] eq 'HASH') {
    %input = %{$_[0]};
  } elsif (@_ == 6) {
    %input = (
      'Firm'             => $_[0],
      'Urbanization'     => $_[1],
      'Delivery Address' => $_[2],
      'City'             => $_[3],
      'State'            => $_[4],
      'Zip Code'         => $_[5], 
    );
  } elsif (@_ == 5) {
    %input = (
      'Firm'             => $_[0],
      'Delivery Address' => $_[1],
      'City'             => $_[2],
      'State'            => $_[3],
      'Zip Code'         => $_[4], 
    );
  } elsif (@_ == 4) {
    %input = (
      'Delivery Address' => $_[0],
      'City'             => $_[1],
      'State'            => $_[2],
      'Zip Code'         => $_[3], 
    );
  } elsif (@_ == 3) {
    %input = (
      'Delivery Address' => $_[0],
      'City'             => $_[1],
      'State'            => $_[2],
    );
  } elsif (@_ == 2) {
    %input = (
      'Delivery Address' => $_[0],
      'Zip Code'         => $_[1], 
    );
  } else {
    confess "Unrecognized input (" . scalar(@_) . " args: " . join(', ', map { ref } @_) . ")!";
  }

  foreach (@all_fields) { $self->{$_} = undef; }

  foreach my $key (keys %input) {
    die "Illegal field '$key'!" unless $input_fields{$key};
    $self->{$key} = $input{$key};
  }
}


#
# to_dump()
#

sub to_dump
{
  my $self = shift;
  my @lines;

  foreach (@all_fields) {
    push @lines, sprintf("%-20s => %s", $_, $self->{$_}) unless $self->{$_} eq '';
  }

  return join("\n", @lines);
}


#
# to_array()
#

sub to_array
{
  my $self = shift;
  my @lines;

  foreach (@input_fields) {
    push @lines, $self->{$_} unless $self->{$_} eq '';
  }

  return @lines;
}


#
# to_string()
#

sub to_string
{
  my $self = shift;

  return join("\n", $self->delivery_address, $self->city, $self->state, $self->zip_code);
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

Scrape::USPS::ZipLookup::Address - Address Class for USPS ZIP Code Lookups


=head1 SYNOPSIS

  use Scrape::USPS::ZipLookup::Address;


=head1 DESCRIPTION

TODO


=head1 TERMS OF USE

BE SURE TO READ AND FOLLOW THE UNITED STATES POSTAL SERVICE TERMS OF USE
PAGE AT C<http://www.usps.gov/disclaimer.html>. IN PARTICULAR, NOTE THAT THEY
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

use strict;

use HTTP::Response;

use vars qw(@ISA);

@ISA = qw(HTTP::Response);


#
# matches()
#
# Output: One array reference for each address returned. Each array
#         contains the Street Address, City, State, and Zip.
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
      push @output, scrape_address($_);
    }

    return @output;
}


#
# first_match()
#

sub first_match
{
	my $self = shift;

    my @addrs = $self->matches;

    return unless @addrs;

    my $first = shift @addrs;

    my %addr = %$first;

    return ($addr{STREET}, $addr{CITY}, $addr{STATE}, $addr{ZIP});
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

  use Scrape::USPS::ZipLookup::Response;

  my $res = $user_agent->...;
  bless $res, 'Scrape::USPS::ZipLookup::Response';


=head1 DESCRIPTION

Used to parse an HTML response to a request made via 
The United States Postal Service (USPS) HTML form at
C<http://www.usps.gov/ncsc/lookups/lookup_zip+4.html>
for standardizing an address.


=head1 TERMS OF USE

BE SURE TO READ AND FOLLOW THE UNITED STATES POSTAL SERVICE TERMS OF USE
PAGE AT C<http://www.usps.gov/disclaimer.html>. IN PARTICULAR, NOTE THAT THEY
DO NOT PERMIT THE USE OF THEIR WEB SITE'S FUNCTIONALITY FOR COMMERCIAL
PURPOSES. DO NOT USE THIS CODE IN A WAY THAT VIOLATES THE TERMS OF USE.

The author believes that the example usage given above does not violate
these terms, but sole responsibility for conforming to the terms of use
belongs to the user of this code, not the author.


=head1 AUTHOR

Gregor N. Purdy, C<gregor@focusresearch.com>.


=head1 COPYRIGHT

Copyright (C) 1999-2001 Gregor N. Purdy. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut


#
# End of file.
#

