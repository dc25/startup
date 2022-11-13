#! /usr/bin/perl
use strict;
use warnings;
use File::Basename qw(fileparse);

# run command, capture results.
my $command_results=`@ARGV`;
chomp($command_results);

#derive previous results filename from command
my ($short_command, $unused_command_path) = fileparse($ARGV[0]);
my $toplevel = "$ENV{HOME}/cron_logs/$short_command";
my $previous_results_file = "$toplevel/previous_results";
#If previous results exist and are identical to current results then exit w/o writing anything.
if (-f $previous_results_file) {
    my $previous_results = `cat $previous_results_file`;
    chomp($previous_results);
    if ($previous_results eq $command_results) {
        exit;
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
my ($year)= ("$1") if($filename=~ /(\d*)-/);
my $path = "$toplevel/$year";
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
