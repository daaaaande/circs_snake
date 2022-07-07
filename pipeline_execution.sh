#!/bin/bash

module load Miniconda/3_snakemake
module load Snakemake/5.10.0

#SCRIPT_DIR=/home/daric/work_WGGC/circRNA_detection/circs_snake/circs_snake/scripts
SCRIPT_DIR=/gpfs/project/projects/bmfz_gtl/software/circRNA_pipeline/circs_snake-master/scripts
yourfilenames=`ls -f1 ../*.fastq | sed 's/\..\///'`

echo "files that will be analyzed:"
echo "###########"

for eachfile in $yourfilenames
do
   echo $eachfile
done

echo "###########"
echo "if you are missing files, or there are unpaired files, or there are too many files, cancel with ctrl+c"
echo "now we need the R_1/R_2 identifier: remember: samplename + R_1 or R_2 + .fastq need to be the exact file names from above! for all files!"
echo "remember: these exact identifiers MUST also be in the config.yaml!"
lane_config_check=`grep -A 1 lane config.yaml `
echo "the in the config.yaml given lane identifiers:"
echo $lane_config_check
read -r -p "R_1 identifier: " LANE|| exit 100
read -r -p "R_2 identifier: " TWO|| exit 100


echo "there should be the files:"
echo "samplename$LANE.fastq"
echo "samplename$TWO.fastq"

echo "###########"
echo "Running the Checklist now. If an answer to any question is no, cancel with ctrl+c"
echo "Did you edit the run_name in the config.yaml ?"
read -r -p "(yes|y / no|n): " RUN_NAME|| exit 100
echo "All samples are paired end RNA-Seq datasets and have the same lane 1/2 identifiers ?"
read -r -p "(yes|y / no|n): " PAIRED|| exit 100
echo "All samples are human or mouse ?"
read -r -p "(yes|y / no|n): " HGMM|| exit 100
echo "All .fastq files are in  /gpfs/project/projects/bmfz_gtl/software/circRNA_pipeline/. ?"
read -r -p "(yes|y / no|n): " PLCE|| exit 100
echo "###########"

# also add the r1 and r2 checks from the config.

echo "creating the infile with all available samples..."
ls -f1 ../*.fastq | sed 's/\..\///' >all_samples.txt

perl $SCRIPT_DIR/snake_infile_creator.pl --i all_samples.txt --l1 $LANE --l2 $TWO --d /gpfs/project/projects/bmfz_gtl/software/circRNA_pipeline/ >samples.tsv
cp samples.tsv ../
echo "done. starting the snakemake workflow now..."

../miniconda3/bin/snakemake -p  --cluster-config cluster.json --cluster "qsub -A {cluster.account} -q {cluster.queue} -l walltime={cluster.time} -l select={cluster.nodes}:ncpus={cluster.ncpus}:mem={cluster.mem}:arch={cluster.arch}" -j 100 --latency-wait 90000 --use-conda --max-status-checks-per-second 1 --keep-going | tee output.log
