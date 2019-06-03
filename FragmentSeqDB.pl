#!/usr/bin/perl -w
use strict;
use Getopt::Long;

# a simple script to sample fragments from the given sequence database

my $in_seq_file;
my $out_seq_file;
my $read_len;
my $coverage;
my $error_rate = 0;
my $len_var = 10;

GetOptions(
  "fasta=s" => \$in_seq_file,
  "out=s" => \$out_seq_file,
  "length=i" => \$read_len,
  "depth=i" => \$coverage,
  "error=i" => \$error_rate,
  "len_var=i" => \$len_var
) or die ("Error in command line arguments\n");

if(!defined $in_seq_file || !defined $out_seq_file || !defined $read_len || !defined $coverage)  {
  print "FragmentSeqDB.seq: a simple script to sample fragments from the given sequence database\n";
  print "Usage: perl FragmentSeqDB.seq --fasta=[SEQ_IN] --out=[FRAG_OUT] --length=[FRAG_LEN] --depth=[DEPTH]\n";
  print "	--fasta:	the input sequence database in FASTA format\n";
  print "	--out:		the file for outputing the fragmented reads\n";
  print "	--length:	the length of the fragmented reads (Integer)\n";
  print "	--depth:	the expected sequencing depth/coverage (Integer)\n";
  print "	--error:	the substitution error rate, default=0 (Optional, Percentage, Integer)\n";
  print "	--len_var:	the read length variation, default=10 (Optional, Percentage, Integer)\n";
  exit();
}

# key is the index of the end of the concaternated sequence, 
# value is the header of the sequence
my %alphabet;
my @indexes; my @headers;
my $concat_seq = '$';
open my $IN, "<$in_seq_file" or die "Cannot open file: $!\n";
while(<$IN>)  {
  chomp;
  if(/^>(.*)/)  {
    push @indexes, length($concat_seq) - 1;
    my $header = $1;
    my $seq = <$IN>;
    chomp $seq;
    for(my $i = 0; $i < length($seq); ++ $i)  {
      $alphabet{substr($seq, $i, 1)} = 1;
    }
    $concat_seq .= $seq . '$';	# use the '$' sign as separator of individual sequences 
    push @headers, $header;
  }
}
close $IN;
my @alphabet = keys %alphabet;

sub BinarySearch($$)  {
  my $list = shift;		# the reference to a list of sorted elements to search
  my $kv = shift;		# the key value to search against the list
  my $left = 0;
  my $right = scalar(@{$list});
  while($left < $right)  {
    my $pivot = int(($left + $right) / 2);
    if($list->[$pivot] < $kv)  {
      $left = $pivot + 1;
    }  elsif($list->[$pivot] > $kv)  {
      $right = $pivot - 1;
    }  else  {
      return $pivot;
    }
  }
  # make sure that the index returned is the closest index that has a value greater than the key value
  while($left < scalar(@{$list}) and $list->[$left] < $kv)  {
    ++ $left;
  }
  return $left;
}

#my $i;
#for($i = 0; $i < scalar(@label_hash); ++ $i)  {
#  print "$label_hash[$i][0]	$label_hash[$i][1]\n";
#}

# compute the expected number of reads given the coverage and database size
my $num_reads = int ($coverage * (length($concat_seq) - scalar(@indexes)) / $read_len);
print "Num of reads to generate: $num_reads\n";
open my $OUT, ">$out_seq_file" or die "Cannot create file <$out_seq_file>: $!, please check input\n";
my $to_gen = $num_reads;
my $max_failure = 1000000;	# maximum number of failure allowed in case of ill-defined parameters
while($to_gen > 0)  {
  if($max_failure > 0)  {
    # determine the length of the fragment
    my $sim_len = int(rand($read_len * $len_var * 2 / 100));
    my $mean_len = int($read_len * $len_var * 2 / 100 / 2);
    my $diff_len = $sim_len - $mean_len;
    my $eff_len = $read_len + $diff_len;
    # get the fragmented reads
    my $begin = int(rand(length($concat_seq)));
    my $str = substr($concat_seq, $begin, $eff_len);
    #print "$str\n";
    # check if the sequence contains sequence terminating symbol
    if($str =~ /\$/)  {
      -- $max_failure;
      next;
    }  else  {
      # search the ID of the sequence
      my $index = BinarySearch(\@indexes, $begin);
      my $src_header = $headers[$index - 1];
      # define the region
      my $fid = $num_reads - $to_gen;
      #print "begin:	$begin	index: $index\n";
      my $frag_begin = $begin - $indexes[$index - 1] - 1;
      my $frag_end = $frag_begin + $eff_len - 1;
      if($frag_begin < 0 || $frag_end < 0)  {
        #print "place 2	$index	$indexes[$index]\n";
	#die;
        -- $max_failure;
        next;
      }
      # work on the error rate
      if($error_rate > 0)  {
        for(my $i = 0; $i < length($str); ++ $i) {
          my $e = rand(100);
          if($e < $error_rate)  {
            substr($str, $i, 1) = $alphabet[int(rand(scalar(@alphabet)))];
          }
        }
      }
      # output the results
      print $OUT ">frag_$fid\:\:$src_header\:\:$frag_begin-$frag_end\n";
      print $OUT "$str\n";
      -- $to_gen;
      #print "$max_failure\n";
      $max_failure = 1000000;
    }
  } else {
    die "Maximum number of sampling failure exceeded... Please check input parameters.\n";
  }
}
close $OUT;

