#!/usr/bin/perl -w

use strict;
use Getopt::Long;

# simulate singular and duplex reads from a sequence database or two sequence databases

my $duplex;
my $gfile1;
my $gfile2;
my $out;
my $num_simulation = 1000000;
my $is_peptide;
my $rlen = 100;
my $min_dup = 45;
my $max_dup = 50;
my $len_buffer = 0.5;   # the sequence is allowed to be as short as $len_buffer * $rlen
my $error_rate = 0.01;

GetOptions (
  "duplex" => \$duplex,
  "seq1=s" => \$gfile1,
  "seq2=s" => \$gfile2,
  "out=s" => \$out,
  "num=i" => \$num_simulation,
  "len=i" => \$rlen,
  "buffer=f" => \$len_buffer,
  "mindup=i" => \$min_dup,
  "maxdup=i" => \$max_dup,
  "error=f" => \$error_rate,
  "peptide" => \$is_peptide
) or die("Error in command line arguments\n");

if(!defined $gfile1 || (defined $duplex && !defined $gfile2) || !defined $out)  {
  print "GenRandSeq.pl: generate random reads (singular or duplex) from given database.\n";
  print "Usage: perl FastaSubSampling --seq1=[FASTA_FILE] --out=[OUTPUT_FILE]\n";
  print "Usage: perl FastaSubSampling --duplex --seq1=[FASTA_FILE] --seq2=[FASTA_FILE] --out=[OUTPUT_FILE]\n";
  print "	--duplex:	    whether to generate duplex reads\n";
  print "	--seq1:		    the first sequence database\n";
  print "	--seq2:		    the second sequence database\n";
  print "	--out:		    the output file\n";
  print "	--num:		    the number of reads to generate (default 1000000)\n";
  print "	--len:		    the length of the generated reads (default 100)\n";
  print "	--buffer:		the length buffer, i.e. the read can be as short as buffer*len (default 0.5)\n";
  print "	--error:	    the expected error rate (default 0.01)\n";
  print "	--mindup:       the mininum length of each duplex (only effective if --duplex is set, default 45)\n";
  print "	--maxdup:       the maximum length of each duplex (only effective if --duplex is set, default 50)\n";
  print "	--peptide:      the input sequences are peptides (default NO)\n";
  exit();
}

open my $OUT, ">$out" or die "Cannot create file for output: $!\n";

srand(0);
my @alpha;
if(!(defined $is_peptide))    {
    $alpha[0] = 'A'; $alpha[1] = 'C'; $alpha[2] = 'G'; $alpha[3] = 'T';
}   else    {
    $alpha[0] = 'A'; $alpha[1] = 'R'; $alpha[2] = 'N'; $alpha[3] = 'D';
    $alpha[4] = 'C'; $alpha[5] = 'Q'; $alpha[6] = 'E'; $alpha[7] = 'G';
    $alpha[8] = 'H'; $alpha[9] = 'I'; $alpha[10] = 'L'; $alpha[11] = 'K';
    $alpha[12] = 'M'; $alpha[13] = 'F'; $alpha[14] = 'P'; $alpha[15] = 'S';
    $alpha[16] = 'T'; $alpha[17] = 'W'; $alpha[18] = 'Y'; $alpha[19] = 'V';
}
my $alpha_size = scalar(@alpha);

# loads in the first file
my @seq1;
my @name1;
my $id = -1;
open my $IN, "<$gfile1" or die "Cannot open file: $!\n";
while(<$IN>) {
    chomp;
    if(/^\>(.*)/)    {
        ++ $id;
        $name1[$id] = $1;
        #print "$1\n";
        next;
    }
    $seq1[$id] .= uc($_);
}
close $IN;

# loads in the second file if generating duplex sequences
my @seq2;
my @name2;
$id = -1;
if($duplex && defined $gfile2)    {
    open $IN, "<$gfile2" or die "Cannot open file: $!\n";
    while(<$IN>) {
        chomp;
        if(/^\>(.*)/)    {
            ++ $id;
            $name2[$id] = $1;
            #print "$1\n";
            next;
        }
        $seq2[$id] .= uc($_);
    }
    close $IN;
}


if(!(defined $duplex))    {
    while($num_simulation > 0) {
        # generate the sequence
        my $x = int(rand(scalar(@seq1)));
        my $y = int(rand(length($seq1[$x])));
        my $sseq = substr($seq1[$x], $y, $rlen); 
        next if length($sseq) < $len_buffer * $rlen; 
    
        # if no N presents
        # introduce random errors
        my @decom = split //, $sseq;
        for(my $i = 0; $i < scalar(@decom); ++ $i)   {
            my $n1 = rand(1);
            my $ax = int(rand($alpha_size));
            if($n1 < $error_rate)    {
                $decom[$i] = $alpha[$ax];
            }
        }
        $sseq = "";
        for(my $i = 0; $i < scalar(@decom); ++ $i)   {
            $sseq .= $decom[$i]
        }
        
        $y ++;
        my $e = $y + $rlen - 1;
        print $OUT ">$name1[$x]:$y-$e\n$sseq\n";
        -- $num_simulation;
    }
}   else    {
    while($num_simulation > 0) {
        # generate the sequence
        my $x1 = int(rand(scalar(@seq1)));
        my $y1 = int(rand(length($seq1[$x1])));
        my $l1 = $min_dup + int(rand(scalar($max_dup - $min_dup)));

        my $x2 = int(rand(scalar(@seq2)));
        my $y2 = int(rand(length($seq2[$x2])));
        my $l2 = $min_dup + int(rand(scalar($max_dup - $min_dup)));

        my $sseq1 = substr($seq1[$x1], $y1, $l1);
        my $sseq2 = substr($seq2[$x2], $y2, $l2);

        next if(length($sseq1) < $min_dup || length($sseq2) < $min_dup);

        # randomly generate sequence
        my @rs;
        my $tl = $rlen - $l1 - $l2;
        while($tl > 0) {
            my $u = int(rand(3));   # three possible locations, prefix, insert, suffix
            my $v = int(rand(4));   # four possible bases
            $rs[$u] .= $alpha[$v];
            -- $tl;
        }
        my $msseq;
        $msseq .= $rs[0] if defined $rs[0];
        $msseq .=$sseq1;
        $msseq .= $rs[1] if defined $rs[1];
        $msseq .=$sseq2;
        $msseq .= $rs[2] if defined $rs[2];

        #print ">>$sseq\n";   
        # introduce random errors
        my @decom = split //, $msseq;
        for(my $i = 0; $i < scalar(@decom); ++ $i)   {
            my $n1 = rand(1);
            my $ax = int(rand($alpha_size));
            if($n1 < $error_rate)    {
                $decom[$i] = $alpha[$ax];
            }
        }
        $msseq = "";
        for(my $i = 0; $i < scalar(@decom); ++ $i)   {
            $msseq .= $decom[$i]
        }
    
        # if no N presents
        $y1 ++; $y2 ++; # convert to 1-based
        my $e1 = $y1 + $l1 - 1;
        my $e2 = $y2 + $l2 - 1;
        print $OUT ">$name1[$x1]:$y1-$e1||$name2[$x2]:$y2-$e2\n$msseq\n";
        -- $num_simulation;
    }
}
close $OUT;
