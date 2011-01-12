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
		direct => "in",
		value => "100"
);
my @params = ( \%param1, \%param2 );	
### Methods ###
my %method1 = (
		name => "Hello",
		type => "void",
		params => \@params,
		comment => "This is a test method"
);
my @methods = ( \%method1 );

my %class = (
		name => "Object",
		comment => "This is a basic class",
		attributes => \@attributes,
		methods => \@methods
);

### the main ###
# At last, we should write the class into cpp head file
open FILE, "> Object.h" or die $!;
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
		
	}
	else
	{
		die "Wrong member!\n";
	}
	print $class_object, "\n";
} 

print FILE @{$cpp_class{comments}};
print FILE @{$cpp_class{name}};
print FILE @{$cpp_class{attributes}};

# At last, close the class 
print FILE "};\n";

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
