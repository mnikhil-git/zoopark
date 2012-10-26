package zoopark;
use Dancer ':syntax';
use strict;
use warnings;
use Cwd;
use Sys::Hostname;
use Data::Dumper;
use ZKView;

our $VERSION = &config->{'appversion'};
our $zkview = new ZKView (file => &config->{'zookeeper_ensembles'});
our @zk_cluster_names =  sort $zkview->get_cluster_names();


get '/' => sub {
    template 'index', {
               zk_ensembles => \@zk_cluster_names,
             };
};

get '/view/:zkname' => sub {
    my $zkinfo =  $zkview->get_cluster_info(param('zkname'));
    template 'view', {
             zk_ensembles => \@zk_cluster_names,
             zk_ensemble => param('zkname'),
             zk_info => $zkinfo,
    };
};

get qr{/fs/([\w-]+)/(.?|.+)}x => sub {
     my ($zkcluster, $zkpath) = splat;
     $zkpath = "/$zkpath" if ($zkpath eq "" || $zkpath !~ /^\//) ;
     if (($zkcluster =~ /[\w-]/) && ($zkpath =~ /^\/.*\/$/)) {
         $zkpath =~ s/\/$//;
     }
     my $zk_fsinfo = $zkview->get_zk_fsinfo($zkcluster, $zkpath);
     template 'fs', {
             zk_ensembles => \@zk_cluster_names,
             zk_ensemble => $zkcluster,
             zkpath => $zkpath,
             zkfsinfo => $zk_fsinfo,
             zkparent => sub { 
                 my ($string) = (@_);
                 my $parent = ();
                 ($parent = $string) =~ s/(.*)\/.*/$1/; 
                 return $parent; 
                 },
     };
};

get '/about' => sub {
    template 'index', {
	    app_zk_ensembles => 1,
         };
};

get '/deploy' => sub {
    template 'deployment_wizard', {
		directory => getcwd(),
		hostname  => hostname(),
		proxy_port=> 8000,
		cgi_type  => "fast",
		fast_static_files => 1,
	};
};

#The user clicked "updated", generate new Apache/lighttpd/nginx stubs
post '/deploy' => sub {
    my $project_dir = param('input_project_directory') || "";
    my $hostname = param('input_hostname') || "" ;
    my $proxy_port = param('input_proxy_port') || "";
    my $cgi_type = param('input_cgi_type') || "fast";
    my $fast_static_files = param('input_fast_static_files') || 0;

    template 'deployment_wizard', {
		directory => $project_dir,
		hostname  => $hostname,
		proxy_port=> $proxy_port,
		cgi_type  => $cgi_type,
		fast_static_files => $fast_static_files,
	};
};

true;
