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
		comment => "This is a variable"	
);
my @attributes = ( \%attribute1, \%attribute2 );

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
my @cpp_class;
push @cpp_class, "/* $class{comment}\n *\n *\n */ \n";
push @cpp_class, "class $class{name}:\n";
push @cpp_class, "\t Object();\n";
push @cpp_class, "\t ~Object();\n";
push @cpp_class, "};\n";

# At last, we should write the class into cpp head file
open FILE, "> Object.h" or die $!;

print FILE @cpp_class;
