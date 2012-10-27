ZOOPARK
=======

A Perl Dancer based Web Dashboard interface  to Apache Hadoop ZooKeeper

INSTALL
=======
 a) install the required perl modules

 $ cat INSTALL_perl | xargs | sudo cpanm --

 b) update & save the configuration of zookeeper cluster ensembles in zkensemble.ini
 
 $ vim zkensemble.ini

Run
====
  a) $ perl bin/app.pl &

  b) Open the browser to the location http://localhost:8081 and see through the content


NOTE: Works on 64-bit Linux Perl. For other versions, do send me a note/open an issue.