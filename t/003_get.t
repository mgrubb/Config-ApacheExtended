# -*- perl -*-

# t/003_get.t - Makes sure that we can retrieve values using get.

use Test::More tests => 28;
use Data::Dumper;
use Config::ApacheExtended;
my $conf = Config::ApacheExtended->new(source => "t/parse.conf", ignore_case => 0);

# test 1
ok($conf);

# test 2
isa_ok($conf, 'Config::ApacheExtended');

# test 3
ok($conf->parse);

# tests 4-5
my $noval = $conf->get('NoVal');
ok($noval);
is($noval,1);

# tests 6-11
my @bar = $conf->get('Bar');
my $bar = $conf->get('Bar');
ok(@bar);
ok($bar);
is(scalar(@bar),2);
is(ref($bar), 'ARRAY');
is($bar[0], 'baz');
is($bar[1], 'bang');

# tests 12-13
my $smulti = $conf->get('SingleValMultiLine');
ok($smulti);
is($smulti,'Single value across lines');

# tests 14-20
my @mmulti = $conf->get('MultilineTest');
my $mmulti = $conf->get('MultilineTest');
ok(@mmulti);
ok($mmulti);
is(scalar(@mmulti), 3);
is(ref($mmulti), 'ARRAY');
is($mmulti[0], 'Multi');
is($mmulti[1], 'values');
is($mmulti[2], 'across lines');

# tests 21-22
my $hereto = $conf->get('HeretoTest');
ok($hereto);
is($hereto, "These lines are inserted\nverbatim into HeretoTest\nvariable expansion to come.\n");

# tests 23-24
my $foo = $conf->get('Foo');
ok($foo);
is($foo, 'bar');

# test 25
my $foobar = $conf->get('FooBar');
ok(!$foobar);

# tests 26-27
my @keys = $conf->get();
ok(@keys);
#diag("Keys: [" . join(",",@keys) . "]");
is(scalar(@keys), 6);

# tests 28
my $foocs = $conf->get('foo');
ok(!$foocs);
