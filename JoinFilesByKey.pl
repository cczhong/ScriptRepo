#!/usr/bin/perl -w
use strict;
use Getopt::Long;

# Join two tables by their common keys 

my $file1;			# the first file
my $file2;			# the second file
my $col1;			  # the column IDs in the first file, separated by ','
my $col2;			  # the column IDs in the second file, separated by ','
my $merge;      # whether to merge the delimitors
my $print_mode = 0;     # 0: only print matched keys; 1: print all keys in file 1 and no unmatched key in file 2
                        # 2: print all keys in file 2 and no unmatched key in file 1; 3: print all matched and unmatched keys in file 1 and 2
my $rep_str = "-";	# the replacement string for missing data
my $out;			# the output file
my $help;

GetOptions (
  "f1=s" => \$file1,
  "f2=s" => \$file2,
  "c1=s" => \$col1,
  "c2=s" => \$col2,
  "merge" => \$merge,
  "print_mode=i" => \$print_mode,
  "rep=s" => \$rep_str,
  "out=s" => \$out,
  "help" => \$help
) or die("Error in command line arguments\n");

# print help information
if(defined $help || !defined $file1 || !defined $file2 || 
  !defined $col1 || !defined $col2 || !defined $out
)  {
  print "JoinFilesByKey.pl: Join two files through their common keys, fill missing data.\n";  
  print "For faster running time, place the first file as the smaller one and the second as the larger one\n";
  print "Usage: perl JoinFilesByKey.pl --f1=[FILE1] --c1=[COLUMN_KEY1] --f2=[FILE2] --c2=[COLUMN_KEY2] --out=[OUTPUT_FILE]\n";
  print "	--f1: 		the first file\n";
  print "	--f2:		the second file\n";
  print "	--c1:		the key column index (0-based) in the first file, separated by \',\'\n";
  print "	--c2:		the key column index (0-based) in the second file, separated by \',\'\n";
  print "	--merge:  merge the delimiters, default NO\n";
  print "	--print_mode:  print mode selection; \n";
  print "  0: only print matched keys; 1: print all keys in file 1 and no unmatched key in file 2\n";
  print "  2: print all keys in file 2 and no unmatched key in file 1; 3: print all matched and unmatched keys in file 1 and 2\n";
  print "	--out:		the output file\n";
  print "	--rep:		the replacing string in case of missing data, default \'-\'\n";
  print " --help:   print this message\n";
  exit();
}

my @col1_decom = split /\,/, $col1;
my @col2_decom = split /\,/, $col2;

my %col1_hash;  foreach(@col1_decom)  { $col1_hash{$_} = 1;  }
my %col2_hash;  foreach(@col2_decom)  { $col2_hash{$_} = 1;  }

my $num_col1 = 0;
my $num_col2 = 0;

open my $OUT, ">$out" or die "Cannot create file: $!\n";

# read in the files
my %f1_hash;
my %f2_hash;
open my $IN1, "<$file1" or die "Cannot open file: $!\n";
while(<$IN1>)  {
  next if(/^\#/);
  chomp;
  my $line = $_;
  my @decom; 
  if(defined $merge) {@decom = split /\t+/, $line;}
  else  {@decom = split /\t/, $line;};
  # check column consistency
  die "Inconsistent number of columns in FILE1! $num_col1: @decom\n" if($num_col2 != 0 && scalar(@decom) != $num_col1);
  $num_col1 = scalar(@decom);
  # generating the key and the values
  my $key; my $value; my $i;
  for($i = 0; $i < scalar(@col1_decom); ++ $i) {
    $key .= $decom[$col1_decom[$i]] . '**';  # '**' is a special character combination that should not be contained in the data
  }
  for($i = 0; $i < scalar(@decom); ++ $i) {
    if(! exists $col1_hash{$i}) {
      $value .= $decom[$i] . '**';
    } 
  }
  $f1_hash{$key} = $value;
}
close $IN1;

open my $IN2, "<$file2" or die "Cannot open file: $!\n";
while(<$IN2>)  {
  next if(/^\#/);
  chomp;
  my $line = $_;
  my @decom; 
  if(defined $merge) {@decom = split /\t+/, $line;}
  else  {@decom = split /\t/, $line;};
  # check column consistency
  die "Inconsistent number of columns in FILE2! $num_col2: @decom\n" if($num_col2 != 0 && scalar(@decom) != $num_col2);
  $num_col2 = scalar(@decom);
  # generating the key and thev alue
  my $key; my $value; my $i;
  for($i = 0; $i < scalar(@col2_decom); ++ $i) {
    $key .= $decom[$col2_decom[$i]] . '**';  # '**' is a special character combination that should not be contained in the data
  }
  #print "$key $print_mode\n";
  next if (!exists $f1_hash{$key} && $print_mode != 2 && $print_mode != 3);
  for($i = 0; $i < scalar(@decom); ++ $i) {
    if(! exists $col2_hash{$i}) {
      $value .= $decom[$i] . '**';
    } 
  }
  $f2_hash{$key} = $value;
  #print "$key $value\n";
}
close $IN2;

my $exp_col_file1 = $num_col1 - scalar(keys %col1_hash);
my $exp_col_file2 = $num_col2 - scalar(keys %col2_hash);

my $i;

foreach(sort keys %f1_hash)  {
  my $ck = $_;
  if(exists $f2_hash{$ck} || $print_mode == 1 || $print_mode == 3)  {
    my @decom_key = split /\*\*/, $ck;
    my @decom_val = split /\*\*/, $f1_hash{$ck};
    foreach(@decom_key) { print $OUT "$_\t";  }
    foreach(@decom_val) { print $OUT "$_\t";  }
    delete $f1_hash{$ck};
    if(exists $f2_hash{$ck})  {
      my @decom_val2 = split /\*\*/, $f2_hash{$ck};
      for($i = 0; $i < scalar(@decom_val2); ++ $i)  {
        print $OUT "$decom_val2[$i]\t" if $i < scalar(@decom_val2) - 1;
        print $OUT "$decom_val2[$i]\n" if $i == scalar(@decom_val2) - 1;
      } 
      delete $f2_hash{$ck};
    } else  {
      for($i = 0; $i < $exp_col_file2; ++ $i) {
        print $OUT "$rep_str\t" if $i < $exp_col_file2 - 1;
        print $OUT "$rep_str\n" if $i == $exp_col_file2 - 1;
      }
    }
    
  }
  
}

if($print_mode == 2 || $print_mode == 3)  {
  foreach(keys %f2_hash)  {
    my $ck = $_;
    my @decom_key = split /\*\*/, $ck;
    my @decom_val = split /\*\*/, $f2_hash{$ck};
    foreach(@decom_key) { print $OUT "$_\t";  }
    for($i = 0; $i < $exp_col_file1; ++ $i) {   print $OUT "$rep_str\t"; }
    for($i = 0; $i < scalar(@decom_val); ++ $i)  {
      print $OUT "$decom_val[$i]\t" if $i < scalar(@decom_val) - 1;
      print $OUT "$decom_val[$i]\n" if $i == scalar(@decom_val) - 1;
    }  
  }
}
close $OUT;
