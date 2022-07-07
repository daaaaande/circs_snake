# instructions on how to analyze paired-end bulk RNA-Seq data with circs_snake

This pipeline is a Snakemake-based re-write of circs, made to improve reproducibility, ease of use and efficiency.
The here shown setup is made for the HHU- internal HPC, Hilbert that uses PBS Pro for job management.
If your are trying to get this run somewhere else, please first:
 - get the reference genome as explained in get_new_genomes.sh
 - build STAR and bowtie2 indexes of the reference genome
 - then install conda and snakemake

## 1. get the input files ready
  - get unzipped and paired end RNA-Seq .fastq files into the directory "/gpfs/project/projects/bmfz_gtl/software/circRNA_pipeline/"
  - not possible: .fastq.gz files , unpaired data, dataset with different lane identifiers (one samples _1.fastq/_2.fastq and another one R1.fastq/R2.fastq)
  - only the in this run needed .fastq file should be in the folder /gpfs/project/projects/bmfz_gtl/software/circRNA_pipeline/. not more, not less!


## 2. prepare samples.tsv
  - create list of all used .fastq files : "ls -f1 /gpfs/project/projects/bmfz_gtl/software/circRNA_pipeline/*.fastq >/gpfs/project/projects/bmfz_gtl/software/circRNA_pipeline/fastqs.list"
  - then create a samplesheet: "perl /gpfs/project/projects/bmfz_gtl/software/circRNA_pipeline/circs_snake-master/scripts/fastq_list_to_infile_creator.pl --i /gpfs/project/projects/bmfz_gtl/software/circRNA_pipeline/fastqs.list --l1 _R1_001 --l2 _R2_001 >/gpfs/project/projects/bmfz_gtl/software/circRNA_pipeline/samples.tsv"
  - here the --l1 and --l2 are the lane paramaters: for sample1_1.fastq and sample1_2.fastq its _1 and _2, respectively
  - samplename + lane identifier + ".fastq" should result in the exact filenames in /gpfs/project/projects/bmfz_gtl/software/circRNA_pipeline/, make sure to always use the same lane identifiers for all samples on the same run!


## 3. prepare interactive snakemake session
  - re-attach a screen session, or create one: "screen -dr snake_circs"
  - start an interactive job: "qsub -q default -I job_scripts/interactive_snake.sh"
  - ssh to the snakemake node: "ssh snakemake-node"
  - load the needed modules: "module load Snakemake/5.10.0" + "module load Miniconda/3_snakemake"

## 4. configure run
  - check if only files from samples included in samples.tsv are in /gpfs/project/projects/bmfz_gtl/software/circRNA_pipeline/
  - edit config.yaml: lane identifiers + run_name: the dataset needs a unique name!
  - check if samplename + lane identifier + ".fastq" result in the exact filenames in /gpfs/project/projects/bmfz_gtl/software/circRNA_pipeline/

## 5. execute run
  - cd to /gpfs/project/projects/bmfz_gtl/software/circRNA_pipeline/circs_snake-master/.
  - dry run mode first: "../miniconda3/bin/snakemake -p  --cluster-config cluster.json --cluster "qsub -A {cluster.account} -q {cluster.queue} -l walltime={cluster.time} -l select={cluster.nodes}:ncpus={cluster.ncpus}:mem={cluster.mem}:arch={cluster.arch}" -j 100 --latency-wait 90000 --use-conda --max-status-checks-per-second 1 --keep-going -n"
  - then the actual execution: "../miniconda3/bin/snakemake -p  --cluster-config cluster.json --cluster "qsub -A {cluster.account} -q {cluster.queue} -l walltime={cluster.time} -l select={cluster.nodes}:ncpus={cluster.ncpus}:mem={cluster.mem}:arch={cluster.arch}" -j 100 --latency-wait 90000 --use-conda --max-status-checks-per-second 1 --keep-going"
