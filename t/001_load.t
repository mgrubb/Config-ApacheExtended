# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'Config::ApacheExtended' ); }

my $object = Config::ApacheExtended->new ();
isa_ok ($object, 'Config::ApacheExtended');


