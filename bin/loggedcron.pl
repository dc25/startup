#! /usr/bin/perl
use strict;
use warnings;
use File::Basename qw(fileparse);
use Getopt::Long;
use Switch;


# thanks to: https://stackoverflow.com/a/8289657/509928
my $script_command = $0;
foreach (@ARGV) {
$script_command .= /\s/ ?   " \'" . $_ . "\'"
                :           " "   . $_;
}

my $skip_repeats = '';
my $path_resolution = 'year';
my $path_head = '';
GetOptions ("skip-repeats"  => \$skip_repeats,
            "path-resolution=s" => \$path_resolution,   
            "path-head=s" => \$path_head)   
or die("Error in command line arguments\n");

# run command, capture results.
my $command_results=`@ARGV`;
chomp($command_results);

#derive previous results filename from command
if ($path_head eq '') {
    my ($short_command, $unused_command_path) = fileparse($ARGV[0]);
    $path_head=$short_command;
}
my $toplevel = "$ENV{HOME}/cron_logs/$path_head";
my $previous_results_file = "$toplevel/previous_results";
#If previous results exist and are identical to current results then exit w/o writing anything.
if ($skip_repeats) {
    if (-f $previous_results_file) {
        my $previous_results = `cat $previous_results_file`;
        chomp($previous_results);
        if ($previous_results eq $command_results) {
            exit;
        }
    }
}

# Save current command results as new previous results.
system("mkdir -p $toplevel");
open my $prev_results_filehandle, '>', "$previous_results_file" or die "Unable to open previous results file for writing.";
print $prev_results_filehandle <<END;
$command_results
END
close $prev_results_filehandle or die "Unable to close previous results file.";

#create and enter new directory
my $filename=`date +%Y-%m-%d__%H-%M-%S`;
chomp($filename);
my ($year,$month,$day,$hour)= ("$1","$2","$3","$4") if($filename=~ /(\d*)-(\d*)-(\d*)__(\d*)/);

# assign to path based on path resolution from command line. defaults to year.
my $path = "";
switch($path_resolution) {
    case "year"  {$path="${toplevel}/${year}"}
    case "month" {$path="${toplevel}/${year}/${month}"}
    case "day"   {$path="${toplevel}/${year}/${month}/${day}"}
    case "hour"  {$path="${toplevel}/${year}/${month}/${day}/${hour}"}
    else         { die "Invalid path_resolution option: $path_resolution" }
}
system("mkdir -p $path");
chdir "$path";

#write results to file
my $date=`date`;
chomp($date);
open my $filehandle, '>', "$filename" or die "unable to open file";
print $filehandle <<END;
COMMAND      : $script_command
DATE         : $date
--------- what follows is output from: @ARGV ---------
$command_results
END
close $filehandle or die "unable to close file";

#save to git
#
# Use different pub key for dedicated github repository.  
# Thanks to : https://www.howtogeek.com/devops/how-to-use-a-different-private-ssh-key-for-git-shell-commands/
#
# Only attempt to do git commands if ssh key exists.
#
my $cron_logs_key="$ENV{HOME}/.ssh/cron_logs";
print "$cron_logs_key";
if (-f $cron_logs_key) {
    $ENV{GIT_SSH_COMMAND}="ssh -i $cron_logs_key -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no";
    system("git add .");
    system("git commit -m \"running @ARGV\" .");
    system("git push");
}
