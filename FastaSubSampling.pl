#!/usr/bin/perl -w
use strict;
use Getopt::Long;

# randomly sub-sampling reads from the given FASTA file

my $fasta_file;			# the original fasta file
my $sample_rate;		# the sub-sampling rate (percentage)
my $out1;			# the sequences that are sub-sampled
my $out2;			# the remaining sequences that are not sampled

GetOptions (
  "fasta=s" => \$fasta_file,
  "rate=i" => \$sample_rate,
  "out1=s" => \$out1,
  "out2=s" => \$out2
) or die("Error in command line arguments\n");

if(!defined $fasta_file || !defined $sample_rate || !defined $out1)  {
  print "FastaSubSampling.pl: sub-samples FASTA sequences.\n";
  print "Usage: perl FastaSubSampling --fasta=[FASTA_FILE] --rate=[SUB-SAMPLING_RATE] --out1=[OUTPUT_FILE]\n";
  print "	--fasta:	the FASTA file that need to be subsampled\n";
  print "	--rate:		the sub-sampling rate (percentage, e.g. 10)\n";
  print "	--out1:		the output file that records the sampled sequences\n";
  print "	--out2:		the output file that records the UN-sampled sequences (optional)\n";
  exit();
}

open my $OUT1, ">$out1" or die "Cannot write to file <$out1>: $!, please check input.\n";
my $OUT2;
if(defined $out2)  {
  open $OUT2, ">$out2" or die "Cannot write to file <$out2>: $!, please check input.\n";
}
open my $IN, "<$fasta_file" or die "Cannot open file <$fasta_file>: $!, please check input.\n";
while(<$IN>)  {
  chomp;
  if(/^>/)  {
    my $header = $_;
    my $seq = <$IN>;
    my $roll = rand(100);
    if($roll <= $sample_rate)  {
      print $OUT1 "$header\n$seq";
    }  else  {
      print $OUT2 "$header\n$seq" if defined $out2;
    }
  }
}
close $IN;
close $OUT1;
close $OUT2 if defined $out2;
