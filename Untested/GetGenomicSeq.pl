#!/usr/bin/perl -w
use strict;

# assuming that the entire genome is put into the same file in FASTA format
# also assuming 1-based indexing system

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
      $line =~ /^>(\S+)/;      
      $id = $1;
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

sub RevComp($)  {
  my $seq = shift;
  my @decom = split //, $seq;
  @decom = reverse @decom;
  my $new_seq = "";
  foreach(@decom) {
    if($_ eq 'a')  {
      $new_seq .= 't';
    } elsif($_ eq 'c') {
      $new_seq .= 'g';
    } elsif($_ eq 'g') {
      $new_seq .= 'c';
    } elsif($_ eq 't') {
      $new_seq .= 'a';
    } if($_ eq 'A')  {
      $new_seq .= 'T';
    } elsif($_ eq 'C') {
      $new_seq .= 'G';
    } elsif($_ eq 'G') {
      $new_seq .= 'C';
    } elsif($_ eq 'T') {
      $new_seq .= 'A';
    } else  {
      $new_seq .= 'N';
    }
  }
  return $new_seq;
}


my $fasta_file = shift;
my $gloc_list = shift;
my $out_file = shift;

my @genome_loc;
open my $IN, "<$gloc_list" or die "Cannot open file: $!\n";
while(<$IN>) {
  chomp; push @genome_loc, $_;
}
close $IN;

my %seq_hash;
FastaToHash($fasta_file, \%seq_hash);

my $OUT;
if(defined $out_file)  {
  open $OUT, ">$out_file" or die "Cannot create file: $!\n";
} 

# parse each genomic location in the list
foreach(@genome_loc) {
  my $loc_id = $_;
  if($loc_id =~ /(\S+):(\d+)\-(\d+)/)  {
    my $chrom = $1; my $left = $2; my $right = $3;
    if(!exists $seq_hash{$chrom}) {
      print "Warning: $loc_id: chromosome $chrom does not exist in sequence database, skipping...\n";
      next;
    }  
    if($left < $right)  {
      my $seq = substr($seq_hash{$chrom}, $left + 1, $right - $left + 1);
      if(defined $out_file) {
        print $OUT ">$loc_id\n$seq\n";
      } else  {
        print "$loc_id\n$seq\n";
      }  
    } else  {
      my $seq = substr($seq_hash{$chrom}, $right + 1, $left - $right + 1);
      $seq = RevComp($seq);
      if(defined $out_file) {
        print $OUT ">$loc_id\n$seq\n";
      } else  {
        print "$loc_id\n$seq\n";
      }  
    }   
  } else  {
    print "Warning: $loc_id is not in correct format, skipping...\n";
  }
}
