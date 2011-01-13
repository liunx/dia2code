#!/usr/bin/perl
use warnings;
use strict;
use XML::Simple;

open FILE, "autodia.out.dia" or die $!;

my $xml = XMLin( join( '', <FILE> ) );

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
		$object        = $xml->{'dia:layer'}{'dia:object'};
	}
	else
	{
		$object = $xml->{'dia:layer'}{'dia:object'}{$dia_object_id};
	}

	my $type = $object->{type};
	if ( is_entity($type) )
	{
		warn "handling entity type : $type\n";
		my $name = $object->{'dia:attribute'}{name}{'dia:string'};
		$name =~ s/#(.*)#/$1/;
		if ( $type eq 'UML - Class' )
		{

			# get class name
			my %class = ( name => $name );
			my @methods;
			foreach my $method (
				@{
					get_methods(
						$object->{'dia:attribute'}{operations}{'dia:composite'}
					)
				}
			  )
			{

				#				print $method->{name}, "\n";
				push @methods, $method;
			}
			$class{methods} = \@methods;
			my @attributes;
			foreach my $attribute (
				@{
					get_attributes(
						$object->{'dia:attribute'}{attributes}{'dia:composite'}
					)
				}
			  )
			{

				#				print $attribute, "\n";
				push @attributes, $attribute;
			}
			$class{attributes} = \@attributes;
			print $class{name}, "\n";
			parser( \%class );
		}

	}
}

#####################################################################################
### Subroutines
#####################################################################################
sub parser {
	my $class_ref = shift;
	my %cpp_class;

	# We need to fully read the class hash, and get all of it's
	# contents like class name, attributes, methods, visibilities,
	# then translate them into source codes.

	# Walk through the hash table
	foreach my $class_object ( keys %$class_ref )
	{
		my $ref = $class_ref;
		if ( $class_object eq "name" )
		{

			# print the class name

			$cpp_class{name} = put_classname( $ref->{$class_object} );

			#		print $classname, "\n";
		}
		elsif ( $class_object eq "comment" )
		{
			$cpp_class{comments} = put_comments( $ref->{$class_object}, "" );
		}
		elsif ( $class_object eq "attributes" )
		{
			$cpp_class{attributes} = put_attributes( $ref->{$class_object} );
		}
		elsif ( $class_object eq "methods" )
		{
			$cpp_class{methods} = put_methods( $ref->{$class_object} );
		}
		else
		{
			die "Wrong member!\n";
		}
		print $class_object, "\n";
	}

	# first, write the class header file
	open FILE, "> $class_ref->{name}.h" or die $!;

	print FILE "#ifndef __$class_ref->{name}_H\n";
	print FILE "#define __$class_ref->{name}_H\n";
#	print FILE @{ $cpp_class{comments} };
	print FILE @{ $cpp_class{name} };
	print FILE @{ $cpp_class{attributes} };
	print FILE @{ $cpp_class{methods} };

	# At last, close the class
	print FILE "};\n";
	print FILE "#endif\n";

	# Second, write the class cpp file
	# open FILE, "> $class{name}.cpp" or die $!;
}

### get comments
sub put_comments {

	# string list
	my $ref = shift;

	# We need the comments to match with it's
	# body
	my $tab = shift;

	my ( @comments, @buf );

	# split the comments into piecies
	@buf = split( /\n/, $ref );
	push @comments, "$tab/*\n";
	for my $i (@buf)
	{
		push @comments, "$tab * $i\n";
	}
	push @comments, "$tab */\n";

	return \@comments;
}

### get class name
sub put_classname {

	# hash table
	my $ref = shift;

	my @classname;
	push @classname, "class $ref {\n";

	return \@classname;
}

### get attributes
sub put_attributes {

	# get the reference of attributes (ARRAY)
	my $ref = shift;

	my @attributes;
	push @attributes, "\t/* Attributes */\n";

	# we need three template arrays to store
	# public, private, protected attributes
	my ( @public, @private, @protected );
	push @public,    "\tpublic:\n";
	push @private,   "\tprivate:\n";
	push @protected, "\tprotected:\n";

	for my $i (@$ref)
	{
		if ( $i->{visibility} eq "public" )
		{
			push @public, "\t$i->{type} $i->{name} ;\t//$i->{comment}\n";
		}
		elsif ( $i->{visibility} eq "private" )
		{
			push @private, "\t$i->{type} $i->{name} ;\t//$i->{comment}\n";
		}
		elsif ( $i->{visibility} eq "protected" )
		{
			push @protected, "\t$i->{type} $i->{name} ;\t//$i->{comment}\n";
		}
		else
		{
			die "Wrong attribute!\n";
		}
	}

	# At last, push them into attributes array
	push @attributes, @public;
	push @attributes, @private;
	push @attributes, @protected;

	#	print FILE @attributes;

	return \@attributes;
}

### get parameters
sub put_params {
	my $params;
	my $ref = shift;

	# we use a variable to show loop count
	my $loop = 0;
	for my $i (@$ref)
	{
		if ( $loop != 0 )
		{
			$params .= ", ";
		}

		if ( $i->{direct} eq "in" )
		{
			$params .= "const $i->{type} $i->{name}";
		}
		elsif ( $i->{direct} eq "out" )
		{
			$params .= "$i->{type}& $i->{name}";
		}
		elsif ( $i->{direct} eq "inout" )
		{
			$params .= "$i->{type}& $i->{name}";
		}
		else
		{
			print "Wrong direct!\n";
		}
		$loop++;
	}
	return $params;
}

### get methods
sub put_methods {
	my $ref = shift;
	my ( @methods, @public, @private, @protected );
	push @methods,   "\t/* methods */\n";
	push @public,    "\tpublic:\n";
	push @private,   "\tprivate:\n";
	push @protected, "\tprotected:\n";
	for my $i (@$ref)
	{
		my $params;
		if ( $i->{visibility} eq "0" ) # public
		{
			$params = put_params( $i->{Params} );
			if ( $params eq undef ) { next; }
			push @public,
			  "\t$i->{type} $i->{name}($params) ;\t//$i->{comment}\n";
		}
		elsif ( $i->{visibility} eq "1" )	# private
		{
			$params = put_params( $i->{Params} );
			if ( $params eq undef ) { next; }
			push @private,
			  "\t$i->{type} $i->{name}($params) ;\t//$i->{comment}\n";
		}
		elsif ( $i->{visibility} eq "2" )	# protected
		{
			$params = put_params( $i->{Params} );
			if ( $params eq undef ) { next; }
			push @protected,
			  "\t$i->{type} $i->{name}($params) ;\t//$i->{comment}\n";
		}
		else
		{
			print "Wrong attribute!\n";
		}
	}
	push @methods, @public;
	push @methods, @private;
	push @methods, @protected;

	return \@methods;

}

#######################################################################################
=head1 COPYRIGHT AND LICENSE

Copyright (C) 2001-2007 by Aaron Trevena

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.

=cut

sub is_entity {
	my $object_type = shift;
	my $IsEntity    = 0;
	$IsEntity = 1 if ( $object_type =~ /(class|package)/i ); # ignore case 
	return $IsEntity;
}

sub get_methods {
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

sub get_parameters {
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

sub get_attributes {
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


