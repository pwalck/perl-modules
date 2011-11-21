package Tie::JSON;

use JSON;

BEGIN
{
  $Tie::JSON::VERSION = '0.1';
}

require Tie::Hash;
@ISA = ('Tie::ExtraHash');

sub TIEHASH
{
  my $package = shift;
  my %storage = ();
  my ($filename, $options, $json_options) = @_;
  my %data;
  
  $data{filename} = $filename;
  $data{options} = $options || {};
  $data{json_options} = $json_options || { pretty => 1, canonical => 1 };
  
  if (-f $filename)
  {
    $data{original} = do { open F, $filename; local $/; <F> };
    %storage = %{from_json($data{original})};
  }
  
  bless [\%storage, \%data], $package;
}

sub DESTROY
{
  my $storage = $_[0][0];
  my $data = $_[0][1];
  
  my %copy = %{$storage};
  
  if (!$$data{options}{readonly} and (to_json(\%copy, $$data{json_options}) ne $$data{original}))
  {
    local $\;
    open F, '>', $$data{filename} or die;
    print F to_json(\%copy, $$data{json_options});
    close F;
  }
}

1;

__END__

=head1 NAME

Tie::JSON - Simple way to tie hashes to JSON files.

=head1 SYNOPSIS

 use Tie::JSON;

 # tie with default options:

 tie %hash, 'Tie::JSON', 'data.json';
 
 # tie with Tie::JSON options (currently only "readonly")

 tie %hash, 'Tie::JSON', 'data.json', { readonly => 1 };

 # tie with options passed to the JSON encoder:

 tie %hash, 'Tie::JSON', 'data.json', {}, { pretty => 0 };

=head1 VERSION

 0.1

First version, needs some polishing. There are
no error messages, there is no way to flush data to disk
without untie:ing and the name sort of implies that tie:ing
arrays should work.

=head1 DESCRIPTION

This module enables easy persistence of hashes in json files. I
use it for storing all sorts of stuff, from configuration to persistent
persistent data between runs of one-liners and simple caching.
Even fairly large nested structures (several MB) are encoded/decoded
very quickly on a modern computer. However, it is not the most
efficient way to store and retrieve data so your mileage may vary.
