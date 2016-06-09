#!/usr/bin/perl -w
use strict;
use Getopt::Long;

my $pfam_file;  	# PFAM alignment, in stockholme format
my $directory;  	# the output directory
my $filter_ID;		# the list of family IDs that are to be retrieved
my $help;			

GetOptions (
  "pfam_db=s" => \$pfam_file,
  "out=s" => \$directory,
  "id=s" => \$filter_ID,
  "help" => \$help
) or die("Error in command line arguments\n");

# print help information
if($help || !defined $pfam_file || !defined $directory)  {  
  print "****************************************\n";
  print "* Extract Pfam reference sequences.\n";
  print "****************************************\n";
  print "Usage: perl RetrievePfamSeqs.pl --pfam_db=[PFAM_IN_STOCKHOME] --out=[OUTPUT_DIR]\n";
  print "	--pfam_db:	the pfam database file in stockhome format\n";
  print "	--out:		the output directory to store the sequences\n";
  print "	--id:		the list of IDs (e.g. PF00010) of interest, one per line (optional)\n";
  print "	--help:		print this information\n";
  exit();
}

# make sure the output directory exists, otherwise create one
if(!(-e "$directory"))  {
  mkdir "$directory" or die "Cannot create directory <$directory>: $!, please check input.\n";
}

# load in the Pfam IDs of interest, if provided
my %IDs_to_pull;
if(defined $filter_ID)  {
  open my $FIN, "<$filter_ID" or die "Cannot open ID file <$filter_ID>: $!, plase check input.\n";
  while(<$FIN>)  {
    chomp;
    $IDs_to_pull{$_} = 1;
  }
  close $FIN;
}

open my $IN, "<$pfam_file" or die "Cannot open Pfam database file <$pfam_file>: $!, please check input.\n";
my @contents;
while(<$IN>) {
  chomp;
  push @contents, $_;
  #print "$_\n";
  if($_ eq '//')  {   # the end of a family
    if($contents[0] eq '# STOCKHOLM 1.0' && $contents[-1] eq '//')  {  # valid infomation
      my $i;
      my $to_pull = 1;	  # indiciate whether the family is of interest
      my $family_name;    # name of the protein family
      my $family_ID;      # accession number of the protein family
      my %sequence_hash;  # hash map between the individual sequence ID and their sequences
      for($i = 1; $i < scalar(@contents) - 1; ++ $i) {
        if($contents[$i] =~ /^\#\=GF\s+ID\s+(\S+)/)  {    # recording family name
          $family_name = $1;
        } elsif($contents[$i] =~ /^\#\=GF\s+AC\s+(\w+\d+)/) {    # recording accessing number
          $family_ID = $1;
          #print "$1\n";
          if(defined $filter_ID and !exists $IDs_to_pull{$family_ID})  {
            # skip this family
            $to_pull = 0;
            last;
          }
        } elsif(substr($contents[$i], 0, 1) ne '#') {    # recording sequence
          my @decom = split /\s+/, $contents[$i];
          $decom[1] =~ s/\-|\.//g;
          $decom[1] = uc($decom[1]);
          $sequence_hash{$decom[0]} .= $decom[1];
        }
      }
      if($to_pull)  {
        # output the sequences
        if(!(-e "$directory/$family_ID"))  {
          mkdir "$directory/$family_ID" or die "Cannot create directory: $!\n";
        }
        foreach(keys %sequence_hash) {
          my $ori_seq_ID = $_;
          my $seq_ID = $_;
	  $seq_ID =~ s/\//\_/g;
          my $out_file_name = "$directory/$family_ID/$seq_ID.fa";
          open my $OUT, ">$out_file_name" or die "Cannot write file: $!\n";
          print $OUT ">$family_ID\:\:$family_name\:\:$seq_ID\n";
          print $OUT "$sequence_hash{$ori_seq_ID}\n";
          close $OUT;
        }
      }
    }
    undef @contents;  # clear the current information block
  }
}
close $IN;
