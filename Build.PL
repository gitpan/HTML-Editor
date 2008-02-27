use strict;
use Module::Build;
use vars qw( $settings $skip);
my $class = Module::Build->subclass(class => "Module::Build::Custom", code => <<'SUBCLASS' );
my $release = 'blib/rhtml/';
my $dir     = 'htdocs/';
my $path = '.';
sub ACTION_build {
        my $self = shift;
        &change($dir);
        $release = 'blib/perl/';
        $dir     = 'cgi-bin/';
        &change($dir);
}
sub change {
        my $d = shift;
        chomp($d);
        opendir(IN, $d) or warn "cant open $d $!:$/";
        my @files = readdir(IN);
        closedir(IN);
        for(my $i = 0 ; $i <= $#files ; $i++) {
                unless ($files[$i] =~ /^\./) {
                        my $c = $d . $files[$i];
                        my $e = $c;
                        $e =~ s/^$dir(.*)/$1/;
                        unless (-d $d . $files[$i]) {
                                system(" cp " . $c . " $release/$e") unless (-e $release . "/" . $e && $files[$i] =~ /\~$/);
                        } else {
                                system("mkdir -p $release/$e") unless (-e $release . "/" . $e);
                                &change($d . $files[$i] . "/");
                        }
                }
        }
}
SUBCLASS
my $inctance = $class->new(
        get_options => {skip => {store => \$skip},},
        module_name => 'HTML::Editor',
        requires => {
            'Test::More' => ">=0.7",
            'Module::Build' => ">=0.2808",
            'Test::Pod' =>  ">=1.26",
            'Test::Pod::Coverage' =>  ">=0.55",
            'CGI::QuickApp' => '>=0.25',
            'Template::Quick'  => '>=0.25',
            'HTML::Window'  => '>=0.25',
            'HTML::Entities' => ">=1.35",
            'Syntax::Highlight::Perl' => ">=1.00",
},
($] >= 5.005 ? (AUTHOR => 'Dirk Lindner <lze@cpan.org>') : ()),
dist_abstract => 'BBCode & html editor',
license => 'lgpl',
create_makefile_pl => 'passthrough',
);
$inctance->{properties}{htd} = "/srv/www/htdocs";
$inctance->{properties}{cgi}  = "/srv/www/cgi-bin";

eval 'use CGI::QuickApp::Settings qw($settings loadSettings saveSettings)';
unless ($@) {
        loadSettings();
        *settings    = \$CGI::QuickApp::Settings::settings;
        $inctance->{properties}{htd}          = $settings->{cgi}{DocumentRoot} if -e $settings->{cgi}{DocumentRoot};
        $inctance->{properties}{cgi}         = $settings->{cgi}{bin} if -e $settings->{cgi}{bin};
}
$inctance->{properties}{cgi}         = $inctance->args('cgi')         if $inctance->args('cgi');
$inctance->{properties}{htd}         = $inctance->args('htd')         if $inctance->args('htd');
unless ($skip){
        $inctance->{properties}{htd}  = Module::Build->prompt("Where is your Document root ?",     $inctance->{properties}{htd} );
         $inctance->{properties}{cgi}  = Module::Build->prompt("Where is your cgi-bin Directory ?",$inctance->{properties}{cgi});
}else{
        print "Document root: $inctance->{properties}{htd}$/cgi-bin Directory:$inctance->{properties}{cgi}$/";
}
$inctance->{properties}{install_path}{perl} = $inctance->{properties}{cgi};
$inctance->{properties}{install_path}{rhtml} = $inctance->{properties}{htd};
$inctance->create_build_script;
