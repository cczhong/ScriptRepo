#!/usr/bin/perl -w
use strict;
use Getopt::Long;
use Cwd 'abs_path';
use File::Basename;

# runs Annovar annotation (on a given set of databases) on a specific data set
# only runs the "filter" mode

my $vcf_file;
my $database_id;
my $out_dir;

GetOptions(
  "vcf=s" => \$vcf_file,
  "db=s" => \$database_id,
  "out=s" => \$out_dir
) or die "Error in argument parsing: $!\n";

if(!defined $vcf_file || !defined $database_id || !defined $out_dir)  {
  print "RunAnnovarSuite.pl: runs Annovar annotation (on a given set of databases) on a specific data set\n";
  print "Usage: perl RunAnnovarSuite.pl --vcf=[RAW_VCF4] --db=[DATABASE_LIST] --out=[OUTPUT_DIRECTORY]\n";
  print "	--vcf:		the VCF4 file for an individual's variances\n";
  print "	--db:		the list of method and database name (tab-delimited), one-per-line\n";
  print "			example:\n";
  print "			filter	cosmic70\n";
  print "	--out:		the output directory\n";
  exit();
}

$out_dir = abs_path($out_dir);

if(!-d $out_dir)  {
  mkdir "$out_dir" or die "Cannot create output directory: $!\n";
}

# define default paths
my $annovar_home = "/home/cczhong/Tools/ANNOVAR";
my $hg_ver = "hg19";
my $basename = basename($vcf_file, ".vcf");

# prepare avinput
print "\n*********************************\n";
print "Preparing ANNOVAR input...\n";
print "*********************************\n";
system "perl $annovar_home/convert2annovar.pl -format vcf4old $vcf_file > $out_dir/$basename.avinput";
# run input databases one-by-one
open my $IN, "<$database_id" or die "Cannot open file <$database_id>: $!\n";
while(<$IN>)  {
  next if /^\#/;	# skip comments
  chomp;
  my @decom = split /\s+/, $_;
  my $method = $decom[0];
  my $db_name = $decom[1];
  print "\n*********************************\n";
  print "Searching database $db_name...\n";
  print "*********************************\n";
  system "perl $annovar_home/annotate_variation.pl -$method -dbtype $db_name -buildver $hg_ver $out_dir/$basename.avinput $annovar_home/humandb/ --outfile $out_dir/$basename.$db_name --otherinfo";
}
close $IN;
print "Run finished for $vcf_file...Abort.\n";

