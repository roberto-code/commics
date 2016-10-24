package MetadataParser;

use base "HTML::Parser";
use strict; 


######################################################################
sub new {
    #constructor
    my ($class_name) = @_;
 
    my $self = {
        _metadata_ids => [],
        _metadata_values  => [],
        _current_metadata => '',
        _expect_data => 0,
        _contador => 0,
        _hashData => {
          'LATITUDE' => 'NULL',
          'LONGITUDE' => 'NULL',
          'ALTITUDE' => 'NULL',
          'MICROBIOME_NAME' => 'NULL',
          'SEQUENCING_STATUS' => 'NULL',
          'NCBI_TAXON_ID' => 'NULL',
          'ADD_DATE' => 'NULL',
          'MODIFIED_DATE' => 'NULL',
          'ISOLATION_COUNTRY' => 'NULL',
          'ISOLATION' => 'NULL',
          'ISOLATION_YEAR' => 'NULL',
          'PH' => 'NULL',
          'HABITAT' => 'NULL',
          'TEMPERATURE_RANGE' => 'NULL',
          'OXYGEN_REQUIREMENT' => 'NULL',
        },
    };
 bless $self, $class_name;
    return $self;
}
  



######################################################################
######################################################################
#Métodos de la clase
#
sub mdpDataHash
{
	my $self=shift; #El primer parámetro de un metodo es la  clase
	return %{$self->{_hashData}};
}


sub text 
{
	my ($self, $text) = @_;
	chomp($text);
	$text =~ s/&nbsp;//g;

 
	$self->{_contador}++;

	if( $text =~ m/Latitude/  && $text !~ m/\(Latitude\)/ )
	{
  	$self->{_current_metadata} = 'LATITUDE';
  	$self->{_expect_data} = 1;
	}	
	elsif( $text =~ m/Longitude/ && $text !~ m/\(Longitude\)/ )
	{
		$self->{_current_metadata} = 'LONGITUDE';
  	$self->{_expect_data} = 1;
	}
	elsif( $text =~ m/Altitude/ && $text !~ m/\(Altitude\)/ )
	{
		$self->{_current_metadata} = 'ALTITUDE';
  		$self->{_expect_data} = 1;
	}
  	elsif( $text =~ m/Microbiome\sName/ )
	{
		$self->{_current_metadata} = 'MICROBIOME_NAME';
  	$self->{_expect_data} = 1;
	}
  	elsif( $text =~ m/Sequencing\sStatus/ )
	{
		$self->{_current_metadata} = 'SEQUENCING_STATUS';
  		$self->{_expect_data} = 1;
	}	
	elsif( $text =~ m/NCBI\sTaxon\sID/ )
	{
		$self->{_current_metadata} = 'NCBI_TAXON_ID';
  	$self->{_expect_data} = 1;
	}
	elsif( $text =~ m/Add\sDate/ )
	{
		$self->{_current_metadata} = 'ADD_DATE';
  		$self->{_expect_data} = 1;
	}
	elsif( $text =~ m/Modified\sDate/ )
	{
		$self->{_current_metadata} = 'MODIFIED_DATE';
  		$self->{_expect_data} = 1;
	}
	elsif( $text =~ m/Isolation\sCountry/ )
	{
		$self->{_current_metadata} = 'ISOLATION_COUNTRY';
  		$self->{_expect_data} = 1;
	}
  	elsif( $text =~ m/Isolation/ && $text !~ m/Isolation\sCountry/ && $text !~ m/Isolation\sYear/)
	{
		$self->{_current_metadata} = 'ISOLATION';
  		$self->{_expect_data} = 1;
	}
  	elsif( $text =~ m/Isolation\sYear/ )
	{
		$self->{_current_metadata} = 'ISOLATION_YEAR';
  		$self->{_expect_data} = 1;
	}
	elsif( $text =~ m/pH/ )
	{
		$self->{_current_metadata} = 'PH';
  		$self->{_expect_data} = 1;
	}
  	elsif( $text =~ m/Habitat/ )
	{
		$self->{_current_metadata} = 'HABITAT';
  		$self->{_expect_data} = 1;
	}
	elsif( $text =~ m/Temperature\sRange/ )
	{
		$self->{_current_metadata} = 'TEMPERATURE_RANGE';
  		$self->{_expect_data} = 1;
	}
	elsif( $text =~ m/Oxygen\sRequirement/ )
	{
		$self->{_current_metadata} = 'OXYGEN_REQUIREMENT';
  		$self->{_expect_data} = 1;
	}
	else
	{
  		if(   $self->{_expect_data} == 1 && $text !~ m/^\s+$/)
  		{
			$text =~ s/^\s+|\s+$//g;
			#print "$self->{_current_metadata}=$text\n";
			my $metadata_ids_str = join "|", @{$self->{_metadata_ids}}; 
			if($metadata_ids_str  !~ m/$self->{_current_metadata}/)
			{
				push(@{$self->{_metadata_ids}}, $self->{_current_metadata});
				push(@{$self->{_metadata_values}}, $text);
                                delete( $self->{_hashData}{$self->{_current_metadata}} );
                                $self->{_hashData}{$self->{_current_metadata}} = $text;
			}
			

			$self->{_current_metadata} ='';
			$self->{_expect_data} = 0;

  		}
	}

}

######################################################################
#Destructor
#
sub DESTROY 
{
	my $self=shift; #El primer parámetro de un metodo es la  clase
	$self->{_current_metadata} = '';
	$self->{_expect_data} = 0;
	$self->{_contador} = 0;

	undef(@{$self->{_metadata_ids}});
	undef(@{$self->{_metadata_values}});
        undef(%{$self->{_hashData}});
}



#Fin
1;

