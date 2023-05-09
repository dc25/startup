#! /usr/bin/perl
use strict;
use warnings;

# Use different pub key to push to dedicated github repository.  
# Thanks to : https://www.howtogeek.com/devops/how-to-use-a-different-private-ssh-key-for-git-shell-commands/
my $cron_logs_key="$ENV{HOME}/.ssh/cron_logs";
unless (-f $cron_logs_key) {
    die "Missing cron logs ssh key file  $cron_logs_key";
}

#do this git stuff 20 seconds before the next minute begins to give all the other crons a chance to finish.
sleep 40;
my $toplevel = "$ENV{HOME}/cron_logs";

system("mkdir -p $toplevel");
chdir "$toplevel";
#save to git
#
system("git add $toplevel");
system("git commit -m \"Checking in $toplevel\" $toplevel");
$ENV{GIT_SSH_COMMAND}="ssh -i $cron_logs_key -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no";
system("git push");
