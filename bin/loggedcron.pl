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
my $cron_logs = 'cron_logs';
GetOptions ("skip-repeats"  => \$skip_repeats,
            "cron-logs=s" => \$cron_logs,   
            "path-resolution=s" => \$path_resolution,   
            "path-head=s" => \$path_head)   
or die("Error in command line arguments\n");

#if no path_head specified then use command as path_head
if ($path_head eq '') {
    my ($short_command, $unused_command_path) = fileparse($ARGV[0]);
    $path_head=$short_command;
}
my $toplevel = "$ENV{HOME}/$cron_logs/$path_head";

my $long_command = `which $ARGV[0]`;
chomp($long_command);

system("mkdir -p $toplevel");
chdir "$toplevel";

shift @ARGV;
foreach (@ARGV) {
    $long_command .= /\s/ ?   " \'" . $_ . "\'"
                  :           " "   . $_;
}

# run command, capture results.
my $command_results = `$long_command`;
chomp($command_results);

#save previous results at top level
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
--------- what follows is output from: $long_command ---------
$command_results
END
close $filehandle or die "unable to close file";
