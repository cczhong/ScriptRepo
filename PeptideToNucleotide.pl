#!/usr/bin/perl -w
use strict;
use Getopt::Long;

# reverse-translate peptide read back to nucleotide read, using a designated codon

my $file;		# the peptide file in FASTA format
my $out;		# the reverse-translated nucleotide file in FASTA format

GetOptions(
  "file=s" => \$file,
  "out=s" => \$out
) or die "Error in command-line arguments!";

if(!defined $file || !defined $out)  {
  print "PeptideToNucleotide.pl: reverse-translate a peptide sequence to nucleotide sequecne\n";
  print "Usage: perl PeptideToNucletide.pl --file=[INPUT_PEPTIDE] --out=[OUTPUT_NUCLEOTIDE]\n";
  print "	--file:		the input peptide file in FASTA format\n";
  print "	--out:		the output nucleotide file in FASTA format\n";
  exit();
}

my %rt_hash;

# hard-code the reverse translate mapping, codon picked based on lexicographical order
$rt_hash{"F"} = "TTT";
$rt_hash{"L"} = "TTA";
$rt_hash{"I"} = "ATT";
$rt_hash{"M"} = "ATG";
$rt_hash{"V"} = "GTT";
$rt_hash{"S"} = "TCT";
$rt_hash{"P"} = "CCT";
$rt_hash{"T"} = "ACT";
$rt_hash{"A"} = "GCT";
$rt_hash{"Y"} = "TAT";
$rt_hash{"H"} = "CAT";
$rt_hash{"Q"} = "CAA";
$rt_hash{"N"} = "AAT";
$rt_hash{"K"} = "AAA";
$rt_hash{"D"} = "GAT";
$rt_hash{"E"} = "GAA";
$rt_hash{"C"} = "TGT";
$rt_hash{"W"} = "UTT";
$rt_hash{"R"} = "CGT";
$rt_hash{"G"} = "GGT";
$rt_hash{"X"} = "NNN";

# reads in the file and reverse translate
open my $IN, "<$file" or die "Cannot open file <$file>: $!, please check input\n";
open my $OUT, ">$out" or die "Cannot write to file <$out>: $!, please check input\n";
while(<$IN>)  {
  chomp;
  if(/^>/)  {
    print $OUT "$_\n";
  }  else  {
    my @decom = split //, $_;
    foreach(@decom)  {
      if(exists $rt_hash{$_})  {
        print $OUT "$rt_hash{$_}";
      }  else  {
        close $IN;
        close $OUT;
        die "Unrecognized amino acid label: $_\n";
      }
    }
    print $OUT "\n";
  }
}
close $OUT;
close $IN;
