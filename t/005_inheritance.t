# -*- perl -*-

# t/005_inheritance.t - Tests the inheritance features.

use Test::More tests => 7;
use Data::Dumper;
use Config::ApacheExtended;
my $conf = Config::ApacheExtended->new(source => "t/parse.conf", inherit_vals => 1);

# test 1
ok($conf);

# test 2
isa_ok($conf, 'Config::ApacheExtended');

# test 3
ok($conf->parse);

# tests 4-5
my $foobar = $conf->block(FooBar => 'baz test');
ok($foobar);
isa_ok($foobar, 'Config::ApacheExtended');

# tests 6-7
my $foo = $foobar->get('foo');
ok($foo);
is($foo, 'bar');
