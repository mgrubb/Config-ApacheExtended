# -*- perl -*-

# t/007_include.t - Tests the include feature

use Test::More "no_plan";
use Config::ApacheExtended;
my $conf = Config::ApacheExtended->new(source => "t/include.conf", expand_vars => 1, inherit_vals => 1, honor_include => 1);

# test 1
ok($conf);

# test 2
isa_ok($conf, 'Config::ApacheExtended');

# test 3
ok($conf->parse);

# tests 4-7
my $inctest = $conf->get( 'IncludeTest' );
ok($inctest);
is($inctest,'inc');
my $foo = $conf->get('Foo');
ok($foo);
is($foo,'bar');

TODO: {
local $TODO = "Directory include not done";
}
