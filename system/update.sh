#!/bin/bash


echo "GETTING NEW METAGENOMES..."

perl getNewMetagenomesIds.pl;
echo "NUMBER OF NEW METAGENOMES:"
Number=`awk 'END{print NR -1}' new_metagenomes.txt`;
echo $Number
if [ $Number -eq 0 ] 
then 
echo "THERE ARE NOT NEW METAGENOMES AVAILABLE" 
else
echo "THE FOLLOWING METAGENOMES WILL BE ADDED TO THE DATABASE:"
awk '{if ($1 != "#")  print }' new_metagenomes.txt

echo "ADDING NEW METADATA"

perl getMetadata.pl;
echo "DOWNLOADING GENES INFO FILES..."
perl downloadGenesInfoFiles.pl;
echo "ADDING GENES INFO..."
perl getGenesInfo.pl;
echo "ADDING NUCLEOTIDES SEQUENCES..."
perl getNtSequences.pl;
echo "ADDING AMINOACIDS SEQUENCES..."
perl getAaSequences.pl;
echo "UPDATING AUXILIARY TABLE..."
perl updateCountCogs.pl;
echo "UPDATE FINISHED"
fi


