# -*- perl -*-

# t/006_expandvars.t - Tests the variable expansion feature

use Test::More tests => 11;
use Config::ApacheExtended;
my $conf = Config::ApacheExtended->new(
	source			=> "t/expandvars.conf",
	expand_vars		=> 1,
	inherit_vals	=> 1,
);


ok($conf);														# test 1
ok($conf->parse);												# test 2

my $foo = $conf->get('Foo');
my $thisfoo = $conf->get('ThisFoo');
my @bar = $conf->get( 'Bar' );
my $block = $conf->block( FooBar => 'baz test' );
my $boom = $block->get('Boom');
my $cstr = join($", @bar);

ok($foo);														# test 3
is($foo, 'bar');												# test 4
ok($thisfoo);													# test 5
is($thisfoo,$foo);												# test 6


ok($block);														# test 7
ok(@bar);														# test 8
is(scalar(@bar), 2);											# test 9
ok($boom);														# test 10
is($boom, $cstr);												# test 11
