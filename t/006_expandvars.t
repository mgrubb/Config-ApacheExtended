# -*- perl -*-

# t/006_expandvars.t - Tests the variable expansion feature

use Test::More tests => 12;
use Config::ApacheExtended;
my $conf = Config::ApacheExtended->new(source => "t/expandvars.conf", expand_vars => 1, inherit_vals => 1);

# test 1
ok($conf);

# test 2
isa_ok($conf, 'Config::ApacheExtended');

# test 3
ok($conf->parse);

# tests 4-7
my $foo = $conf->get('Foo');
ok($foo);
is($foo, 'bar');
my $thisfoo = $conf->get('ThisFoo');
ok($thisfoo);
is($thisfoo,$foo);

# tests 8-12
my @bar = $conf->get( 'Bar' );
my $block = $conf->block( FooBar => 'baz test' );
my $boom = $block->get('Boom');
ok($block);
ok(@bar);
is(scalar(@bar), 2);
my $cstr = join($", @bar);
ok($boom);
is($boom, $cstr);
