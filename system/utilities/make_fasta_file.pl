#!/usr/bin/perl -w

use DBI;
use strict;


my $dbhost ='localhost';
my $dbname ='METAGENOMESIMG';	
				
my $dbuser ='root';	
#my $dbpass ='vaclp,duv1';
my $dbpass ='20master09';

my $dsn = "DBI:mysql:$dbname:$dbhost";
my $dbh = DBI->connect($dsn, $dbuser, $dbpass)
                or die "Couldn't connect to database: " . DBI->errstr;


my( $meta_id, $gene_id, $cog, $ec, $kegg );
my( $aa_sequence );


my $select_infoh = $dbh->prepare('SELECT METAID, GENEID, COG, EC, KEGG FROM genes WHERE LOCUS_TYPE= \'CDS\'')
                or die "Couldn't prepare statement: " . $dbh->errstr;

my $select_sequenceh = $dbh->prepare('SELECT SEQAA FROM sequences WHERE METAID = ? AND GENEID = ?')
                or die "Couldn't prepare statement: " . $dbh->errstr;


open (FASTAFILE, '>metagenomes_img.fasta');
open (ERRORFILE, '>fasta_file_errors.txt');

$select_infoh->execute();
# BIND TABLE COLUMNS TO VARIABLES
$select_infoh->bind_columns( undef, \$meta_id, \$gene_id, \$cog, \$ec, \$kegg );

# LOOP THROUGH RESULTS
while($select_infoh->fetch()) 
{
	$select_sequenceh->execute( $meta_id, $gene_id );
	$select_sequenceh->bind_columns( undef, \$aa_sequence );
	while( $select_sequenceh->fetch() )
	{
		$ec =~ s/EC://i;
		$kegg =~ s/KO://i;
		
		if( $aa_sequence )
		{
			print FASTAFILE ">$meta_id|$gene_id|$cog|$ec|$kegg\n$aa_sequence\n";
		}
		else
		{
			print ERRORFILE "Sequence not found: METAGENOME ID = $meta_id, GENE ID = $gene_id\n";
		}	
	}
	$select_sequenceh->finish;

} 

$select_infoh->finish;



close (FASTAFILE); 
close (ERRORFILE);
$dbh->disconnect;




