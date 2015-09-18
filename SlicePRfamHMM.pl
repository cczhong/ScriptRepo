#!/usr/bin/perl -w
use strict;
use Getopt::Long;

my $pfam_file;			# the combined Pfam or Rfam file
my $out_dir;			# the output directory for individual HM or CV models
my $fext = "hmm";

GetOptions (
  "file=s" => \$pfam_file,
  "out=s" => \$out_dir,
  "ext=s" => \$fext
) or die("Error in command line arguments\n");

if(!defined $pfam_file || !defined $out_dir)  {
  print "SlicePRfamHMM.pl: slicing individual HM or CV model from multi-Pfam/Rfam file\n";
  print "Usage: perl SlicePRfamHMM.pl [P/RFAM_FILE] [OUTPUT_DIRECTORY]\n";
  print "	--file:		the multi-Pfam/Rfam file\n";
  print "	--out:		the output directory for individual models\n"; 
  print "			(please make sure the folder is empty as the program might overwrite existing files)\n";
  print "	--ext:		the file extension (default \'hmm\', suggesting \'cm\' for Rfam models)\n";
  exit;
}

if(!-d $out_dir)  {
  mkdir $out_dir or die "Failed to create the output directory: $!\nAbort.\n";
}

my %accession_count;
open my $IN, "<$pfam_file" or die "Cannot open file: $!\n";
while(<$IN>)  {
  chomp;
  if(/^HMMER/ || /^INFERNAL/)  {
    my @contents;
    my $accession;
    push @contents, $_;
    my $line = "";
    while(!($line =~ /\/\//))  {
      $line = <$IN>;
      chomp $line;
      push @contents, $line;
      if($line =~ /ACC\s+(.*)\./ || $line =~ /ACC\s+(.*)/)  {
        $accession = $1;
      }
    }
    if(defined $accession and !exists $accession_count{$accession})  {
      # create new file to output
      open my $OUT, ">$out_dir/$accession.$fext" or die "Cannot create file:$!\n";
      foreach(@contents)  {
        print $OUT "$_\n";
      }
      close $OUT;
      $accession_count{$accession} = 1;
    }  elsif(defined $accession)  {
      # append to existing file
      open my $OUT, ">>$out_dir/$accession.$fext" or die "Cannot create file:$!\n";
      foreach(@contents)  {
        print $OUT "$_\n";
      }
      close $OUT;
      $accession_count{$accession} = 1;
    }
  }
}
close $IN;
