#!/usr/bin/perl -w
use strict;
use Getopt::Long;

# Join two tables by their common keys 

my $file1;			# the first file
my $file2;			# the second file
my $col1;			# the column IDs in the first file, separated by ','
my $col2;			# the column IDs in the second file, separated by ','
my $merge;    # whether to merge the delimitors
my $print_unmatch;  # whether to print the unmatched entries
my $rep_str = "-";		# the replacement string for missing data
my $out;			# the output file

GetOptions (
  "f1=s" => \$file1,
  "f2=s" => \$file2,
  "c1=s" => \$col1,
  "c2=s" => \$col2,
  "merge" => \$merge,
  "print_unmatch" => \$print_unmatch,
  "rep=s" => \$rep_str,
  "out=s" => \$out
) or die("Error in command line arguments\n");

# print help information
if(!defined $file1 || !defined $file2 || 
  !defined $col1 || !defined $col2 || 
  !defined $out
)  {
  print "JoinFilesByKey.pl: Join two files through their common keys, fill missing data.\n";  
  print "Usage: perl JoinFilesByKey.pl --f1=[FILE1] --c1=[COLUMN_KEY1] --f2=[FILE2] --c2=[COLUMN_KEY2] --out=[OUTPUT_FILE]\n";
  print "	--f1: 		the first file\n";
  print "	--f2:		the second file\n";
  print "	--c1:		the key column index (0-based) in the first file\n";
  print "	--c2:		the key column index (0-based) in the second file\n";
  print "	--merge:  merge the delimiters, default NO\n";
  print "	--print_unmatch:  print the unmatched entries, default NO\n";
  print "	--out:		the output file\n";
  print "	--rep:		the replacing string in case of missing data, default \'-\'\n";
  exit();
}

open my $OUT, ">$out" or die "Cannot create file: $!\n";

# read in the files
my $num_col1 = 0;
my $num_col2 = 0;
my %f1_hash;
my %f2_hash;
open my $IN1, "<$file1" or die "Cannot open file: $!\n";
while(<$IN1>)  {
  next if(/^\#/);
  chomp;
  my $line = $_ . "\tfoo";
  my @decom; 
  if(defined $merge) {@decom = split /\t+/, $line;}
  else  {@decom = split /\t/, $line;};
  if(($num_col1 > 0 and scalar(@decom) != $num_col1) || $col1 > scalar(@decom) - 1)  {
    print "$num_col1: @decom\n";
    die "Inconsistent number of columns in FILE1!\n";
  }
  $num_col1 = scalar(@decom);
  $f1_hash{$decom[$col1]} = $line;
}
close $IN1;

open my $IN2, "<$file2" or die "Cannot open file: $!\n";
while(<$IN2>)  {
  next if(/^\#/);
  chomp;
  my $line = $_ . "\tfoo";
  my @decom; 
  if(defined $merge) {@decom = split /\t+/, $line;}
  else  {@decom = split /\t/, $line;};
  if(($num_col2 > 0 and scalar(@decom) != $num_col2) || $col2 > scalar(@decom) - 1)  {
    print "$num_col2: @decom\n";
    die "Inconsistent number of columns in FILE2!\n";
  }
  $num_col2 = scalar(@decom);
  $f2_hash{$decom[$col2]} = $line;
}
close $IN2;

foreach(sort keys %f1_hash)  {
  my $ck = $_;
  if(exists $f2_hash{$ck} || defined $print_unmatch)  {
    print $OUT "$ck\t";
    my @decom; 
    if(defined $merge) {@decom = split /\t+/, $f1_hash{$ck};}
    else  {@decom = split /\t/, $f1_hash{$ck};}
    for(my $i = 0; $i < scalar(@decom) - 1; ++ $i)  {
      print $OUT "$decom[$i]\t" if($i != $col1);
    }
    if(exists $f2_hash{$ck})  {
      my @decom2; 
      if(defined $merge) {@decom2 = split /\t+/, $f2_hash{$ck};}
      else  {@decom2 = split /\t/, $f2_hash{$ck};};
      for(my $i = 0; $i < scalar(@decom2) - 1; ++ $i)  {
        print $OUT "$decom2[$i]\t" if($i != $col2);
      }
      delete $f2_hash{$ck};
    }  elsif(defined $print_unmatch)  {
      for(my $i = 0; $i < $num_col2 - 2; ++ $i)  {
        print $OUT "$rep_str\t";
      }
    }
    print $OUT "\n";
  }
}

if(defined $print_unmatch)  {
  foreach(sort keys %f2_hash)  {
    my $ck = $_;
    print $OUT "$ck\t";
    for(my $i = 0; $i < $num_col1 - 2; ++ $i)  {
      print $OUT "$rep_str\t";
    }
    my @decom2; 
    if(defined $merge) {@decom2 = split /\t+/, $f2_hash{$ck};}
    else  {@decom2 = split /\t/, $f2_hash{$ck};};
    for(my $i = 0; $i < scalar(@decom2) - 1; ++ $i)  {
      print $OUT "$decom2[$i]\t" if($i != $col2);
    }
    print $OUT "\n";
  }
}
close $OUT;
