#!/usr/bin/perl

use strict;
use vars qw($libdir);
BEGIN
{
if ( -d './lib' )
{
	push(@INC, './lib');
	$libdir = './lib';
}
elsif ( -d '../lib' )
{
	push(@INC, '../lib');
	$libdir = '../lib';
}
else
{
	die "Could not find lib directory which contains Config::ApacheExtended";
}
}

print "$libdir\n";
use Config::ApacheExtended;

use Parse::RecDescent;

Parse::RecDescent->Precompile(join('',<Config::ApacheExtended::DATA>), "Config::ApacheExtended::Parser");
link "./Parser.pm","$libdir/Config/ApacheExtended/Parser.pm";
unlink "./Parser.pm";
