use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Config::ApacheExtended',
    VERSION_FROM => 'lib/Config/ApacheExtended.pm', # finds $VERSION
    AUTHOR       => 'Michael Grubb (mgrubb-cpan@fifthvision.net)',
    ABSTRACT     => '',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
					 'Parse::RecDescent' => 1.80,
                    },
);
