
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.3601"
  },
  "configure_requires" => {
    "ExtUtils::MakeMaker" => "6.30",
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Filter out the noise of a huge IRC channel by lowering The Cone Of Silence",
  "dist_author" => [
    "Mike Doherty <doherty\@cpan.org>"
  ],
  "dist_name" => "Cone-Of-Silence",
  "dist_version" => "0.001",
  "license" => "perl",
  "module_name" => "Cone::Of::Silence",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Xchat" => 0,
    "perl" => "v5.10.1",
    "strict" => 0,
    "utf8" => 0,
    "warnings" => 0
  },
  "script_files" => [
    "bin/cos.pl"
  ]
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
