#!/usr/bin/perl -w
use strict;
use Getopt::Long;

# Join tab separated tables by their common keys

my $file_pivot;			  # the pivot file
my $files;    			  # the files to be joined, separated by ','
my $folder;           # the folder that contains the files to be joined
my $col_pivot = 0;		# the column IDs for pivot file
my $cols = 0;     	  # the column IDs for files to be joined, separated by ','
my $col_folder = 0;   # the column ID for all files in the folder
my $null_str = "N/A";	# the replacement string for missing data
my $union;            # whether to print union of key
my $header;           # whether to consider header for files to be joined
my $out;			        # the output file
my $help;

GetOptions (
  "pivot=s" => \$file_pivot,
  "files=s" => \$files,
  "folder=s" => \$folder,
  "col_pivot=s" => \$col_pivot,
  "cols=s" => \$cols,
  "col_folder=s" => \$col_folder,
  "null_str=s" => \$null_str,
  "union" => \$union,
  "header" => \$header,
  "out=s" => \$out,
  "help" => \$help
) or die("Error in command line arguments\n");

# print help information
if(defined $help || !defined $out || (!defined $files && !defined $folder) ||
    (defined $files && defined $folder) || (defined $file_pivot && !defined $col_pivot) ||
    (defined $files && !defined $cols) || (defined $folder && !defined $col_folder)
)  {
  print "JoinMultipleFiles.pl: Join multiple tables based on their common keys\n";  
  print "Usage: perl JoinMultipleFiles.pl --files=[FILES_TO_JOIN] --cols=[COLUMNS_OF_KEYS] --out=[OUTPUT_FILE]\n";
  print "\tOR\n";
  print "Usage: perl JoinMultipleFiles.pl --folder=[FOLDER] --col_folder=[COLUMN_OF_KEYS] --out=[OUTPUT_FILE]\n";
  print "\t--pivot:\tthe reference list of keys; no header is allowed\n";
  print "\t--files:\tthe files to be joined, separated by \',\' (mutually exclusive with --folder)\n";
  print "\t--folder:\tthe folder containing files to be joined (mutually exclusive with --files)\n";
  print "\t--col_pivot:\tthe column ID for key in the pivot file; must be set if --pivot is set\n";
  print "\t--cols:\t\tthe column IDs for keys in the files to be joined, separated by \',\';\n";    
  print "\t\t\tmust be set if --files is set;\n"; 
  print "\t\t\tmust have one-to-one correspondence with arguments for --files\n";
  print "\t--col_folder:\tthe column ID for keys in files in folder;\n"; 
  print "\t\t\tmust be set if --folder is set; used for all files in folder\n";
  print "\t--union:\ttake union of keys as reference is --pivot is not set, defualt FALSE\n";
  print "\t--header:\tassume the header present in files to be joined, default FALSE\n";
  print "\t--out:\t\tthe output file\n";
  print "\t--null_str:\tthe replacing string in case of missing data, default \'N\/A\'\n";
  exit();
}

# calculating the number of columns in a file
sub GetNumColumns($)  {
  my $file = shift;
  my $num_cols;
  open my $IN, "<$file" or die "GetNumColumns::Cannot open file: $!\n";
  while(<$IN>) {
    chomp;
    my @decom = split /\t/, $_;
    if(defined $num_cols && $num_cols != scalar(@decom))  {
      $num_cols = -1;
      print "Warning: $file is not a valid tab-separated file!\n";
    }
    $num_cols = scalar(@decom);
  }
  close $IN;
  return $num_cols;
}

# get the stem of a path
sub GetFileStem($) {
  my $path = shift;
  my @decom = split //, $path;
  my $i;  
  for($i = scalar(@decom) - 1; $i >= 0; -- $i) {
    last if $decom[$i] eq "\/";
  }
  return substr($path, $i + 1);
}

# sanity check
my $num_col_pivot;
if(defined $file_pivot)  {
  $num_col_pivot = GetNumColumns($file_pivot);
  die "$file_pivot is not valid tab-separated file" if ($num_col_pivot <= $col_pivot);
}
my %num_cols;
my %key_cols;
if(defined $files)  {
  my @infiles = split /\,/, $files;
  my @incols = split /\,/, $cols;
  die "Number of files to be joined is inconsistent with key columns advised, abort\n";
  for(my $i = 0; $i < scalar(@infiles); ++ $i) {
    my $nc = GetNumColumns($infiles[$i]);
    die "$infiles[$i] is not valid tab-separated file" if ($nc <= $incols[$i]);
    $num_cols{$infiles[$i]} = $nc;
    $key_cols{$infiles[$i]} = $incols[$i];
  }
}
if(defined $folder)  {
  foreach(<$folder/*>) {
    my $f = $_;
    my $nc = GetNumColumns($f);
    die "$f is not valid tab-separated file" if ($nc <= $col_folder);
    $num_cols{$f} = $nc;  $key_cols{$f} = $col_folder;
  }
}
if(scalar keys %num_cols <= 0)  {
  die "No valid file to be joined; abort.\nPlease use --help to view options\n";
}

# identifying the reference keys
my @ref_keys;
if(defined $file_pivot)  {
  open my $IN, "<$file_pivot" or die "Cannot open file: $!\n";
  while(<$IN>) {
    chomp; my @decom = split /\t/, $_;
    push @ref_keys, $decom[$col_pivot];
  }
  close $IN;
} else {
  my %ck_keys;
  foreach(keys %key_cols) {
    my $f = $_;
    open my $IN, "<$f" or die "Cannot open file: $!\n";
    <$IN> if $header;
    while(<$IN>) {
      chomp; my @decom = split /\t/, $_;
      $ck_keys{$decom[$key_cols{$f}]} += 1;
    }
    close $IN;
  }
  foreach(sort keys %ck_keys) {
    push @ref_keys, $_ if($union || $ck_keys{$_} == scalar(keys %key_cols))
  }
}

# load in information into hash table / take care of the header information
my @headers; push @headers, "#Major_Key";
my @read_files;
my %info;
foreach(sort keys %key_cols) {
  my $f = $_;
  push @read_files, $f;
  my $fstem = GetFileStem($f);
  open my $IN, "<$f" or die "Cannot open file: $!\n";
  # handle the header
  if($header) {
    # appending file stem to the headers
    my $h = <$IN>; chomp $h; my @decom = split /\t/, $h;
    for(my $i = 0; $i < scalar(@decom); ++ $i) {
      $decom[$i] =~ s/\s/\_/g;  push @headers, $fstem . '::' . $decom[$i];
    }
  } else  {
    for(my $i = 1; $i <= $num_cols{$f}; ++ $i) {
      push @headers, $fstem . '::col_' . $i; 
    }
  }  
  # record the information into two-dimensional hash table
  while(<$IN>) {
    chomp; my @decom = split /\t/, $_;
    $info{$f}{$decom[$key_cols{$f}]} = $_;
  }
  close $IN;
}

# gernate the merged table
open my $OUT, ">$out" or die "Cannot create file for output: $!\n";
for(my $i = 0; $i < scalar(@headers); ++ $i) {
  if($i < scalar(@headers) - 1) { print $OUT "$headers[$i]\t";  }
  else {  print $OUT "$headers[$i]";  }
}
print $OUT "\n";
for(my $i = 0; $i < scalar(@ref_keys); ++ $i) {
  print $OUT "$ref_keys[$i]\t";  
  for(my $j = 0; $j < scalar(@read_files); ++ $j) {
    my @to_print;
    if(exists $info{$read_files[$j]}{$ref_keys[$i]})  {
      @to_print = split /\t/, $info{$read_files[$j]}{$ref_keys[$i]};
    } else  {
      for(my $k = 0; $k < $num_cols{$read_files[$j]}; ++ $k) {  push @to_print, $null_str;  }
    }
    for(my $k = 0; $k < scalar(@to_print); ++ $k) {
      if($j == scalar(@read_files) - 1 && $k == scalar(@to_print) - 1)  {
        print $OUT "$to_print[$k]";
      } else  { print $OUT "$to_print[$k]\t";  }
    }
  }
  print $OUT "\n";
}

