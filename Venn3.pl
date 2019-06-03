#!/usr/bin/perl -w
use strict;

my $f1 = shift;
my $f2 = shift;
my $f3 = shift;

my %commonHash;
my @sampleHash;

open my $IN1, "<$f1" or die "Cannot open file: $!\n";
while(<$IN1>) {
    chomp;
    $commonHash{$_} = 1;
    ${$sampleHash[0]} = 1;
}
close $IN1;

open my $IN2, "<$f2" or die "Cannot open file: $!\n";
while(<$IN2>) {
    chomp;
    $commonHash{$_} = 1;
    ${$sampleHash[1]} = 1;
}
close $IN2;

open my $IN3, "<$f3" or die "Cannot open file: $!\n";
while(<$IN3>) {
    chomp;
    $commonHash{$_} = 1;
    ${$sampleHash[2]} = 1;
}
close $IN3;

my $n1 = scalar keys %{$sampleHash[0]};
my $n2 = scalar keys %{$sampleHash[1]};
my $n3 = scalar keys %{$sampleHash[2]};
my $n12 = 0;
my $n13 = 0;
my $n23 = 0;
my $n123 = 0;

foreach(keys %commonHash)   {
    if(exists ${$sampleHash[0]}{$_} && exists ${$sampleHash[1]}{$_} && exists ${$sampleHash[2]}{$_})    {
        ++ $n123;
    }   elsif(exists ${$sampleHash[0]}{$_} && exists ${$sampleHash[1]}{$_}) {
        ++ $n12;
    }   elsif(exists ${$sampleHash[0]}{$_} && exists ${$sampleHash[2]}{$_}) {
        ++ $n13;
    }   elsif(exists ${$sampleHash[1]}{$_} && exists ${$sampleHash[2]}{$_}) {
        ++ $n23;
    }
}

print "area1 = $n1\n";
print "area2 = $n2\n";
print "area3 = $n3\n";
print "n12 = $n12\n";
print "n13 = $n13\n";
print "n23 = $n23\n";
print "n123 = $n123\n";
