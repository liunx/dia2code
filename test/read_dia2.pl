#!/usr/bin/perl
use warnings;
use strict;
use XML::Simple;

open FILE, "autodia.out.dia" or die $!;

my $xml = XMLin( join( '', <FILE> ) );

# Walk along the xml file
my $single_object = 0;
foreach my $dia_object_id ( keys %{ $xml->{'dia:layer'}->{'dia:object'} })
{
	if ( $single_object == 1 )
	{
		last;
	}
	my $object;
	if ( $dia_object_id eq "dia:attribute" )
	{
		$object = $xml->{'dia:layer'}{'dia:object'};
	}
	else 
	{
		$object = $xml->{'dia:layer'}{'dia:object'}{$dia_object_id};
	}
	
}

print "Hello,Perl!\n";