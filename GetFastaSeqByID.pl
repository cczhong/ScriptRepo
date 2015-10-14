#!/usr/bin/perl -w
use strict;
use Getopt::Long;

my $fasta_file;			# the multi-fasta file
my $id_list;			# the ids that needs to be pulled out, one in a line
my $out;			# the output file for the filtered list
my $pattern = 0;		# treat rows in id_list as patterns
my $reverse = 0;		# if the tag is set, output sequences that are NOT in the id_list
my $verbose = 0;		# verbose
my $phead = 0;			# the pattern must begin at the header
my $ptail = 0;			# the pattern must end at the header
my $header_append = "";		# the text to be appended to the end of the header when output
my $help = 0;			# print help information

GetOptions (
  "fasta=s" => \$fasta_file,
  "id=s" => \$id_list,
  "out=s" => \$out,
  "pattern" => \$pattern,
  "phead" => \$phead,
  "ptail" => \$ptail,
  "reverse" => \$reverse,
  "verbose" => \$verbose,
  "append" => \$header_append,
  "help" => \$help
) or die("Error in command line arguments\n");

# print help information
if($help || !defined $fasta_file || !defined $id_list || !defined $out)  {
  print "\n";  
  print "Usage: perl GetFastaSeqByID.pl --fasta=[FASTA_FILE] --id=[ID_LIST_FILE] --out=[OUTPUT_FILE]\n";
  print "	--fasta:	the multi-fasta file that contains the sequences\n";
  print "	--id:		the file contains IDs of interest, one per row (do not contain '>')\n";
  print "	--out:		the file in which the filtered sequences are written into\n";
  print "	--pattern:	treat IDs as keywords (instead of strict match)\n";
  print "	--phead:	requiring that the keywords must be prefix of the header\n";
  print "	--ptail:	requiring that the keywords must be suffix of the header\n";
  print "	--reverse:	output sequences that do NOT match the IDs\n";
  print "	--verbose:	print intermediate information\n";
  print "	--append:	the text to be appended to the end of the original header\n";
  print "	--help:		print this information\n";
  print "\n";
  exit;
}

# load IDs
my %ID_hash;
open my $IIN, "<$id_list" or die "Cannot open ID file, please check input: $!\n";
while(<$IIN>)  {
  chomp;
  $ID_hash{$_} = 1;
}
close $IIN;

# subroutine for searching a list of keywords
sub KWordSearchBatch($$$$)  {
  my $s = shift;	# the string to be matched
  my $p = shift;	# reference to an array of patterns
  my $phead = shift;
  my $ptail = shift;
  foreach(@{$p})  {
    if((!$phead && !$ptail && $s =~ /\Q$_\E/) or
       ($phead && $s =~ /^\Q$_\E/) or
       ($ptail && $s =~ /\Q$_\E$/)
    )  {	# if keyword is found, return true 
      #print "$s	$_\n";
      return 1;
    }
  }
  return 0;
}

# process reads one-by-one
open my $OUT, ">$out" or die "Cannot create output file, please check input: $!\n";
open my $SEQIN, "<$fasta_file" or die "Cannot open FASTA file, please check input: $!\n";
my $tag = 0;
while(<$SEQIN>)  {
  chomp;
  if(/^>(.*)/)  {	# begins of a read
    my $rid = $1;
    my $found;
    if(!$pattern)  {	# looks for perfect match
      $found = exists $ID_hash{$rid};
    }  else  {		# checks for keyword matching
      my @kw = keys %ID_hash;
      $found = KWordSearchBatch($rid, \@kw, $phead, $ptail);
      #print "$rid	$found\n";
    }
    if(($found and !$reverse) or (!$found and $reverse))  {
      $tag = 1;
      if(length($header_append) > 0)  {
        print $OUT ">$rid\_$header_append\n";
      }  else  {
        print $OUT ">$rid\n";
      }
    }  else  {
      $tag = 0;
    }
  }  else  {
    print $OUT "$_\n" if $tag;
  }
}
close $SEQIN;
close $OUT;
