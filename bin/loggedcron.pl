#! /usr/bin/perl
use strict;
use warnings;
use File::Basename qw(fileparse);

# run command, store results, exit if results is empty string
my $command_results=`@ARGV`;
chomp($command_results);
if ("$command_results" eq "") {
    exit;
}

#derive filename and path from command and date
my ($short_command, $unused_command_path) = fileparse($ARGV[0]);
my $filename=`date +%Y-%m-%d__%H-%M-%S`;
chomp($filename);
my ($year)= ("$1") if($filename=~ /(\d*)-/);
my $path = "$ENV{HOME}/cron_logs/$short_command/$year";


#create and enter new directory
system("mkdir -p $path");
chdir "$path";

#write results to file
my $date=`date`;
chomp($date);
open my $filehandle, '>', "$filename" or die "unable to open file";
print $filehandle <<END;
THIS SCRIPT  : $0
RUNNING      : @ARGV
DATE         : $date
-------------------------------------------------------------------------
$command_results
END
close $filehandle or die "unable to close file";

#save to git
system("git add .");
system("git commit -m \"running @ARGV\" .");
system("git push");
