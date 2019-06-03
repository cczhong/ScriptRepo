#!/usr/bin/perl -w
use strict;
use Getopt::Long;

# get the genomic sequence by a given ID; output the fasta format

my $list;
my $gfile;
my $interval;
my $out,
my $help;

GetOptions(
  "list=s" => \$list,
  "ref=s" => \$gfile,
  "intv=s" => \$interval,
  "out=s" => \$out,
  "help" => \$help
) or die ("Error in command line arguments\n");

if(!defined $gfile || (!defined $list && !defined $interval) || defined $help)  {
  print "GetGenomeSeq.pl: get sequence from the reference genome and output as FASTA\n";
  print "Usage: perl GetGenomeSeq.pl --list=[LIST_OF_INTERVAL] --ref=[REF_GENOME]\n";
  print "	--list:\tinterval list; 4-5 fields per line: chromosome begin end strand  annotation(optional)\n";
  print "	--ref:\tthe reference genome in FASTA format\n";
  print "	--intv:\tfetch single interval only; format example:\"chr1:23-1213-\" or \"chrX:1234-23234+\"\n";
  print "	--out:\twirte to the file instead of STDOUT\n";
  print "	--help:\tprint this message\n";
  exit();
}

# output output file if specified
my $OUT;
open $OUT, ">$out" or die "Cannot create file: $!\n" if defined $out;

# loads in the intervals
my %to_fetch;

if(defined $interval)  {
  $interval =~ /(chr\S+)\:(\d+)\-(\d+)([+-])/;
  my @interval = ($2, $3, $4);
  push @{$to_fetch{$1}}, \@interval;
}

if(defined $list)  {
  open my $LIN, "<$list" or die "Cannot open file: $!\n";
  while(<$LIN>) {
    chomp;
    my @decom = split /\s+/, $_;
    my $chr = $decom[0]; shift @decom;
    push @{$to_fetch{$chr}}, \@decom;
  }
  close $LIN;
}

# sort the intervals within each chromosome
foreach(keys %to_fetch) {
  @{$to_fetch{$_}} = 
    sort {$a->[0] <=> $b->[0] || $a->[1] <=> $b->[1]} 
    @{$to_fetch{$_}};
  #for(my $i = 0; $i < scalar(@{$to_fetch{$_}}); ++ $i) {
  #  print "${$to_fetch{$_}}[$i]->[0]\t${$to_fetch{$_}}[$i]->[1]\t${$to_fetch{$_}}[$i]->[2]\n";
  #}
}

# load in the reference genome
open my $GIN, "<$gfile" or die "Cannot open genome file: $!\n";
my $cchrom;
my $cbegin = 1;
my $cend = 0;
my $cseq;
my $tag = 0;
my $itv_index = 0;    # index to the interval in the to_fetch hash
while(<$GIN>) {
  chomp;
  if(/^>(\S+)/)  {
    $tag = 0;   # reset check chromosome tag to false
    $itv_index = 0;
    $cchrom = $1;
    $cbegin = 1;  $cend = 0;
    $tag = 1 if(exists $to_fetch{$cchrom});  
  } elsif($tag) {
    $cend = $cend + length($_);
    $cseq .= $_;
    #print "$cbegin  $cend $cseq\n";
    while($itv_index < scalar(@{$to_fetch{$cchrom}})) {
      if(${$to_fetch{$cchrom}}[$itv_index]->[0] >= $cbegin && ${$to_fetch{$cchrom}}[$itv_index]->[1] <= $cend)  {
        # we can output the sequence
        my $st = substr($cseq, ${$to_fetch{$cchrom}}[$itv_index]->[0] - $cbegin, 
          ${$to_fetch{$cchrom}}[$itv_index]->[1] - ${$to_fetch{$cchrom}}[$itv_index]->[0] + 1
        );
        $st = uc($st);
        if(${$to_fetch{$cchrom}}[$itv_index]->[2] eq '-')  {
          # perform reverse complement
          my $tst = $st;
          $st = "";
          for(my $i = length($tst) - 1; $i >= 0; -- $i) {
            my $c = substr($tst, $i, 1);
            if($c eq 'T') { $c = 'A'; }
            elsif($c eq 'A') { $c = 'T'; }
            elsif($c eq 'G') { $c = 'C'; }
            elsif($c eq 'C') { $c = 'G'; }
            elsif($c eq 'N') { $c = 'N'; }
            print "Unknown genomic sequence found in reference: $tst::$c\n"
              if($c ne 'T' && $c ne 'A' && $c ne 'C' && $c ne 'G' && $c ne 'N');
            $st .= $c;
          }
        }
        if(defined $OUT)  {
          print $OUT ">$cchrom:${$to_fetch{$cchrom}}[$itv_index]->[0]-${$to_fetch{$cchrom}}[$itv_index]->[1]${$to_fetch{$cchrom}}[$itv_index]->[2]";
          print $OUT "||${$to_fetch{$cchrom}}[$itv_index]->[3]\n" if defined ${$to_fetch{$cchrom}}[$itv_index]->[3];
          print $OUT "\n" if !defined ${$to_fetch{$cchrom}}[$itv_index]->[3];
          print $OUT "$st\n";
        } else  {
          print ">$cchrom:${$to_fetch{$cchrom}}[$itv_index]->[0]-${$to_fetch{$cchrom}}[$itv_index]->[1]${$to_fetch{$cchrom}}[$itv_index]->[2]";
          print "||${$to_fetch{$cchrom}}[$itv_index]->[3]\n" if defined ${$to_fetch{$cchrom}}[$itv_index]->[3];
          print "\n" if !defined ${$to_fetch{$cchrom}}[$itv_index]->[3];
          print "$st\n";
        }
      } elsif(${$to_fetch{$cchrom}}[$itv_index]->[0] >= $cbegin && 
          ${$to_fetch{$cchrom}}[$itv_index]->[0] <= $cend && ${$to_fetch{$cchrom}}[$itv_index]->[1] > $cend
      ) {
        # this means we need to read in more sequence to get the output; do nothing
        last;
      } elsif(${$to_fetch{$cchrom}}[$itv_index]->[0] > $cend) {
        # this means we can skip the sequence; it will never be referred
        $cbegin = $cend + 1;
        $cseq = "";
        last;
      }
      ++ $itv_index;
    }  
  }
}
close $GIN;

