#!/usr/bin/perl

use strict;
use Parse::RecDescent;
my $libdir;
my $grammarfile;

my($dest,$grammar,$package) = @ARGV[0..2];

open(GRAMMAR,"<$grammar") or die "Could not open [ $grammar ] : $!\n";

Parse::RecDescent->Precompile(join('',<GRAMMAR>), $package );
my @parts = split(/::/,$package);
my $file = $parts[-1] . ".pm";
my $dfile = sprintf('%s/%s/%s', $dest, join('/', @parts[0..$#parts - 1]), $file);
unlink $dfile if -e $dfile;
link "./$file", $dfile;
unlink "./$file";
