#!/usr/bin/perl -w
use strict;
use Getopt::Long;

my $fq_file;
my $fa_file;

GetOptions (
  "fq=s" => \$fq_file,
  "fa=s" => \$fa_file
) or die("Error in command line arguments\n");

if(!defined $fq_file || !defined $fa_file)  {
  print "Fasta2Fastq.pl:  convert FASTA format to FASTQ format\n";
  print "Usage: perl Fasta2Fastq.pl --fq=[FASTQ_FILE] --fa=[FASTA_FILE]\n";
  print " --fq:   the FASTQ file\n";
  print " --fa:   the FASTA file\n";
  exit;
}

open my $IN, "<$fa_file" or die "Cannot open FASTA file: $!\n";
open my $OUT, ">$fq_file" or die "Cannot create FASTQ file: $!\n";

my $n = 0;
while(<$IN>)  {
  chomp;
  my $line = $_;
  ++ $n;
  if($n % 2 == 1 && $line =~ /^>/)  {
    $line =~ s/^\>/\@/;
    print $OUT "$line\n";
    my $seq = <$IN>; ++ $n;
    chomp $seq;
    print $OUT "$seq\n";
    $line =~ s/^\@/\+/;
    print $OUT "$line\n";
    my $qual = 'I' x length($seq);
    print $OUT "$qual\n";
  }
}
close $IN;
close $OUT;
