#
# Address.pm
#
# [ $Revision: 1.1 $ ]
#
# Perl 5 module to standardize U.S. postal addresses by referencing
# the U.S. Postal Service's web site:
#
#     http://www.usps.gov/ncsc/lookups/lookup_zip+4.html'
#
# BE SURE TO READ AND UNDERSTAND THE TERMS OF USE SECTION IN THE
# DOCUMENTATION, WHICH MAY BE FOUND AT THE END OF THIS SOURCE CODE.
#
# Copyright (C) 1999-2001 Gregor N. Purdy. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#

package Scrape::USPS::ZipLookup::Address;
use strict;

use vars qw($VERBOSE);
$VERBOSE = 0;

use overload qw("") => \&to_string;

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
  'Check Digit'
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
  my %fields = map { ($_, '') } @all_fields;
  my $self   = bless { %fields }, $class;

  $self->input_fields(@_) if @_;

  return $self;
}


#
# new_html()
#

sub new_html
{
  my $class = shift;
  my $html  = shift;

  my $self = $class->new();

  $self->html($html);

  return $self;
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


#
# input_fields()
#
# Set or get all input fields simultaneously. When setting, any unspecified
# fields are set to the empty string and all output fields are set to the
# empty string as well.
#

sub input_fields
{
  my $self  = shift;
  my %fields = map { ($_, '') } @input_fields;

  return map { ($_, $self->{$_}) } @input_fields unless @_;

  my %input;

  if (@_ == 1 and ref $_[0] eq 'HASH') {
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
    die "Unrecognized input field specification!";
  }

  foreach (@all_fields) { $self->{$_} = ''; }

  foreach (keys %input) {
    die "Illegal field '$_'!" unless $input_fields{$_};
    $self->{$_} = $input{$_}
  }
}


#
# query()
#
# Set or get the query string that forms the content of the HTTP request
# for scraping. This ends up calling the input_fields() function to set
# or get the input fields.
#

sub query
{
  my $self = shift;

  my $uri = URI->new('http:');

  if (@_) {
    $uri->query(shift);
    my %hash = $uri->query_form();
    $self->input_fields(%hash);
    return;
  } else {
    $uri->query_form($self->input_fields());
    return $uri->query;
  }
}


#
# html()
#
# Set via HTML fragment obtained from HTTP::Response.
#

sub html
{
  my $self = shift;

  my ($addr) = @_;
  my $table;
  my $trash;
  my %data;

  #
  # First, split it into the address proper, and the table of additional
  # information:
  #

  unless ($addr =~ s/^(.*)<TABLE(\s+[^>]*)?>(.*)<\/TABLE>(.*)$//sim) {
    die "Bad address: Can't find <TABLE> begin tag!: \n\n>>>>>\n$addr\n<<<<<\n\n";
  }

  $addr  = $1;
  $table = $3;
  $trash = $4;

  #
  # Now, scrape information from the table:
  #

  $table =~ s/<\/?[a-z]+>//ig; # Remove all begin and end tags
  $table =~ s/^\s*//mg;        # Remove leading whitespace.
  $table =~ s/\s*$//mg;        # Remove trailing whitespace.
  $table =~ s/\n+/\n/mg;       # Delete any extra newlines

  print STDERR "vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv\n" if $VERBOSE;
  print STDERR ">> TABLE:\n$table\n" if $VERBOSE;
  print STDERR "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n" if $VERBOSE;

  foreach (split(/\n/m, $table)) {
    m/^([a-z ]*)\s+:\s+(.*)$/i or die "Bad table field: \"$_\"!\n";
    $self->_field($1, $2);
  }

  #
  # Now, perform some simple transformations on the address to get it into shape:
  #

  $addr =~ s/<\/?[a-z]+>//ig;  # Remove all begin and end tags
  $addr =~ s/^\s*//mg;         # Remove leading whitespace.
  $addr =~ s/\s*$//mg;         # Remove trailing whitespace.
  $addr =~ s/ +/ /g;           # Collapse spaces.

  print STDERR "vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv\n" if $VERBOSE;
  print STDERR ">> ADDRESS:\n$addr\n" if $VERBOSE;
  print STDERR "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n" if $VERBOSE;

  my @addr = split(/\n/m, $addr);

  my $city_state_zip = pop @addr;

  $city_state_zip =~ m/^(.*) ([A-Z][A-Z]) (\d{5}(-\d{4})?)$/
    or die "Unrecognized city-state-zip format '$city_state_zip'!";

  my ($city, $state, $zip_code) = ($1, $2, $3);

  my $delivery_address = pop @addr;

  if (@addr and $addr[-1] =~ m/^\((EVEN|ODD) Range [0-9]+ - [0-9]+\)$/) {
    $delivery_address  = pop(@addr) . " " . $delivery_address;
  }
  
  my $firm = pop @addr if @addr;

  die "Unrecognized address format: '$addr'!" if @addr;

#  $addr =~ s/\n/|/mg;          # Put it all on one line with '|' between fields

  #
  # Add field delimiters for the state and zip code:
  #

#  $addr =~ s/ ([A-Z]{2}) (\d{5}(-\d{4})?).*$/|$1|$2/i;

  #
  # Split it into an array and set fields based on it:
  #
  # We do explicit assignment in case there were any extra elements
  # produced by split.
  #
  # TODO: This is not robust enough to deal with urbanizations, I would guess.
  #

#  my ($delivery_address, $city, $state, $zip_code) = split('\|', $addr);

  $self->firm            ($firm)             if defined $firm;
  $self->delivery_address($delivery_address);
  $self->city            ($city);
  $self->state           ($state);
  $self->zip_code        ($zip_code);

  return;
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

  return join("\n", $self->to_array);
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

Copyright (C) 1999-2001 Gregor N. Purdy. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

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

