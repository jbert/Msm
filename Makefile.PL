use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Msm',
    AUTHOR              => q{John Berthels <jjberthels@gmail.com>},
    VERSION_FROM        => 'lib/Msm.pm',
    ABSTRACT_FROM       => 'lib/Msm.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Msm-*' },
);
