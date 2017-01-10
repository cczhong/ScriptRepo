#!/usr/bin/perl -w
use strict;
use Getopt::Long;
use Cwd 'abs_path';
use File::Basename;


# runs Annovar annotation (on a given set of databases) on a specific data set
# only runs the "filter" mode
my $annovar_home = "/home/cczhong/Tools/ANNOVAR";
my $vcf_file;
my $database_id;
my $out_dir;
my $genome_ver;
my $gdir;

GetOptions(
  "vcf=s" => \$vcf_file,
  "db=s" => \$database_id,
  "out=s" => \$out_dir,
  "home=s" => \$annovar_home,
  "genome=s" => \$genome_ver,
  "dir=s" => \$gdir
) or die "Error in argument parsing: $!\n";

if(!defined $vcf_file || !defined $database_id || !defined $out_dir)  {
  print "RunAnnovarSuite.pl: runs Annovar annotation (on a given set of databases) on a specific data set\n";
  print "Usage: perl RunAnnovarSuite.pl --vcf=[RAW_VCF4] --db=[DATABASE_LIST] --out=[OUTPUT_DIRECTORY]\n";
  print "\t--vcf:\tthe VCF4 file for an individual's variances\n";
  print "\t--db:\tthe list of method and database name (tab-delimited), one-per-line\n";
  print "\t\texample:\n";
  print "\t\tfilter	cosmic70\n";
  print "\t\tgeneanno  refGene\n";
  print "\t--home:\tthe home directory of the ANNOVAR software (default \"/home/cczhong/Tools/ANNOVAR\")\n";
  print "\t--genome:\tthe version of genome to use (default hg19)\n";
  print "\t--dir:\tthe directory holding reference database for the corresponding genome (default $annovar_home/humandb)\n";
  print "\t--out:\tthe output directory\n";
  exit();
}

$out_dir = abs_path($out_dir);

if(!-d $out_dir)  {
  mkdir "$out_dir" or die "Cannot create output directory: $!\n";
}

# define default paths
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
  system "perl $annovar_home/annotate_variation.pl -$method -dbtype $db_name -buildver $genome_ver $out_dir/$basename.avinput $gdir --outfile $out_dir/$basename.$db_name --otherinfo";
}
close $IN;
print "Run finished for $vcf_file...Abort.\n";

