#!/usr/bin/perl -w

use DBI;
use strict;

my $dirtoget="./genes_info";
#my $dirtoget="./tonto";

my $dbhost ='localhost';
my $dbname ='METAGENOMESIMG';	
				
my $dbuser ='root';	
#my $dbpass ='vaclp,duv1';
my $dbpass ='20master09';

my $dsn = "DBI:mysql:$dbname:$dbhost";
my $dbh = DBI->connect($dsn, $dbuser, $dbpass)
                or die "Couldn't connect to database: " . DBI->errstr;


#my $counth = $dbh->prepare('SELECT COG, count(COG) from genes where METAID= ? AND COG!=\'\' AND COG IS NOT NULL group by COG')
#                or die "Couldn't prepare statement: " . $dbh->errstr;
my $counth = $dbh->prepare('SELECT genes.COG, cat.COG_CATEGORY, count(genes.COG) from genes, cog_categories cat where genes.METAID= ? AND genes.COG=cat.COG AND genes.COG!=\'\' AND genes.COG IS NOT NULL group by genes.COG')
                or die "Couldn't prepare statement: " . $dbh->errstr;

my $metaidsh = $dbh->prepare('select distinct(METAID) from genes WHERE METAID!=\'\' AND METAID IS NOT NULL')
                or die "Couldn't prepare statement: " . $dbh->errstr;

my $inserth = $dbh->prepare('INSERT INTO count_cogs(METAID,COG,COG_CATEGORY,COUNT_COG) VALUES(?,?,?,?)')
                or die "Couldn't prepare statement: " . $dbh->errstr;

my $selecth = $dbh->prepare('SELECT * FROM count_cogs WHERE METAID= ? AND COG= ?')
                or die "Couldn't prepare statement: " . $dbh->errstr;

my $updateh = $dbh->prepare('UPDATE count_cogs SET COUNT_COG= ? WHERE METAID= ? AND COG= ?')
                or die "Couldn't prepare statement: " . $dbh->errstr;

$metaidsh->execute();

while ( my ($metaid) = $metaidsh->fetchrow_array() ) 
{
    	$counth->execute( $metaid );
	while( my($cog, $category, $count) = $counth->fetchrow_array() )
	{
		$selecth->execute( $metaid, $cog);
		my $count_rows = $selecth->rows();
		$selecth->finish;
		if( $count_rows == 0 )
		{
			$inserth->execute( $metaid, $cog, $category, $count );
			$inserth->finish;
	
		}
		else
		{
			$updateh->execute( $count, $metaid, $cog );
			$updateh->finish;
		}	
	}
	$counth->finish;
}
$metaidsh->finish;

$dbh->disconnect;



