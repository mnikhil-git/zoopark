use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'zoopark',
    AUTHOR              => q{Nikhil Mulley <mnikhil@gmail.com>},
    VERSION_FROM        => 'lib/zoopark.pm',
    ABSTRACT            => 'WebUI to ZooKeeper Cluster(s)',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'Apache Software License')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'YAML'       => 0,
        'Dancer'     => 1.3095,
        'Template'   => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'zoopark-*' },
);
