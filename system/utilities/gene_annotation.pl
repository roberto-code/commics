#!/usr/bin/perl -w


use strict;




my $file2open = $ARGV[0];


open(FILEH, $file2open) || die("Could not open the specified file!");
my @file_content = <FILEH>;
close(FILEH);

open(OUTPUT,">annotated_genes.txt");

my ($current_contig, $current_cog,$current_e_value) = ("","",1000);
foreach my $line( @file_content )
{	
  my ($contig,$annotation,undef,undef, undef, undef, undef, undef, undef, undef,$e_value) = split("\t", $line); 
  my (undef,undef,$cog,undef,undef) = split(/\|/,$annotation); # '|' is a special character, this is the right way to do.
  if( $current_contig ne $contig )
  {
    if( $current_contig ne "")
    {
      print OUTPUT "$current_contig\t$current_cog\n";
    }
    $current_contig = $contig;
    $current_cog = $cog;
  }
  else
  {
    if($e_value<$current_e_value)
    {
      $current_e_value = $e_value;
      $current_cog = $cog;
    }
  }

}

close(OUTPUT);

