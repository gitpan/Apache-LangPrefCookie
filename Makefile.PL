use 5.006;
use ExtUtils::MakeMaker;
use Apache::TestMM qw(test clean); 

# prerequisites
my %require =
  (
    "Apache::Test" => "", # any version will do
  );
my @scripts = qw(t/TEST);
# accept the configs from command line
Apache::TestMM::filter_args();
Apache::TestMM::generate_script('t/TEST');

WriteMakefile(
              NAME              => 'Apache::LangPrefCookie',
              VERSION_FROM      => 'lib/Apache/LangPrefCookie.pm', # finds $VERSION
              PREREQ_PM         => { 'Apache' => 0, 'Apache::Request' => 0, 'Apache::Cookie' => 0 }, # e.g., Module::Name => 1.1
              ABSTRACT_FROM     => 'lib/Apache/LangPrefCookie.pm', # retrieve abstract from module
              AUTHOR            => 'Hansjoerg Pehofer <hansjoerg.pehofer@uibk.ac.at>',
              clean => {
                        FILES => "@{ clean_files() }",
                       },
             );

sub clean_files {
    return [@scripts];
}
