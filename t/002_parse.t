# -*- perl -*-

# t/002_parse.t - Makes sure that the parser parses properly.

use Test::More tests => 3;

use Config::ApacheExtended;
my $conf = Config::ApacheExtended->new(source => "t/parse.conf");
my $pt = $conf->parse();
ok($pt);
isa_ok($pt, 'Config::ApacheExtended::ParseTree');
is(scalar(keys(%{$pt->getData})), 7);
