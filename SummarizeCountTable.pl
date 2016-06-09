#!/usr/bin/perl -w
use strict;
use Getopt::Long;

# count the occurrence of values(categorical) in a column from multiple files
# and summarize the counts into a table
# Example:
# In file 1:
#   apple
#   apple
#   pear
#
# In file 2:
#   pear
#   pear
#   orange
#
# The resulting table will be:
#   apple   2   0
#   pear    1   2
#   orange  0   1


my $files;		# the input files, separated by semicolumn ";"
my $cols;		# the columns to be summarized in the files, 0-based
my $out;		# the output file

GetOptions  (
  "files=s" => \$files,
  "cols=s" => \$cols,
  "out=s" => \$out
) or die "Error in command-line arguments!\n";

if(!defined $files || !defined $cols)  {
  print "SummarizeCountTable.pl: Count the occurrence of values(categorical) in a column from multiple files and summarize the counts into a table.\n";
  print "Usage: perl SummarizeCountTable.pl --files=[FILE] --cols=[COLUMN_ID] --out=[OUTPUT_FILE]\n";
  print "	--files:        the input file names, separated by \",\", e.g. file1,file2,file3,...\n";
  print "	--cols:         the corresponding column IDs, separated by \",\", e.g. 0,1,0,...\n";
  print "	--out:          the output file\n\n";
  exit();
}

my $OUT;
if(defined $out)    {
    open $OUT, ">$out" or die "Cannot create file for output: $!\n";
}

my @file = split /\,/, $files;
my @col = split /\,/, $cols;

if(scalar(@file) != scalar(@col))    {
    die "Inconsistent number of fields in files and columns; abort.\n";
}

my @header;
push @header, "#NAME";
push @header, @file;
my %hash;
for(my $i = 0; $i < scalar(@file); ++ $i)   {
    open my $IN, "<$file[$i]" or die "Cannot open file: $!\n";
    while(<$IN>) {
        chomp;
        my @decom = split /\s+/, $_;
        die "Error: There are no $col[$i] columns in file $file[$$i]; abort\n" if (scalar(@decom) - 1 < $col[$i]);
        if(!exists $hash{$decom[$col[$i]]})    {
            my @empty = (0) x scalar(@file);
            $hash{$decom[$col[$i]]} = \@empty;
        }
        # increase the count here
        ${$hash{$decom[$col[$i]]}}[$i] ++;
    }
    close $IN;
}


for(my $i = 0; $i < scalar(@header) - 1; ++ $i)   {
    print "$header[$i]\t" if !defined $out;
    print $OUT "$header[$i]\t" if defined $out;
}
print "$header[-1]\n" if !defined $out;
print $OUT "$header[-1]\n" if defined $out;
foreach(sort keys %hash)   {
    my $name = $_;
    print "$name\t" if !defined $out;
    print $OUT "$name\t" if defined $out;
    for(my $i = 0; $i < scalar(@{$hash{$name}}) - 1; ++ $i)   {
        print "${$hash{$name}}[$i]\t" if !defined $out;
        print $OUT "${$hash{$name}}[$i]\t" if defined $out;
    }
    print "${$hash{$name}}[-1]\n" if !defined $out;
    print $OUT "${$hash{$name}}[-1]\n" if defined $out;
}

close $OUT if defined $out;










