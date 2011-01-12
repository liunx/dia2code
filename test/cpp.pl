#!/usr/bin/perl
use warnings;
use strict;

#### Attributes ###
my %attribute1 = (
		name => "a",
		type => "int",
		visibility => "public",
		comment => "This is a variable"	
);
my %attribute2 = (
		name => "b",
		type => "int",
		visibility => "private",
		comment => "This is b variable"	
);
my %attribute3 = (
		name => "c",
		type => "int",
		visibility => "protected",
		comment => "This is c variable"	
);
my @attributes = ( \%attribute1, \%attribute2, \%attribute3 );

### Parameters ###
my %param1 = (
		name => "a",
		type => "int",
		direct => "in",
		value => "0"
);
my %param2 = (
		name => "b",
		type => "int",
		direct => "out",
		value => "100"
);
my @params = ( \%param1, \%param2 );	
### Methods ###
my %method1 = (
		name => "Hello",
		type => "void",
		params => \@params,
		visibility => "public",
		comment => "This is a test method"
);
my %method2 = (
		name => "Hello2",
		type => "void",
		params => \@params,
		visibility => "private",
		comment => "This is a test method"
);
my %method3 = (
		name => "Hello3",
		type => "void",
		params => \@params,
		visibility => "protected",
		comment => "This is a test method"
);
my @methods = ( \%method1, \%method2, \%method3 );

my %class = (
		name => "Object",
		comment => "This is a basic class",
		attributes => \@attributes,
		methods => \@methods
);

### the main ###
my %cpp_class;
# We need to fully read the class hash, and get all of it's 
# contents like class name, attributes, methods, visibilities,
# then translate them into source codes.

# Walk through the hash table
foreach my $class_object ( keys %class )
{
	my $ref = \%class;
	if ( $class_object eq "name")
	{
		# print the class name
		
		$cpp_class{name} = get_classname( $ref->{$class_object} );
#		print $classname, "\n";
	}
	elsif ( $class_object eq "comment" )
	{
		$cpp_class{comments} = get_comments( $ref->{$class_object}, "" );
	}
	elsif ( $class_object eq "attributes" )
	{
		$cpp_class{attributes} = get_attributes( $ref->{$class_object} );	
	}
	elsif ( $class_object eq "methods" )
	{
		$cpp_class{methods} = get_methods( $ref->{$class_object} );			
	}
	else
	{
		die "Wrong member!\n";
	}
	print $class_object, "\n";
} 

# first, write the class header file
open FILE, "> $class{name}.h" or die $!;

print FILE "#ifndef __$class{name}_H\n";
print FILE "#define __$class{name}_H\n";
print FILE @{$cpp_class{comments}};
print FILE @{$cpp_class{name}};
print FILE @{$cpp_class{attributes}};
print FILE @{$cpp_class{methods}};

# At last, close the class 
print FILE "};\n";
print FILE "#endif\n";
# Second, write the class cpp file
# open FILE, "> $class{name}.cpp" or die $!;

###################################################################
### Subroutines ###

### get comments 
sub get_comments {
	# string list
	my $ref = shift;
	# We need the comments to match with it's 
	# body
	my $tab = shift;
	
	my ( @comments, @buf );
	# split the comments into piecies
	@buf = split( /\n/, $ref );
	push @comments, "$tab/*\n";
	for my $i ( @buf )
	{
		push @comments, "$tab * $i\n";
	}
	push @comments, "$tab */\n";
	
	return \@comments;
}

### get class name
sub get_classname {
	# hash table
	my $ref = shift;
	
	my @classname;
	push @classname, "class $ref {\n";
	
	return \@classname;
}

### get attributes
sub get_attributes {
	# get the reference of attributes (ARRAY)
	my $ref = shift;
	
	my @attributes;
	push @attributes, "\t/* Attributes */\n";
	# we need three template arrays to store 
	# public, private, protected attributes
	my ( @public, @private, @protected );
	push @public, "\tpublic:\n";
	push @private, "\tprivate:\n";
	push @protected, "\tprotected:\n";
	
	for my $i ( @$ref )
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
sub get_params {
	my $params;
	my $ref = shift;
	# we use a variable to show loop count
	my $loop = 0;
	for my $i ( @$ref )
	{
		if ( $loop != 0 )
		{
			$params .= ", "
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
			die "Wrong direct!\n";
		}
		$loop++;
	}
	return $params;
}

### get methods
sub get_methods {
	my $ref = shift;
	my ( @methods, @public, @private, @protected );
	push @methods, "\t/* methods */\n";
	push @public, "\tpublic:\n";
	push @private, "\tprivate:\n";
	push @protected, "\tprotected:\n";
	for my $i ( @$ref )
	{
		my $params;
		if ( $i->{visibility} eq "public" )
		{
			$params = get_params( $i->{params} );
			push @public, "\t$i->{type} $i->{name}($params) ;\t//$i->{comment}\n";	
		}
		elsif ( $i->{visibility} eq "private" )
		{
			$params = get_params( $i->{params} );
			push @private, "\t$i->{type} $i->{name}($params) ;\t//$i->{comment}\n";	
		}
		elsif ( $i->{visibility} eq "protected" )
		{
			$params = get_params( $i->{params} );
			push @protected, "\t$i->{type} $i->{name}($params) ;\t//$i->{comment}\n";	
		}
		else
		{
			die "Wrong attribute!\n";
		}
	}
	push @methods, @public;
	push @methods, @private;
	push @methods, @protected;
	
	return \@methods;
	
}
