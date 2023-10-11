#! /usr/bin/perl
use strict;
use warnings;
use Getopt::Long;

#do this git stuff 20 seconds before the next minute begins to give all the other crons a chance to finish.
sleep 40;

my $cron_logs = 'cron_logs';
GetOptions ("cron-logs=s"  => \$cron_logs)   
or die("Error in command line arguments\n");

# Split the input string into an array of words using the comma as the delimiter
my @words = split(',', $cron_logs);

# Loop through each word in the array
foreach my $cron_log (@words) {

    # Use different pub key to push to dedicated github repository.  
    # Thanks to : https://www.howtogeek.com/devops/how-to-use-a-different-private-ssh-key-for-git-shell-commands/
    my $cron_log_key="$ENV{HOME}/.ssh/$cron_log";
    unless (-f $cron_log_key) {
	die "Missing cron logs ssh key file  $cron_log_key";
    }

    my $toplevel = "$ENV{HOME}/$cron_log";

    system("mkdir -p $toplevel");
    chdir "$toplevel";
    #save to git
    #
    system("git add $toplevel");
    system("git commit -m \"Checking in $toplevel\" $toplevel");
    $ENV{GIT_SSH_COMMAND}="ssh -i $cron_log_key -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no";
    system("git push --set-upstream origin main");
}
