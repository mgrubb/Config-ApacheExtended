# -*- perl -*-

# t/002_parse.t - Makes sure that the parser parses properly.

use Test::More 'no_plan';

use Config::ApacheExtended;

my $conf = Config::ApacheExtended->new(source => "t/parse.conf");
$conf->parse();
use Data::Dumper;

diag(Dumper($conf));
