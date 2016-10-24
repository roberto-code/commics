#!/usr/bin/perl -w

use DBI;
use strict;

my $dbhost ='localhost';
my $dbname ='METAGENOMESIMG';	
				
my $dbuser ='root';	
my $dbpass ='20master09';


my $dsn = "DBI:mysql:$dbname:$dbhost";
my $dbh = DBI->connect($dsn, $dbuser, $dbpass)
                or die "Couldn't connect to database: " . DBI->errstr;


my $updateh = $dbh->prepare('UPDATE metadata set HABITAT_SUPERTYPE=?, HABITAT_TYPE=?,HABITAT_SUBTYPE=?,HABITAT_EXTRA=? WHERE META_ID=?')
                or die "Couldn't prepare statement: " . $dbh->errstr;


my $file2open = $ARGV[0];


open(FILEH, $file2open) || die("Could not open the specified file!");
my @file_content = <FILEH>;
close(FILEH);

my @cog_categories;
foreach my $line( @file_content )
{	
  my ($metaid,$supertype,$type,$subtype,$extra) = split("\t", $line); 
  print "updating $metaid\n";
  $updateh->execute($supertype,$type,$subtype,$extra,$metaid);
  $updateh->finish;
}

$dbh->disconnect;
