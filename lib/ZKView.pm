# ZKView
# Abstract functions around ZooKeeper clusters
package ZKView;
#
# Nikhil Mulley 
#
# https://github.com/mnikhil-git/zoopark
#

use Carp;
use Config::IniFiles;
use Data::Dumper;
use Net::ZooKeeper qw(:node_flags :acls);
use ZKMon;


use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $DEBUG $HOSTNAME);

$VERSION = '0.01';
@EXPORT = qw (get_cluster_names);

sub new {

    my $class = shift;
    my %args = @_;

    my $self = bless {
                file => $args{file},
               }, $class;
    
    return $self;
} 


sub _read_config {

    my $self = shift;
    my %conf;
    if ($self->{file}) {
        tie %conf, 'Config::IniFiles', ( -file => $self->{file} );
    } else {
       croak "Please specify the ini ZooKeeper ensembles in INI file : $@ ";
    }
    $self->{zkensembles} = \%conf;

}

sub get_cluster_names {

    my $self = shift;
    my $zkclusters;
    $self->_read_config;

    if ($self->{zkensembles}) {
        return keys %{$self->{zkensembles}};
    }

}

sub get_cluster_conf {

    my $self = shift;
    my $zk_cluster = shift;

    if ($zk_cluster) {
         $self->_read_config;
         if ($self->{zkensembles}) {
             return $self->{zkensembles}{$zk_cluster};
         }
    }

}


sub get_cluster_hosts {

    my $self = shift;
    my $zk_cluster = shift;

    if ($zk_cluster) {
        $self->_read_config;
        if ($self->{zkensembles}) {
            return keys %{$self->{zkensembles}{$zk_cluster}};
        }
    }

}

sub get_cluster_info {

    my $self = shift;
    my $zk_cluster = shift;

    my $zkmon = new ZKMon;
    my $zkinfo;

    if ($zk_cluster) {
        my $zkconf = $self->get_cluster_conf($zk_cluster);
        foreach my $zkhost ( sort keys %{$zkconf} ) {
            $zkinfo->{$zkhost} = $zkmon->stat($zkhost, $zkconf->{$zkhost});
            $zkinfo->{$zkhost}->{zkport} = $zkconf->{$zkhost};
        }
    }
    $zkmon = undef;
    return $zkinfo;

}

sub get_cluster_leader {

    my $self = shift;
    my $zk_cluster = shift;
    my $zk_leader_port = shift;
    
    my $zkinfo;
    if ($zk_cluster) {
        my $zkinfo = $self->get_cluster_info($zk_cluster);
        foreach my $zkhost ( sort keys %{$zkinfo} ) {
            if ($zkinfo->{$zkhost}->{Mode} eq 'leader') {
                $zk_leader_port ? return "$zkhost:$zkinfo->{$zkhost}->{zkport}" : return $zkhost ;
            }
        }
    }

}

sub get_zk_quorom {

    my $self = shift;
    my $zk_cluster = shift;
    my $zk_quorom = ();

    if ($zk_cluster) {
        my $zkinfo = $self->get_cluster_info($zk_cluster);
        foreach my $zkhost ( sort keys %{$zkinfo} ) {
            $zk_quorom .= "$zkhost:$zkinfo->{$zkhost}->{zkport},";
        }
        return $zk_quorom;
    }

}

sub get_zk_fsinfo {

    my $self = shift;
    my $zk_cluster = shift;
    my $zkpath = shift;
    
    my $zk_fsinfo = ();
    #my $zkleader = $self->get_cluster_leader($zk_cluster, 1);
    my $zk_quorom = $self->get_zk_quorom($zk_cluster);
    my $zkclient = Net::ZooKeeper->new($zk_quorom);
    my $zkstat = $zkclient->stat();
    
    if ($zkclient->exists($zkpath, 'stat' => $zkstat)) {
        while (my($k,$v) = each(%{$zkstat})) {
            $zk_fsinfo->{'zk_statinfo'}->{$k} = $v;
        }
        $zk_fsinfo->{'zk_statinfo'}->{'zkpath'} = $zkpath;
        $zk_fsinfo->{'zk_statinfo'}->{'zkcluster'} = $zk_cluster;

        @{$zk_fsinfo->{'zk_children'}} = $zkclient->get_children($zkpath);

        $zk_fsinfo->{'zk_acls'} = ($zkclient->get_acl($zkpath))[0];
        
        $zk_fsinfo->{'zk_data'} = $zkclient->get($zkpath, 'stat' => $zkstat);
    }
    return $zk_fsinfo;
}

1;
