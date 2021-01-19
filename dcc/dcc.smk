
configfile: "dcc/dcc_config.yaml"
samplesfile = "samples.tsv"
#
####  trying to load the samplesfile into a list
import pandas as pd

samples_df = pd.read_table(samplesfile).set_index("samples", drop=False)
sample_names = list(samples_df['samples'])
print("will now execute DCC hg38 on samples:")
print(sample_names)


#rule all: # extend this rule to include outfiles from the last step respectively
#  input:
#    expand(config['prefix'] + "/dcc_2_out/run_{name}" + "/processed_run_{name}.tsv",name=sample_names)




    #expand(config['prefix'] + "/dcc_2_out/run_{name}" + "/"+"{name}"+ config['lane_ident1'] +".Chimeric.out.junction",name=config["samples"]),
    #expand(config['prefix'] + "/dcc_2_out/run_{name}" + "/"+"{name}"+ config['lane_ident2'] +".Chimeric.out.junction",name=config["samples"])
# needs to be changed to expand and oooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooutput o step

# make an extra dcc file?
# make the linear stuff work later - first the raw pipeline
rule cleanup_annotation:
  input:
    config['prefix'] + "/dcc_2_out/run_{name}" + "/CircRNACount_annotated.tsv"
  output:
    config['prefix'] + "/dcc_2_out/run_{name}" + "/processed_run_{name}.tsv"
  params:
    parse_script=config['parse_file'],
    samplename="{name}",
    coords_file=config['prefix'] + "/dcc_2_out/run_{name}" + "/CircCoordinates"
  shell:
    "perl {params.parse_script} {input} {params.coords_file} {output} {params.samplename}"




rule annotate_cleanfile:
  input:
    config['prefix'] + "/dcc_2_out/run_{name}" + "/CircRNACount_clean"
  output:
    config['prefix'] + "/dcc_2_out/run_{name}" + "/CircRNACount_annotated.tsv"
  params:
    bed_file = config['bed_ref']
  shell:
    "bedtools window -a {input} -b {params.bed_file} -w 1 >{output}"

rule cleanup_circfile:
  input:
    config['prefix'] + "/dcc_2_out/run_{name}" + "/CircRNACount"
  output:
    config['prefix'] + "/dcc_2_out/run_{name}" + "/CircRNACount_clean"
  shell:
    "cat {input} | sed '1d' >{output}"

rule execute_dcc:
    input:
      both_lanes=config['prefix'] + "/dcc_2_out/run_{name}" + "/{name}_bothlanes.Chimeric.out.junction",
      lane_1=config['prefix'] + "/dcc_2_out/run_{name}" + "/"+"{name}"+ config['lane_ident1'] +".Chimeric.out.junction",
      lane_2=config['prefix'] + "/dcc_2_out/run_{name}" + "/"+"{name}"+ config['lane_ident2'] +".Chimeric.out.junction"
    params:
      refseq_file=config['refseq_file_dcc'],
      fasta_ref=config['fasta_reference'],
      dcc_com=config['dcc_command']
# automation  my$dcc_err=`$dcc_command $sample_dir_out/$bothlanesname -mt1 $sample_dir_out/$laneonename.Chimeric.out.junction -mt2 $sample_dir_out/$lanetwoname.Chimeric.out.junction -D -fg -an $refseq_file -Pi -M -Nr 2 1 -A $fastqs_files -N -T $threads -G $filter`;
    threads: 12
    # outFileNamePrefix SRR3184285lane_2
    # SRR3184285lane_2
    # check exactly how the files are called that come out
    output:
      config['prefix'] + "/dcc_2_out/run_{name}" + "/CircRNACount"
    conda: # at some point i need a conda env here with python2
      "/gpfs/project/daric102/circs_hilbert_scratchgs/snakemake_tests/envs/hg38_STAR.yaml"
    shell:
      "python {params.dcc_com} {input.both_lanes} -mt1 {input.lane_1} -mt2 {input.lane_2} -D -fg -an {params.refseq_file} -Pi -M -Nr 2 1 -A {params.fasta_ref} -N -T {threads}"

##### NEEED TO CONTINUE HERE

# for DCC we need 3 alignments, for each read pair after the initial mapping
rule align_mate2:
  input:
    lane_2=config['prefix'] + "/" + "{name}" + config["lane_ident2"] + ".fastq",
    genome=config["genome_STAR_hg38"],
    dir_check=config['prefix'] + "/dcc_2_out/run_{name}/chk.tx"
  params:
    processing_dir= config['prefix'] + "/dcc_2_out/run_{name}/",
    lane2_name="{name}"+ config['lane_ident2']+"."
  threads: 12

  output:
    config['prefix'] + "/dcc_2_out/run_{name}" + "/"+"{name}"+ config["lane_ident2"] +".Chimeric.out.junction"
  conda:
    "/gpfs/project/daric102/circs_hilbert_scratchgs/snakemake_tests/envs/hg38_STAR.yaml"
  shell:
    "STAR --runThreadN {threads} --genomeDir {input.genome} --outSAMtype BAM SortedByCoordinate --readFilesIn {input.lane_2} --outFileNamePrefix {params.lane2_name} --outReadsUnmapped Fastx --outSJfilterOverhangMin 15 15 15 15 --alignSJoverhangMin 15 --alignSJDBoverhangMin 15 --seedSearchStartLmax 30 --outFilterMultimapNmax 20 --outFilterScoreMin 1 --outFilterMatchNmin 1 --outFilterMismatchNmax 2 --chimSegmentMin 15 --chimScoreMin 15 --chimScoreSeparation 10 --chimJunctionOverhangMin 15 --limitBAMsortRAM 512000000000 &>STAR_lane1_map1_logfile.log"



rule align_mate1:
  input:
    lane_1=config['prefix'] + "/" + "{name}" + config["lane_ident1"] + ".fastq",
    genome=config["genome_STAR_hg38"],
    dir_check=config['prefix'] + "/dcc_2_out/run_{name}/chk.tx"

  params:
    processing_dir= config['prefix'] + "/dcc_2_out/run_{name}/",
    lane1_name="{name}"+ config['lane_ident1']+"."

  threads: 12


  output:
    config['prefix'] + "/dcc_2_out/run_{name}" + "/"+"{name}"+ config['lane_ident1'] +".Chimeric.out.junction"
  conda:
    "/gpfs/project/daric102/circs_hilbert_scratchgs/snakemake_tests/envs/hg38_STAR.yaml"
  shell:
    "STAR --runThreadN {threads} --genomeDir {input.genome} --outSAMtype BAM SortedByCoordinate --readFilesIn {input.lane_1} --outFileNamePrefix {params.lane1_name} --outReadsUnmapped Fastx --outSJfilterOverhangMin 15 15 15 15 --alignSJoverhangMin 15 --alignSJDBoverhangMin 15 --seedSearchStartLmax 30 --outFilterMultimapNmax 20 --outFilterScoreMin 1 --outFilterMatchNmin 1 --outFilterMismatchNmax 2 --chimSegmentMin 15 --chimScoreMin 15 --chimScoreSeparation 10 --chimJunctionOverhangMin 15 --limitBAMsortRAM 512000000000 &>STAR_lane1_map1_logfile.log"




rule align_primary_STAR_DCC:
  input:
    lane_1= config['prefix'] + "/" + "{name}" + config["lane_ident1"] + ".fastq",
    lane_2= config['prefix'] + "/" + "{name}" + config["lane_ident2"] + ".fastq",
    genome= config["genome_STAR_hg38"],
    dir_check= config['prefix'] + "/dcc_2_out/run_{name}/chk.tx"
  params:
    processing_dir= config['prefix'] + "/dcc_2_out/run_{name}/",
    outfile_name="{name}"+"_bothlanes."
  threads: 12

  output:
    config['prefix'] + "/dcc_2_out/run_{name}" + "/{name}_bothlanes.Chimeric.out.junction"

  conda:
        "/gpfs/project/daric102/circs_hilbert_scratchgs/snakemake_tests/envs/hg38_STAR.yaml"
  shell:
        "STAR --runThreadN {threads} --genomeDir {input.genome} --outSAMtype BAM SortedByCoordinate --readFilesIn {input.lane_1} {input.lane_2} --outFileNamePrefix {params.outfile_name} --outReadsUnmapped Fastx --outSJfilterOverhangMin 15 15 15 15 --alignSJoverhangMin 15 --alignSJDBoverhangMin 15 --outFilterMultimapNmax 20 --outFilterScoreMin 1 --outFilterMatchNmin 1 --outFilterMismatchNmax 2 --chimSegmentMin 15 --chimScoreMin 15 --chimScoreSeparation 10 --chimJunctionOverhangMin 15 --limitBAMsortRAM 512000000000 &>STAR_init_map1_logfile.log"
# $star_command --runThreadN $threads --config["genome"]Dir $bt_ref --outSAMtype BAM SortedByCoordinate --readFilesIn $infile_dir/$lineonefile $infile_dir/$linetwofile --outFileNamePrefix $config["samples"]_name. --outReadsUnmapped Fastx --outSJfilterOverhangMin 15 15 15 15 --alignSJoverhangMin 15 --alignSJDBoverhangMin 15 --outFilterMultimapNmax 20 --outFilterScoreMin 1 --outFilterMatchNmin 1 --outFilterMismatchNmax 2 --chimSegmentMin 15 --chimScoreMin 15 --chimScoreSeparation 10 --chimJunctionOverhangMin 15 --limitBAMsortRAM 512000000000\n" ;

rule prepare_files_dcc:
    # unzip if needed,
    # create output dir
    #eed_unpack=0
    # create config["samples"] between-files dir
    # go to processing dir
    input:
        lane_1=config['prefix'] + "/{name}" + config["lane_ident1"] + ".fastq",
        lane_2=config['prefix'] + "/{name}" + config["lane_ident2"] + ".fastq",
    params:
        processing_dir= config['prefix'] + "/dcc_2_out/run_{name}/",
    output:
        config['prefix'] + "/dcc_2_out/run_{name}/chk.tx"

    shell:
        "mkdir -p {params} && cd {params} && touch {output}"



rule unzip_gz_dcc:
    input:
        lane_1=config['prefix'] + "/{name}" + config["lane_ident1"] + ".fastq",
        lane_2=config['prefix'] + "/{name}" + config["lane_ident2"] + ".fastq",
        #out_dir=config['prefix'] + "/"
    output:
        lane_1=config['prefix'] + "/{name}" + config["lane_ident1"] + ".fastq.gz",
        lane_2=config['prefix'] + "/{name}" + config["lane_ident2"] + ".fastq.gz",
    shell:
        "gunzip {input} "
# v0.1
