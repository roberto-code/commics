#!/usr/bin/perl -w

use DBI;
use strict;

my $dirtoget="./genes_info";
#my $dirtoget="./tonto";

my $dbhost ='localhost';
my $dbname ='METAGENOMESIMG';	
				
my $dbuser ='root';	
my $dbpass ='20master09';


my $dsn = "DBI:mysql:$dbname:$dbhost";
my $dbh = DBI->connect($dsn, $dbuser, $dbpass)
                or die "Couldn't connect to database: " . DBI->errstr;


my $updateh = $dbh->prepare('UPDATE genes SET COG = ?,KEGG = ?,EC= ?,LOCUS_TYPE= ?, PFAM= ? WHERE METAID = ? AND GENEID = ?')
                or die "Couldn't prepare statement: " . $dbh->errstr;

my $inserth = $dbh->prepare('INSERT INTO genes(METAID, GENEID, COG, KEGG, EC, LOCUS_TYPE, PFAM) VALUES (?,?,?,?,?,?,?)')
                or die "Couldn't prepare statement: " . $dbh->errstr;


my $selecth = $dbh->prepare('SELECT * FROM genes WHERE METAID = ? AND GENEID = ?')
                or die "Couldn't prepare statement: " . $dbh->errstr;

my $insert_categoryh = $dbh->prepare('INSERT INTO cog_categories(COG, COG_DESCRIPTION, COG_CATEGORY) VALUES (?,?,?)')
                or die "Couldn't prepare statement: " . $dbh->errstr;

my $select_cogh = $dbh->prepare('SELECT * FROM cog_categories WHERE COG = ?')
                or die "Couldn't prepare statement: " . $dbh->errstr;


opendir(DATADIR, $dirtoget) || die("Cannot open directory");
my @file_names = readdir(DATADIR);
closedir(DATADIR); 


my($cog, $cog_description, $kegg, $locus_type, $enzyme, $pfam) = ( '', '', '', '', '', '' );
my ($gene_id,$locus_tag,$source,$cluster_info,$gene_info,$e_value) = ( '', '', '', '', '', '' );

foreach my $genes_file ( @file_names )
{
	if( $genes_file =~ m/^\d\d\d\d\d\d\d\d\d\d/)
	{
		my $metagenome_id = substr( $genes_file,0,10 );

		print "Processing metagenome: $metagenome_id\n";
		
		my $file2open = $dirtoget."\/".$genes_file;
		open(GENEIDS, $file2open) || die("Could not open genes file!");
		my @genes_list = <GENEIDS>;
		close(GENEIDS);

		my @cog_categories;
		foreach my $gene_line( @genes_list )
		{
			if( $gene_line =~ m/^\d\d\d\d\d\d\d\d\d\d/ )
			{	
				
				($gene_id,$locus_tag,$source,$cluster_info,$gene_info,$e_value) = split("\t", $gene_line); 
				if($source =~ m/^COG\d\d\d\d/)
				{
					$cog = $source;
					$cog_description = $cluster_info;

				}
				elsif($source =~ m/^EC:\d.\d.\d.\d/)
				{
					$enzyme = $source;
				}
				elsif($source =~ m/^KO:K\d\d\d\d\d/)
				{
					$kegg = $source;
				}
				elsif($source =~ m/^pfam\d\d\d\d\d/)
				{
					$pfam = $source;
				}
				elsif( $source =~ /Locus_type/ )
				{
   					$locus_type=  $gene_info;
				}
				elsif( $source =~ /COG_category/ )
				{
					 my $cog_category = $cluster_info;
					 if( $cog_category=~ /\[([a-zA-Z])\]/g )
					 {
						push(@cog_categories, $1);
					 }
				}
				

			}# if $gene_line
			elsif( $gene_line =~ m/^\t\t\t\t\t/ )
			{
				
				$selecth->execute($metagenome_id, $gene_id);
				if( $selecth->rows == 0 )
				{
					$inserth->execute( $metagenome_id, $gene_id, $cog, $kegg, $enzyme,$locus_type, $pfam);
					$inserth->finish;
					#insert
				}
				else
				{
					$updateh->execute( $cog,$kegg, $enzyme,$locus_type, $pfam, $metagenome_id, $gene_id);
					$updateh->finish;
					#update
				}
				$selecth->finish;
	
				$select_cogh->execute($cog);
				if( $select_cogh->rows == 0 )
				{
					foreach my $category( @cog_categories )
					{
						$insert_categoryh->execute( $cog, $cog_description, $category );
						$insert_categoryh->finish;
					}
				}
				$select_cogh->finish;
				undef @cog_categories;
				($cog, $cog_description, $kegg, $locus_type, $enzyme, $pfam) = ( '', '', '', '', '', '' );
				($gene_id,$locus_tag,$source,$cluster_info,$gene_info,$e_value) = ( '', '', '', '', '', '' );
			}
			
		}#foreach
                system( "mv $file2open $dirtoget/processed");
	}
	else
	{
		#print "$genes_file has a bad name\n";
	}


}

$dbh->disconnect;

