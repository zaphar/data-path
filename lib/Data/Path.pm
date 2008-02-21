package Data::Path;

use 5.006001;
use strict;
use warnings;
use Scalar::Util 'blessed';
use Carp;

our $VERSION = '1.2';

sub new {
	my ($class,$data,$callback)=@_;
	$callback||={};
	my $self=
		{ data     => $data 

		# set call backs to default if not given
		, callback => 
			{ key_does_not_exist            => $callback->{key_does_not_exist} ||
				sub {
					my ($data, $key, $index, $value, $rest )=@_;
					croak "key $key does not exists\n";
				}

			, index_does_not_exist         => $callback->{index_does_not_exist} ||
				sub {
					my ($data, $key, $index, $value, $rest )=@_;
					croak "key $key\[$index\] does not exists\n";
				}

			, retrieve_index_from_non_array => $callback->{retrieve_index_from_non_array} ||
				sub {
					my ($data, $key, $index, $value, $rest )=@_;
					croak "trie to retrieve an index $index from a no array value (in key $key)\n";
				}

			, retrieve_key_from_non_hash    => $callback->{retrieve_key_from_non_hash} ||
				sub {
					my ($data, $key, $index, $value, $rest )=@_;
					croak "trie to retrieve a key from a no hash value (in key $key)\n";
				}
			, not_a_coderef_or_method    => $callback->{not_a_coderef_or_method} ||
				sub {
					my ($data, $key, $index, $value, $rest )=@_;
					croak "tried to retrieve from a non-existant coderef or method: $key in $data";
				}
			}

		};
	return bless $self,$class;
}

sub get {
	my ($self,$rkey,$data)=@_;

	# set data to
	$data||=$self->{data};

	# get key till / or [
	my $key = $1 if ( $rkey =~ s/^\/([^\/|\[]+)//o );
	
	# check index for index
	my $index = $1 if ( $rkey =~ s/^\[(\d+)\]//o );

	# set rest
	my $rest  = $rkey;

	# get key from data
	my $value;
    if ($key =~ s/(\(\))$//) {
        $self->{callback}->{not_a_coderef_or_method}->($data, $key, $index, $value, $rest)
            unless exists $data->{$key} or (blessed $data && $data->can($key)); 
        
        $value = $data->{$key}->() if (exists $data->{$key});
        $value = $data->$key() if blessed $data && $data->can($key);
    } else {
	   $value = $data->{$key};
    }
	
    # croak if key does not exists and something after that is requested 
	$self->{callback}->{key_does_not_exist}->($data, $key, $index, $value, $rest) 
		if not exists $data->{$key} and $rest;

	# check index 
	if (defined $index) {

		# croak if index does not exists and something after that is requested 
		$self->{callback}->{index_does_not_exist}->($data, $key, $index, $value, $rest) 
			if not exists $value->[$index] and $rest;

		if ( ref $value eq 'ARRAY' ) {
			$value=$value->[$index];
		} else {
			$self->{callback}->{retrieve_index_from_non_array}->($data, $key, $index, $value, $rest);
		}
	}

	# check if last element is reached
	if ($rest) {
		if ( ref $value eq 'HASH' || blessed $value ) {
			$value=$self->get($rest,$value);
		} else {
			$self->{callback}->{retrieve_key_from_non_hash}->($data, $key, $index, $value, $rest);
		}
	}

	return $value;
}

1;

__END__

=head1 NAME

Data::Path - Perl extension for XPath like accessing from complex data structs

=head1 SYNOPSIS

  use Data::Path;

  my $hashdata={
  	result => {
		msg => 
			[ { text => 'msg0' }
			, { text => 'msg1' }
			, { text => 'msg2' }
			]
	},
    method => sub {'method text'}
  }
  
  my $hpath=Data::Path->new($hashdata);
  my $value= $hpath->get('/result/msg[1]/text');
  my $value2 = $hpath->get('/method()');
  
  print "OK" if $value2 eq 'method text';
  print "OK" if $value eq 'msg1';


  my $hpath=Data::Path->new($hashdata,$callback);

  my $hpath=Data::Path->new
  	($hashdata,
	{ key_does_not_exist => sub { die index not found } 
  	);

=head1 DESCRIPTION

XPath like access to get values from a complex data structs.

key_does_not_exist / index_does_not_exist are only called if it was not the last part of the path.
If the last part of path is not exists undef is returned.

=head2 CALLBACKs

The default callbacks but you can overwrite this.

	{ key_does_not_exist            =>
		sub {
			my ($data, $key, $index, $value, $rest )=@_;
			croak "key $key does not exists\n";
		}

	, index_does_not_exist         =>
		sub {
			my ($data, $key, $index, $value, $rest )=@_;
			croak "key $key\[$index\] does not exists\n";
		}

	, retrieve_index_from_non_array =>
		sub {
			my ($data, $key, $index, $value, $rest )=@_;
			croak "trie to retrieve an index $index from a no array value (in key $key)\n";
		}

	, retrieve_key_from_non_hash    =>
		sub {
			my ($data, $key, $index, $value, $rest )=@_;
			croak "trie to retrieve a key from a no hash value (in key $key)\n";
		}
	, not_a_coderef_or_method    => $callback->{not_a_coderef_or_method} ||
		sub {
			my ($data, $key, $index, $value, $rest )=@_;
			croak "tried to retrieve from a non-existant coderef or method";
		}
	}

	
=head2 EXMAPLE overwrite callback

  my $hpath=Data::Path->new
  	($hashdata,
	{ key_does_not_exist   => sub { die key not found } 
	{ index_does_not_exist => sub { die index not found } 
  	);


=head2 EXPORT

None by default.

=head1 SEE ALSO

	XPath
 
=head1 TODO

Slices of data through /foo[*]/bar syntax. eg. retrieve all the bar keys from each element of the foo
array.

allow accessing the results of coderefs eg. /foo()/bar retreive the result of the foo coderef/method
of the object

=head1 AUTHOR

Marco Schrieck, E<lt>marco.schrieck@gmx.deE<gt>

Jeremy Wall L<< jeremy@marzhillstudios.com >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Marco Schrieck
Copyright (C) 2007 by Jeremy Wall

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.


=cut
