#!/usr/bin/perl -w
use strict;
use Getopt::Long;

# a general VCF parser to filter/extract depth-of-coverage and variant allel frequency information

my $vcf;            # the VCF file to be input
my $mindp;          # the minimum depth of coverage for the site
my $maxdp;          # the maximum depth of coverage for the site
my $minaf;          # the minimum allel frequency
my $maxaf;          # the maximum allel frequency
my $checkall;       # only output the record if all fields satisfy the criterion
my $checkone = 1;   # ouput the record if at least one field satisfy the criterion
my $summary;        # summary the DP and allel frequency instead of filtering the VCF
my $info_idx;       # the index for the information field (will be overwritten if header present)
my $format_idx;     # the index for the format field (will be overwritten if header present)
my $out;            # the output file 

GetOptions (
    "vcf=s" => \$vcf,
    "mindp=i" => \$mindp,
    "maxdp=i" => \$maxdp,
    "minaf=f" => \$minaf,
    "maxaf=f" => \$maxaf,
    "checkall" => \$checkall,
    "checkone" => \$checkone,
    "summary" => \$summary,
    "info-column=i" => \$info_idx,
    "format-column=i" => \$format_idx,
    "out=s" => \$out
) or die("Error in command line arguments\n");

if(!defined $vcf || !(defined $mindp || defined $maxdp || defined $minaf || defined $maxaf))    {
    print "VCFDepthParser.pl: General-purpose parser for VCF depth of coverage and allel frequency.\n";
    print "Usage: perl VCFDepthParser.pl --vcf=[VCF_FILE] --(mindp/maxdp/minaf/maxaf)=[CUTOFF_VALUE]\n\n";
    print "\t--vcf:           the VCF file to be parsed\n";
    print "\t--mindp:         cutoff as the minimum depth of coverage\n";
    print "\t--maxdp:         cutoff as the maximum depth of coverage\n";
    print "\t--minaf:         cutoff as the minimum variant allel frequency\n";
    print "\t--maxaf:         cutoff as the maximum variant allel frequency\n";
    print "\t--checkall:      require all individuals parsing the criterion\n";
    print "\t--checkone:      require at least one individual parsing the criterion (default)\n";
    print "\t--summary:       instead of filtering VCF, output readable infomration regarding depth of frequncy and coverage\n";
    print "\t--info-column:   advise the column for the INFO field if header is absent (to be overwritten if header presents)\n";
    print "\t--format-column: advise the column for the FORMAT field if header is absent (to be overwritten if header presents)\n";
    print "\t--out:           the output file (default: STDOUT)\n";
    print "\n";
    exit;
}

# open output file
my $OUT;
if(defined $out)    {
    open $OUT, ">$out" or die "Cannot create file for output!\n";
}

# reads in the content of the VCF file
my @contents;
open my $IN, "<$vcf" or die "Cannot open file: $!\n";
while(<$IN>) {
    chomp;
    push @contents, $_;
}
close $IN;

# parse the last line of the header to define column IDs
my $header_line;
for(my $i = 0; $i < scalar(@contents); ++ $i)   {
    if($contents[$i] =~ /\#CHROM/)    {
        $header_line = $contents[$i];
        my @decom = split /\s+/, $contents[$i];
        for(my $j = 0; $j < scalar(@decom); ++ $j)   {
            if($decom[$j] eq "INFO")    {
                $info_idx = $j;
            }   elsif($decom[$j] eq "FORMAT") {
                $format_idx = $j;
            }
        }
    }
}

# handle header information for summary call
if($summary)    {
    my @summary_header;
    my @decom = split /\s+/, $header_line;
    for(my $i = 0; $i < 5; ++ $i)   {
        push @summary_header, $decom[$i];
    }
    for(my $i = $format_idx + 1; $i < scalar(@decom); ++ $i)   {
        push @summary_header, $decom[$i] . "_DP";
        push @summary_header, $decom[$i] . "_VAF";
    }
    for(my $i = 0; $i < scalar(@summary_header) - 1; ++ $i)   {
        print "$summary_header[$i]\t" if !defined $out;
        print $OUT "$summary_header[$i]\t" if defined $out;
    }
    print "$summary_header[-1]\n" if !defined $out;
    print $OUT "$summary_header[-1]\n" if defined $out;
}

sub CheckCondition($$)  {
    my $dp = shift;
    my $af = shift;
    if($dp eq 'N/A' || $af eq 'N/A')    {
        return 1;
    }   
    if((!defined $mindp || (defined $mindp && $dp >= $mindp)) && 
       (!defined $maxdp || (defined $maxdp && $dp <= $maxdp)) && 
       (!defined $minaf || (defined $minaf && $af >= $minaf)) && 
       (!defined $maxaf || (defined $maxaf && $af <= $maxaf))
    )    {
        return 1;
    }   else    {
        return 0;
    }
}

#print "info_idx: $info_idx\n";
#print "format_idx:  $format_idx\n";

# parsing line-by-line
for(my $i = 0; $i < scalar(@contents); ++ $i)   {
    # handle the header
    if($contents[$i] =~ /\#/)    {
        if(!$summary)    {
            print "$contents[$i]\n" if !defined $out;
            print $OUT "$contents[$i]\n" if defined $out;
        }
        next;
    }
    my $depth;      # the depth of coverage
    my $alt_vaf;    # the variant allel frequncy of the alternative allel
    my $is_pass;    # tag indicating whether the record passes the filter
    # check if it contains DP4 field in INFO field (in this case assume the VCF)
    # contains only one individual's information; likely generated by SAMTOOLS  
    #print "contents:    $contents[$i]\n";  
    my @decom = split /\s+/, $contents[$i];    
    my @info;
    push @info, $decom[0]; push @info, $decom[1]; push @info, $decom[2];
    push @info, $decom[3]; push @info, $decom[4];
    if($contents[$i] =~ /DP4=(\d+),(\d+),(\d+),(\d+)/)    {
        $depth = $1 + $2 + $3 + $4;
        $alt_vaf = ($3 + $4) / $depth;
        push @info, $depth;
        push @info, $alt_vaf;
        #print "depth:   $depth\n";
        #print "alt_vaf: $alt_vaf\n";
        $is_pass = CheckCondition($depth, $alt_vaf);
    }   else    {    
        my @decom2 = split /\:/, $decom[$format_idx];
        my $ad_idx;
        my $dp_idx;
        for(my $j = 0; $j < scalar(@decom2); ++ $j)   {
            if($decom2[$j] eq "AD")    {
                $ad_idx = $j;
            }   elsif($decom2[$j] eq "DP") {
                $dp_idx = $j;
            }
        }
        if(!defined $ad_idx || !defined $dp_idx)    {
            die "The VCF file does not contain enough information (AD and DP fields), abort.\n";
        }
        #print "ad_idx:  $ad_idx\n";
        #print "dp_idx:  $dp_idx\n";
        # parse the fields for all individuals
        $is_pass = 0;
        for(my $j = $format_idx + 1; $j < scalar(@decom); ++ $j)   {
            if($decom[$j] eq "\.\/\.")    {
                $depth = "N/A";
                $alt_vaf = "N/A";
            }   else    {
                my @decom3 = split /\:/, $decom[$j];
                $depth = $decom3[$dp_idx];
                $decom3[$ad_idx] =~ /(\d+)\,(\d+)/;
                $alt_vaf = $2 / $depth;
            }
            push @info, $depth;
            push @info, $alt_vaf;
            my $pass = CheckCondition($depth, $alt_vaf);
            if(!$pass && $checkall)  {
                $is_pass = 0;
            }   elsif($depth ne "N/A" && $alt_vaf ne "N/A" && $pass && $checkone) {
                $is_pass = 1;
            }
        }
    }
    # check if the record is passed
    if($is_pass)    {
        if(!$summary)    {
            print "$contents[$i]\n" if !defined $out;
            print $OUT "$contents[$i]\n" if defined $out;
        }   else    {
            for(my $k = 0; $k < scalar(@info) - 1; ++ $k)   {
                print "$info[$k]\t" if !defined $out;
                print $OUT "$info[$k]\t" if defined $out;
            }
            print "$info[-1]\n" if !defined $out;
            print $OUT "$info[-1]\n" if defined $out;
        }
    }
}

close $OUT if defined $out;








