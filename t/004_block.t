# -*- perl -*-

# t/004_get.t - Makes sure that we can retrieve blocks using block.

use Test::More tests => 14;
use Data::Dumper;
use Config::ApacheExtended;
my $conf = Config::ApacheExtended->new(source => "t/parse.conf");

# test 1
ok($conf);

# test 2
isa_ok($conf, 'Config::ApacheExtended');

# test 3
ok($conf->parse);

# tests 4-6
my @blocks = $conf->block();
ok(@blocks);
is(scalar(@blocks), 1);
like($blocks[0], qr/foobar/i);

# tests 7-10
my @foobars = $conf->block('FooBar');
ok(@foobars);
is(scalar(@foobars), 1);
like($foobars[0]->[0], qr/foobar/i);
like($foobars[0]->[1], qr/baz test/i);

# tests 11-12
my $foobar = $conf->block(FooBar => 'baz test');
ok($foobar);
isa_ok($foobar, 'Config::ApacheExtended');

# test 13-14
my $bang = $foobar->get('bang');
ok($bang);
is($bang, 'eek');
