#  For complete documentation for circs_snake please open circs_snake_manual.md in this repo
circs_snake: a snakemake workflow for circular RNA detection and quantification based on find_circ, DCC and CIRCexplorer1.

## how to get started

- get the code: git clone https://github.com/daaaaande/circs_snake
- personalize: nano config.yaml
- prepare: copy/move your input files (paired RNAseq .fastq files) to circs_snake/.
- also create samplesheet needed: more in the config/ readme
- run: snakemake -n (remove the -n once everything looks OK)


additional credits to the original pipelines authors:

https://github.com/marvin-jens/find_circ

https://github.com/dieterich-lab/DCC

https://github.com/YangLab/CIRCexplorer
