#!/usr/bin/perl
use warnings;
use strict;
use XML::Simple;

open FILE, "autodia.out.dia" or die $!;

my $xml = XMLin( join( '', <FILE> ) );
print $xml->{'dia:layer'}->{'dia:object'}->{'type'},"\n";
my %entity;
my @relationships;

# Walk the data structure based on the XML created by XML Simple
# we must guarantee more two object, or we wont get the object id
my $single_object = 0;
foreach my $dia_object_id ( keys %{ $xml->{'dia:layer'}->{'dia:object'} } )
{
	# single object, just loop once
	if ( $single_object == 1 )
	{
		last;
	}
	# we should do a check for simple object
	my $object;
	if ( $dia_object_id eq "dia:attribute" )
	{
		$single_object = 1;
		$object = $xml->{'dia:layer'}{'dia:object'};	
	}
	else 
	{
		$object = $xml->{'dia:layer'}{'dia:object'}{$dia_object_id};
	}
	
	my $type   = $object->{type};
	if ( is_entity($type) )
	{
		warn "handling entity type : $type\n";
		my $name = $object->{'dia:attribute'}{name}{'dia:string'};
		$name =~ s/#(.*)#/$1/;
		if ( $type eq 'UML - Class' )
		{
			foreach my $method (
				@{
					get_methods(
						$object->{'dia:attribute'}{operations}{'dia:composite'}
					)
				}
			  )
			{
				print $method->{name}, "\n";
			}
			foreach my $attribute (
				@{
					get_attributes(
						$object->{'dia:attribute'}{attributes}{'dia:composite'}
					)
				}
			  )
			{
				print $attribute, "\n";
			}
		}
		else
		{
		}
	}
	else
	{
		my $connection = $object->{'dia:connections'}{'dia:connection'};
		warn "handling connection type : $type\n";

		push(
			@relationships,
			{
				from => $connection->[0]{to},
				to   => $connection->[1]{to},
				type => $type,
			}
		);
	}
}

foreach my $connection (@relationships)
{
	if ( $connection->{type} eq 'UML - Generalization' )
	{

	}
	else
	{


	}
}

####-----

sub is_entity
{
	my $object_type = shift;
	my $IsEntity    = 0;
	$IsEntity = 1 if ( $object_type =~ /(class|package)/i ); # ignore case 
	return $IsEntity;
}

sub get_methods
{
	my $methods = shift;
	my $return  = [];
	my $ref     = ref $methods;
	if ( $ref eq 'ARRAY' )
	{
		foreach my $method (@$methods)
		{
			my $name = $method->{'dia:attribute'}{name}{'dia:string'};
			my $type = $method->{'dia:attribute'}{type}{'dia:string'};
			$name =~ s/#(.*)#/$1/g;
			$type = 'void' if ( ref $type );
			$type =~ s/#//g;
			my $arguments = get_parameters(
				$method->{'dia:attribute'}{parameters}{'dia:composite'} );
			push(
				@$return,
				{
					name       => $name,
					type       => $type,
					Params     => $arguments,
					visibility => 0
				}
			);
		}
	}
	elsif ( $ref eq "HASH" )
	{
		my $name = $methods->{'dia:attribute'}{name}{'dia:string'};
		my $type = $methods->{'dia:attribute'}{type}{'dia:string'};
		$name =~ s/#(.*)#/$1/g;
		$type = 'void' if ( ref $type );
		$type =~ s/#//g;
		my $arguments = get_parameters(
			$methods->{'dia:attribute'}{parameters}{'dia:composite'} );
		push(
			@$return,
			{
				name       => $name,
				type       => $type,
				Params     => $arguments,
				visibility => 0
			}
		);
	}
	return $return;
}

sub get_parameters
{
	my $arguments = shift;
	my $return    = [];
	if ( ref $arguments )
	{
		if ( ref $arguments eq 'ARRAY' )
		{
			my @arguments = map ( {
					Type => $_->{'dia:attribute'}{type}{'dia:string'},
					Name => $_->{'dia:attribute'}{name}{'dia:string'},
				},
				@$arguments );
			foreach my $argument (@arguments)
			{
				$argument->{Type} =~ s/#//g;
				$argument->{Name} =~ s/#//g;
			}
			$return = \@arguments;
		}
		else
		{
			my $argument = {
				Type => $arguments->{'dia:attribute'}{type}{'dia:string'},
				Name => $arguments->{'dia:attribute'}{name}{'dia:string'},
			};
			$argument->{Type} =~ s/#//g;
			$argument->{Name} =~ s/#//g;
			push( @$return, $argument );
		}
	}
	return $return;
}

sub get_attributes
{
	my $attributes = shift;
	my $ref        = ref $attributes;
	my $return     = [];
	if ( $ref eq 'ARRAY' )
	{
		foreach my $attribute (@$attributes)
		{
			my $name = $attribute->{'dia:attribute'}{name}{'dia:string'};
			my $type = $attribute->{'dia:attribute'}{type}{'dia:string'};
			$name =~ s/#//g;
			$type =~ s/#//g;
			push( @$return, { name => $name, type => $type, visibility => 0 } );
		}
	}
	elsif ( $ref eq 'HASH' )
	{
		my $name = $attributes->{'dia:attribute'}{name}{'dia:string'};
		my $type = $attributes->{'dia:attribute'}{type}{'dia:string'};
		$name =~ s/#//g;
		$type =~ s/#//g;
		push( @$return, { name => $name, type => $type, visibility => 0 } );
	}
	return $return;
}

###############################################################################

=head1 SEE ALSO

Autodia::Handler

Autodia::Diagram

=head1 AUTHOR

Aaron Trevena, E<lt>aaron.trevena@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2001-2007 by Aaron Trevena

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
