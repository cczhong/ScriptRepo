#!/usr/bin/perl -w
use strict;
use Getopt::Long;
use File::Basename;

my $fasta_file;			# the multi-fasta file
my $num_part;			# number of partitions
my $out;			# the output directory for the filtered list	

GetOptions (
  "fasta=s" => \$fasta_file,
  "num_part=i" => \$num_part,
  "out=s" => \$out
) or die("Error in command line arguments\n");

# print help information
if(!defined $fasta_file || !defined $num_part || !defined $out)  {
  print "Random partition a large FASTA file into a number of smaller ones\n";
  print "Usage: perl PartitionFASTA.pl --fasta=[FASTA_FILE] --num_part=[NUM_PARTITIONS] --out=[OUT_DIR]\n";
  print "	--fasta:	input FASTA file\n";
  print "	--num_part:	number of partitions\n";
  print "	--out:		output directory\n";
  exit();
}

my @suffixes = qw(.fa .fasta .fn .faa .ffn);
my $fname = basename($fasta_file, @suffixes);

# load in the sequences
sub FastaToHash($$)  {
  my $file = shift;
  my $hash = shift;
  # read file line by line
  open my $IN, "<$file" or die "Cannot open FASTA file, please check input: $!\n";
  my $id;
  while(<$IN>)  {
    chomp;
    my $line = $_;
    if($line =~ /^>/)  {
      $id = $_;
      $hash->{$id} = "";
      #print "$id\n";
    }  else  {
      $hash->{$id} = $hash->{$id} . $_;
      #print "$_\n";
    }
  }
  close $IN;
  return;
}
my %seqhash;
FastaToHash($fasta_file, \%seqhash);

my @ids;
foreach(keys %seqhash)  {
  my $bin = int(rand($num_part));
  push @{$ids[$bin]}, $_;
}

mkdir "$out" or die "Cannot create directory <$out>: $!\n" if (!-d $out);
for(my $i = 0; $i < $num_part; ++ $i)  {
  open my $OUT, ">$out/$fname.$i.fasta" or die "Cannot create file <$out/$fname.$i.fasta>: $!\n";
  for(my $j = 0; $j < scalar(@{$ids[$i]}); ++ $j)  {
    print $OUT ">$ids[$i][$j]\n$seqhash{$ids[$i][$j]}\n"
  }
  close $OUT;
}
