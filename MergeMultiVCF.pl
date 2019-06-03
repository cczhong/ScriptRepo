#!/usr/bin/perl -w
use strict;
use Getopt::Long;

# merge multiple VCF files

my $files1;
my $files2;
my $info_col;
my $help;

GetOptions (
  "f1=s" => \$files1,
  "f2=s" => \$files2,
  "c=i" => \$info_col,
  "help" => \$help
) or die("Error in command line arguments\n");

if($help or (!defined $files1 and !defined $files2) or !defined $info_col)    {
    print "Usage: perl MergeMultiVCF.pl [FILES_IN_GROUP1] [FILES_IN_GROUP2] [INFORMATION_COLUMN_ID]\n";
    print "--f1:    files in the first group, separated by colon \',\'\n";
    print "--f2:    files in the second group, separated by colon \',\'\n";
    print "--c:     the column id that holds the variant information\n";
    print "--help:  print this information\n";
}

# reads in the key values of the variants
my %existHash;
my @files1;
my @files2;
@files1 = split /\,/, $files1 if defined $files1;
@files2 = split /\,/, $files2 if defined $files2;
foreach(@files1)   {
    open my $IN, "<$_" or die "Cannot open file: $!\n";
    while(<$IN>) {
        next if (/^\#/);
        chomp;
        my @decom = split /\t/, $_;
        if(!($decom[0] =~ /chrUn/) && !($decom[0] =~ /random/) && !($decom[0] =~ /hap/))    {
            my $key = $decom[0] . '||' . $decom[1] . '||' . $decom[3] . '||' . $decom[4] . '||' . $decom[8];
            $existHash{$key} = 1;
        }
    }
    close $IN;
}

foreach(@files2)   {
    open my $IN, "<$_" or die "Cannot open file: $!\n";
    while(<$IN>) {
        next if (/^\#/);
        chomp;
        my @decom = split /\t/, $_;
        if(!($decom[0] =~ /chrUn/) && !($decom[0] =~ /random/) && !($decom[0] =~ /hap/))    {
            my $key = $decom[0] . '||' . $decom[1] . '||' . $decom[3] . '||' . $decom[4] . '||' . $decom[8];
            $existHash{$key} = 1;
        }
    }
    close $IN;
}

# fill up the info table
my @info;
my $n = 0;
my $num_files = scalar(@files1) + scalar(@files2);
foreach(sort keys %existHash)   {
    my $key = $_;
    my @decom = split /\|\|/, $key;
    for(my $i = 0; $i < $num_files; ++ $i)   {
        push @decom, '-';
    } 
    push @decom, 0;     # this is the number of occurences in sample group 1
    push @decom, 0;     # this is the number of occurences in sample group 2
    push @info, \@decom;
    $existHash{$key} = $n ++;
} 

# fill up the variant quality information
@files1 = split /\,/, $files1 if defined $files1;
@files2 = split /\,/, $files2 if defined $files2;
my $k = 0;
foreach(@files1)   {
    open my $IN, "<$_" or die "Cannot open file: $!\n";
    while(<$IN>) {
        next if (/^\#/);
        chomp;
        my @decom = split /\t/, $_;
        if(!($decom[0] =~ /chrUn/) && !($decom[0] =~ /random/) && !($decom[0] =~ /hap/))    {
            my $key = $decom[0] . '||' . $decom[1] . '||' . $decom[3] . '||' . $decom[4] . '||' . $decom[8];
            $info[$existHash{$key}][$k + 5] = $decom[$info_col];
            $info[$existHash{$key}][$num_files + 5] ++;     # count the occurence of this variation in sample group 1
        }
    }
    close $IN;
    ++ $k;
}

foreach(@files2)   {
    open my $IN, "<$_" or die "Cannot open file: $!\n";
    while(<$IN>) {
        next if (/^\#/);
        chomp;
        my @decom = split /\t/, $_;
        if(!($decom[0] =~ /chrUn/) && !($decom[0] =~ /random/) && !($decom[0] =~ /hap/))    {
            my $key = $decom[0] . '||' . $decom[1] . '||' . $decom[3] . '||' . $decom[4] . '||' . $decom[8];
            $info[$existHash{$key}][$k + 5] = $decom[$info_col];
            $info[$existHash{$key}][$num_files + 6] ++;     # count the occurence of this variation in sample group 2
        }
    }
    close $IN;
    ++ $k;
}

@files1 = split /\,/, $files1 if defined $files1;
@files2 = split /\,/, $files2 if defined $files2;
print "#CHROM\tPOS\tREF\tALT\tFORMAT\t";
foreach(@files1)    {
    print "$_\t";
}
foreach(@files2)    {
    print "$_\t";
}
print "Num_Group1\tNumGroup2\n";

for(my $i = 0; $i < scalar(@info); ++ $i)   {
    for(my $j = 0; $j < $num_files + 6; ++ $j)   {
        print "$info[$i][$j]\t";
    }
    print "$info[$i][-1]\n";
}





