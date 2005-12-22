use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Apache::LangPrefCookie',
    VERSION_FROM      => 'lib/Apache/LangPrefCookie.pm', # finds $VERSION
    PREREQ_PM         => { 'Apache' => 0, 'Apache::Request' => 0, 'Apache::Cookie' => 0 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Apache/LangPrefCookie.pm', # retrieve abstract from module
       AUTHOR         => 'Hansjoerg Pehofer <hansjoerg.pehofer@uibk.ac.at>') : ()),
);
