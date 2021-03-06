#!/bin/bash
#$ -N test1_2016_04_19_full_rnaseq-16.04
#$ -q long-sl65
#$ -l virtual_free=60G
#$ -l h_rt=24:00:00
#$ -o /users/GR/mb/jquilez/pipelines/rnaseq-16.04/job_out/test1_2016_04_19_full_rnaseq-16.04_$JOB_ID.out
#$ -e /users/GR/mb/jquilez/pipelines/rnaseq-16.04/job_out/test1_2016_04_19_full_rnaseq-16.04_$JOB_ID.err
#$ -j y
#$ -M javier.quilez@crg.eu
#$ -m abe
#$ -pe smp 8

submitted_on=2016_04_19
pipeline_version=16.04
sample_id=test1
data_type=chrrnaseq
pipeline_name=rnaseq
pipeline_version=16.04
pipeline_run_mode=full
io_mode=standard
CUSTOM_IN=/users/GR/mb/jquilez/pipelines/rnaseq-16.04/test
CUSTOM_OUT=/users/GR/mb/jquilez/misc/rnaseq
sample_to_fastqs=sample_to_fastqs.txt
submit_to_cluster=no
queue=long-sl65
memory=60G
max_time=24:00:00
slots=8
email=javier.quilez@crg.eu
integrate_metadata=no
sequencing_type=PE
seedMismatches=2
palindromeClipThreshold=30
simpleClipThreshold=12
leading=3
trailing=3
minAdapterLength=1
keepBothReads=true
minQual=3
targetLength=40
strictness=0.999
minLength=36
species=homo_sapiens
version=hg19
read_length=50
n_bootstraps=100
fragment_length_avg=150
fragment_length_sd=30
strand_specific=1
CUSTOM_OUT=/users/GR/mb/jquilez/misc/rnaseq
PIPELINE=/users/GR/mb/jquilez/pipelines/rnaseq-16.04
config=pipelines/rnaseq-16.04/rnaseq.config
path_job_file=/users/GR/mb/jquilez/pipelines/rnaseq-16.04/job_cmd/test1_2016_04_19_full_rnaseq-16.04.sh
time_start=$(date +"%s")
run_date=`date +"%Y-%m-%d-%H-%M"`
job_name=$pipeline_name-$pipeline_version



#==================================================================================================
# PATHS
#==================================================================================================

# Directories

# pipeline scripts
SCRIPTS=$PIPELINE/scripts

# Primary output directory
if [[ $io_mode == "custom" ]]; then
	SAMPLE=$CUSTOM_OUT/$sample_id
else
	SAMPLE=/users/GR/mb/jquilez/data/$data_type/samples/$sample_id
fi

# Logs
LOGS=$SAMPLE/logs/$version

# Trim reads
TRIMMED=$SAMPLE/fastqs_processed/trimmomatic
SINGLE=$TRIMMED/single_end
PAIRED=$TRIMMED/paired_end
UNPAIRED=$TRIMMED/unpaired_reads
ADAPTERS=/software/mb/el6.3/Trimmomatic-0.33/adapters

# Mapping/alignment
GENOME_DIR=/users/GR/mb/jquilez/assemblies/$species/$version/star_genome_index/read_length_${read_length}bp
STAR=$SAMPLE/alignments/star/$version

# reads per transcript quantification
KALLISTO_QUANT=$SAMPLE/quantifications/kallisto/$version
FEATURECOUNTS_QUANT=$SAMPLE/quantifications/featurecounts/$version

# Reads per million (RPM) profiles
PROFILES=$SAMPLE/profiles/$version

# SHA cheksums
CHECKSUMS=$SAMPLE/checksums/$version/$run_date
checksums=$CHECKSUMS/files_checksums.sha


# Files

# input FASTQ
if [[ $io_mode == "custom" ]]; then
	ifq1_name=`grep $sample_id $CUSTOM_IN/sample_to_fastqs.txt |cut -f2`
	ifq2_name=`grep $sample_id $CUSTOM_IN/sample_to_fastqs.txt |cut -f3`
	ifq1=$CUSTOM_IN/$ifq1_name
	ifq2=$CUSTOM_IN/$ifq2_name
else
	ifq1=/users/GR/mb/jquilez/data/$data_type/raw/*/${sample_id}*read1.fastq.gz
	ifq2=/users/GR/mb/jquilez/data/$data_type/raw/*/${sample_id}*read2.fastq.gz
fi

# tools
trimmomatic=`which trimmomatic`
star=`which star`
# + as of 2015-11-03, the `which samtools` version of samtools fails to sort the BAM of some samples
# Quique mentioned he had a similar problem and recommended me to use the '/software/mb/el6.3/samtools-1.2/samtools'
# version
samtools=/software/mb/el6.3/samtools-1.2/samtools
bamToBed=`which bamToBed`
bed2bb=`which bedToBigBed`
kallisto=`which kallisto`
htseq_count=`which htseq-count`
featureCounts=`which featureCounts`
bamToBed=`which bamToBed`

# indices and annotation
chrom_sizes=/users/GR/mb/jquilez/assemblies/$species/$version/ucsc/$version.chrom.sizes.chr1-22XYMUn
if [[ $version == "hg19" || $version == "hg19_mmtv" ]]; then
	kallisto_index=/users/GR/mb/jquilez/assemblies/$species/hg19/kallisto_index/kallisto_${species}_hg19_ensGene.index
	transcripts_gtf=/users/GR/mb/jquilez/assemblies/$species/hg19/gencode/gencode.v19.annotation.gtf
elif [[ $version == "hg38" ]]; then
	kallisto_index=/users/GR/mb/jquilez/assemblies/$species/hg38/kallisto_index/kallisto_${species}_hg38_gencode_v24.index
	transcripts_gtf=/users/GR/mb/jquilez/assemblies/$species/hg38/gencode/gencode.v24.annotation.gtf
fi

# python script to write/access metadata
io_metadata=/users/GR/mb/jquilez/utils/io_metadata.sh



# =================================================================================================
# CODE EXECUTION
# =================================================================================================

main() {

	echo 
	# store general parameters into the metadata
	if [[ $integrate_metadata == "yes" ]]; then
		$io_metadata -m add_to_metadata -t 'rnaseq' -s $sample_id -u $run_date -a PIPELINE_RUN_MODE -v $pipeline_run_mode
		$io_metadata -m add_to_metadata -t 'rnaseq' -s $sample_id -u $run_date -a QUEUE -v $queue
		$io_metadata -m add_to_metadata -t 'rnaseq' -s $sample_id -u $run_date -a MEMORY -v $memory
		$io_metadata -m add_to_metadata -t 'rnaseq' -s $sample_id -u $run_date -a MAX_TIME -v $max_time
		$io_metadata -m add_to_metadata -t 'rnaseq' -s $sample_id -u $run_date -a SLOTS -v $slots
		$io_metadata -m add_to_metadata -t 'rnaseq' -s $sample_id -u $run_date -a ASSEMBLY_VERSION -v $version
		$io_metadata -m add_to_metadata -t 'rnaseq' -s $sample_id -u $run_date -a JOB_NAME -v $job_name		
		$io_metadata -m add_to_metadata -t 'rnaseq' -s $sample_id -u $run_date -a PATH_JOB_FILE -v $path_job_file		
	fi

	if [[ $pipeline_run_mode == 'full' ]]; then
		trim_reads_trimmomatic
		#align_star
		#quantification_featurecounts
		#quantification_kallisto
		#make_profiles
	elif [[ $pipeline_run_mode == 'trim_reads_trimmomatic' ]]; then trim_reads_trimmomatic
	elif [[ $pipeline_run_mode == 'align_star' ]]; then align_star
	elif [[ $pipeline_run_mode == 'quantification_featurecounts' ]]; then quantification_featurecounts
	elif [[ $pipeline_run_mode == 'quantification_kallisto' ]]; then quantification_kallisto
	elif [[ $pipeline_run_mode == 'make_profiles' ]]; then make_profiles
	fi
	echo

}


#==================================================================================================
# FUNCTIONS DEFINITIONS
#==================================================================================================


# =================================================================================================
# Pipeline progress functions
# =================================================================================================

# Outputs a message about the task being done
message_info() {
	step_name=$1
	message=$2
	echo -e "INFO \t`date +"%Y-%m-%d %T"` \t[$step_name] \t$message"
}

# Outputs a message about the error found and exits
message_error() {
	step_name=$1
	message=$2
	echo -e "ERROR \t`date +"%Y-%m-%d %T"` \t[$step_name] \t$message"
	exit	
}

# Outputs a warning message about the task being done
message_warn() {
	step_name=$1
	message=$2
	echo -e "WARN \t`date +"%Y-%m-%d %T"` \t[$step_name] \t$message"
}

# Outputs a message with the time in seconds spent in a given step
message_time_step() {
	step_name=$1
	field_name="TIME_${step_name^^}"
	time0=$2
	time1=$(date +"%s")
	length=$(($time1-$time0))
	echo -e "TIME \t`date +"%Y-%m-%d %T"` \t[$step_name] \tstep time for completion (seconds) = $length"
	if [[ $integrate_metadata == "yes" ]]; then
	 	$io_metadata -m add_to_metadata -t 'rnaseq' -s $sample_id -u $run_date -a $field_name -v $length
	fi
	echo
}

# Outputs the total time in seconds for the pipeline to run
message_time_pipeline() {
	field_name="TIME_COMPLETE_PIPELINE"
	time0=$time_start
	time1=$(date +"%s")
	length=$(($time1-$time0))
	echo -e "TIME \t`date +"%Y-%m-%d %T"` \t[pipeline] \ttotal time for completion (seconds) = $length"
	if [[ $integrate_metadata == "yes" ]]; then
	 	$io_metadata -m add_to_metadata -t 'rnaseq' -s $sample_id -u $run_date -a $field_name -v $length
	fi
	echo
}


# =================================================================================================
# Trim adapter and low-quality ends
# =================================================================================================

trim_reads_trimmomatic() {

	step="trim_reads_trimmomatic"
	time0=$(date +"%s")

	# Check that FASTQ file exists, make/define input/output directories and files
	if [[ $sequencing_type == "SE" ]]; then
		if [ -f $ifq1 ]; then
			mkdir -p $SAMPLE
			mkdir -p $SINGLE
			mkdir -p $LOGS
			step_log=$SAMPLE/logs/${sample_id}_${step}_single_end.log
			single1=$SINGLE/${sample_id}_read1.fastq.gz
			params="$ifq1 $single1"
			ODIR=$SINGLE
			if [[ $integrate_metadata == "yes" ]]; then
				$io_metadata -m add_to_metadata -t 'rnaseq' -s $sample_id -u $run_date -a PATH_FASTQ_READ1 -v $ifq1
				message_info $step "paths to read1 saved to metadata database"
			fi
		else
			message_error $step "$ifq1 not found. Exiting..."
		fi
	elif [[ $sequencing_type == "PE" ]]; then
		if [ -f $ifq1 ] && [ -f $ifq2 ]; then
			mkdir -p $SAMPLE
			mkdir -p $PAIRED
			mkdir -p $UNPAIRED
			mkdir -p $LOGS
			step_log=$SAMPLE/logs/${sample_id}_${step}_paired_end.log
			paired1=$PAIRED/${sample_id}_read1.fastq.gz
			paired2=$PAIRED/${sample_id}_read2.fastq.gz
			unpaired1=$UNPAIRED/${sample_id}_read1.fastq.gz
			unpaired2=$UNPAIRED/${sample_id}_read2.fastq.gz
			params="$ifq1 $ifq2 $paired1 $unpaired1 $paired2 $unpaired2"
			ODIR=$PAIRED
			if [[ $integrate_metadata == "yes" ]]; then
				$io_metadata -m add_to_metadata -t 'rnaseq' -s $sample_id -u $run_date -a PATH_FASTQ_READ1 -v $ifq1
				$io_metadata -m add_to_metadata -t 'rnaseq' -s $sample_id -u $run_date -a PATH_FASTQ_READ2 -v $ifq2
				message_info $step "paths to read1 and read2 saved to metadata database"
			fi
		else
			message_error $step "$ifq1 and/or $ifq2 not found. Exiting..."
		fi
	fi

	# adapter trimming: the trimmomatic program directory contains a folder with the adapter sequences for
	# the Illumina sequencers in use. 'TruSeq3-PE.fa' is used, which contains the adapter sequences for the HiSeq
	message_info $step "sequencing type = $sequencing_type" 
	message_info $step "trimming adapter sequences for HiSeq, NextSeq or HiSeq"
	message_info $step "trimming low-quality reads ends using trimmomatic's recommended practices"
	seqs=$ADAPTERS/TruSeq3-$sequencing_type.fa
	$trimmomatic $sequencing_type \
 					$params \
 					ILLUMINACLIP:$seqs:$seedMismatches:$palindromeClipThreshold:$simpleClipThreshold:$minAdapterLength:$keepBothReads \
 					LEADING:$leading \
 					TRAILING:$trailing \
 					MAXINFO:$targetLength:$strictness \
 					MINLEN:$minLength >$step_log 2>&1

	# parse step log to extract generated metadata
	message_info $step "parse step log to extract generated metadata"
 	n_reads_trimmed=`grep Surviving $step_log | cut -f3 -d':' | cut -f1 -d'(' | sed "s/ //g"`
	message_info $step "reads after trimming = $n_reads_trimmed"

	# update metadata
	if [[ $integrate_metadata == "yes" ]]; then
	 	$io_metadata -m add_to_metadata -t 'rnaseq' -s $sample_id -u $run_date -a ADAPTERS_SEQS -v $seqs
	 	$io_metadata -m add_to_metadata -t 'rnaseq' -s $sample_id -u $run_date -a SEED_MISMATCHES -v $seedMismatches
	 	$io_metadata -m add_to_metadata -t 'rnaseq' -s $sample_id -u $run_date -a PALINDROME_CLIP_THRESHOLD -v $palindromeClipThreshold
	 	$io_metadata -m add_to_metadata -t 'rnaseq' -s $sample_id -u $run_date -a SIMPLE_CLIP_THRESHOLD -v $simpleClipThreshold
	 	$io_metadata -m add_to_metadata -t 'rnaseq' -s $sample_id -u $run_date -a MIN_ADAPTER_LENGTH -v $minAdapterLength
	 	$io_metadata -m add_to_metadata -t 'rnaseq' -s $sample_id -u $run_date -a KEEP_BOTH_READS -v $keepBothReads
	 	$io_metadata -m add_to_metadata -t 'rnaseq' -s $sample_id -u $run_date -a LEADING -v $leading
	 	$io_metadata -m add_to_metadata -t 'rnaseq' -s $sample_id -u $run_date -a TRAILING -v $trailing
	 	$io_metadata -m add_to_metadata -t 'rnaseq' -s $sample_id -u $run_date -a TARGET_LENGTH -v $targetLength
	 	$io_metadata -m add_to_metadata -t 'rnaseq' -s $sample_id -u $run_date -a STRICTNESS -v $strictness
	 	$io_metadata -m add_to_metadata -t 'rnaseq' -s $sample_id -u $run_date -a MIN_LENGTH -v $minLength
	 	$io_metadata -m add_to_metadata -t 'rnaseq' -s $sample_id -u $run_date -a N_READS_TRIMMED -v $n_reads_trimmed
		message_info $step "trimmomatic parameters and numbe of trimmed reads added to metadata"
	fi

	# delete intermediate files
	message_info $step "trimmed reads are in $ODIR"
	if [[ $sequencing_type == "PE" ]]; then
		message_info $step "unpaired reads are deleted"
		rm -fr $UNPAIRED
	fi

	message_time_step $step $time0

}


# =================================================================================================
# Align reads with STAR
# =================================================================================================

align_star() {

	step="align_star"
	time0=$(date +"%s")

	# align paired-end reads with STAR
	star_version=`$star --version`
	message_info $step "align trimmed single-end reads with STAR (version = $star_version)"
	message_info $step "using ENCODE standard options for long RNA-seq pipeline"
	# Mapping options adjusted following ENCODE standard options for long RNA-seq found in the 
	# STAR manual https://github.com/alexdobin/STAR/tree/master/doc (note that although this links to the STAR 2.4 manual,
	# the options used here are also available for STAR 2.3, the version used here)
	# --outFilterType BySJout = reduces the number of ”spurious” junctions
	# --outFilterMultimapNmax 20 = max number of multiple alignments allowed for a read: if exceeded, the read is considered unmapped
	# --alignSJoverhangMin 8 = minimum overhang for unannotated junctions
	# --alignSJDBoverhangMin 1 = minimum overhang for annotated junctions
	# --outFilterMismatchNmax 999 = maximum number of mismatches per pair, large number switches off this filter
	# --outFilterMismatchNoverLmax 0.04 = max number of mismatches per pair relative to read length: for 2x50b, 
	# max number of mis- matches is 0.04*100=4 for the pair (default is 0.3 so we are much more restrictive)
	# --alignIntronMin 20: ...
	# --alignIntronMax 1000000: maximum intron length
	# --outSAMtype BAM SortedByCoordinate = output sorted by coordinate
	if [[ $sequencing_type == "SE" ]]; then
		step_log=$LOGS/${sample_id}_${step}_single_end.log
		single1=$SINGLE/${sample_id}_read1.fastq.gz
		ODIR=$STAR/single_end
		params="$single1"
	elif [[ $sequencing_type == "PE" ]]; then
		step_log=$LOGS/${sample_id}_${step}_paired_end.log
		paired1=$PAIRED/${sample_id}_read1.fastq.gz
		paired2=$PAIRED/${sample_id}_read2.fastq.gz
		ODIR=$STAR/paired_end
		params="$paired1 $paired2"
	fi
	mkdir -p $ODIR
	TMP_DIR=$ODIR/my_tmp
	$star \
		    --genomeDir $GENOME_DIR/ \
			--genomeLoad NoSharedMemory \
			--runThreadN $slots \
			--outFilterType "BySJout" \
			--outFilterMultimapNmax 20 \
			--alignSJoverhangMin 8 \
			--alignSJDBoverhangMin 1 \
			--outFilterMismatchNmax 999 \
			--outFilterMismatchNoverLmax 0.04 \
			--alignIntronMin 20 \
			--alignIntronMax 1000000 \
			--alignMatesGapMax 1000000 \
			--readFilesIn $params \
			--outSAMtype BAM SortedByCoordinate \
			--outTmpDir $TMP_DIR/ \
			--outFileNamePrefix $ODIR/$sample_id. \
			--readFilesCommand zcat >$step_log 2>&1
	rm -fr $TMP_DIR
	message_info $step "alignments are in $ODIR"

	# parse step log to extract generated metadata
	message_info $step "parse step log to extract generated metadata"
	# parse
	star_log_final=$ODIR/*Log.final.out
	# uniquely mapped reads
	n_reads_unique=`grep "Uniquely mapped reads number" $star_log_final |cut -f2 -d'|' | sed "s/\t//g"`
	p_reads_unique=`grep "Uniquely mapped reads %" $star_log_final |cut -f2 -d'|' | sed "s/%//g" | sed "s/\t//g"`
	# multi-mappings accepted (i.e. with less locations than specified with --outFilterMultimapNmax)
	n_reads_multi_mapping_accepted=`grep "Number of reads mapped to multiple loci" $star_log_final |cut -f2 -d'|'| sed "s/\t//g"`
	p_reads_multi_mapping_accepted=`grep "% of reads mapped to multiple loci" $star_log_final |cut -f2 -d'|' | sed "s/%//g"| sed "s/\t//g"`
	# multi-mappings excluded (i.e. with more locations than specified with --outFilterMultimapNmax)
	p_reads_multi_mapping_too_many=`grep "% of reads mapped to too many loci" $star_log_final |cut -f2 -d'|' | sed "s/%//g"| sed "s/\t//g"`
	# unmapped too short
	p_reads_unmapped_too_short=`grep "% of reads unmapped: too short" $star_log_final |cut -f2 -d'|' | sed "s/%//g"| sed "s/\t//g"`
	# number of splices detected
	n_splices=`grep "Number of splices: Total" $star_log_final |cut -f2 -d'|'| sed "s/\t//g"`
	message_info $step "reads unique (number) = $n_reads_unique"
	message_info $step "reads unique (percentage) = $p_reads_unique"
	message_info $step "accepted multi-mappings (number) = $n_reads_multi_mapping_accepted"
	message_info $step "accepted multi-mappings (percentage) = $p_reads_multi_mapping_accepted"
	message_info $step "excluded multi-mappings (percentage) = $p_reads_multi_mapping_too_many" 
	message_info $step "reads unmapped too short (percentage) = $p_reads_unmapped_too_short"
	message_info $step "splices (number) = $n_splices"

	# update metadata
	if [[ $integrate_metadata == "yes" ]]; then
	 	$io_metadata -m add_to_metadata -t 'rnaseq' -s $sample_id -u $run_date -a N_READS_UNIQUE -v $n_reads_unique 
	 	$io_metadata -m add_to_metadata -t 'rnaseq' -s $sample_id -u $run_date -a P_READS_UNIQUE -v $p_reads_unique 
	 	$io_metadata -m add_to_metadata -t 'rnaseq' -s $sample_id -u $run_date -a N_READS_MULTI_MAPPING_ACCEPTED -v $n_reads_multi_mapping_accepted 
	 	$io_metadata -m add_to_metadata -t 'rnaseq' -s $sample_id -u $run_date -a P_READS_MULTI_MAPPING_ACCEPTED -v $p_reads_multi_mapping_accepted 
	 	$io_metadata -m add_to_metadata -t 'rnaseq' -s $sample_id -u $run_date -a P_READS_MULTI_MAPPING_TOO_MANY -v $p_reads_multi_mapping_too_many 
	 	$io_metadata -m add_to_metadata -t 'rnaseq' -s $sample_id -u $run_date -a P_READS_UNMAPPED_TOO_SHORT -v $p_reads_unmapped_too_short
	 	$io_metadata -m add_to_metadata -t 'rnaseq' -s $sample_id -u $run_date -a N_SPLICES -v $n_splices
	fi

	# data integrity
	mkdir -p $CHECKSUMS
	shasum $ODIR/$sample_id.*bam >> $checksums

	message_time_step $step $time0

}


# =================================================================================================
# Transcript quantification with featureCounts
# =================================================================================================

quantification_featurecounts() {

	step="quantification_featurecounts"
	time0=$(date +"%s")

	# quantify abundances of transcripts
	# -p = fragments will be counted instead of reads (the 2 paired-end reads are originated from 1 fragment)
	# -g gene_id = summarize reads counts per transcript
	# -s = strandness: 0=unstranded, 1=strand-specific, 2=reversely-stranded
	# ibam = alignments
	# transcripts_gtf = gene models
	message_info $step "quantifying read counts per gene using featureCounts"
	message_info $step "using gene models from $transcripts_gtf"
	message_info $step "kallisto (transcripts) and featurecounts (genes) quantifications are not directly comparable"
	message_info $step "even if the *_mmtv version of the assembly is used, gene/transcript models are the same as for *"
	if [[ $sequencing_type == "SE" ]]; then
		params=""
		IDIR=$STAR/single_end
		ODIR=$FEATURECOUNTS_QUANT/single_end
		message_info $step "sequencing type is $sequencing_type so reads are counted"
		step_log=$LOGS/${sample_id}_${step}_single_end.log
	elif [[ $sequencing_type == "PE" ]]; then
		params="-p"
		IDIR=$STAR/paired_end
		ODIR=$FEATURECOUNTS_QUANT/paired_end
		message_info $step "sequencing type is $sequencing_type so fragments are counted"
		step_log=$LOGS/${sample_id}_${step}_paired_end.log
	fi
	ibam=$IDIR/$sample_id.Aligned.sortedByCoord.out.bam
	mkdir -p $ODIR
	ofile=$ODIR/${sample_id}_featurecounts.txt
	$featureCounts $params \
					-g gene_id \
					-s $strand_specific \
					-T $slots \
					-a $transcripts_gtf \
					-o $ofile \
					$ibam 2>$step_log

	message_info $step "quantifications are in $ODIR"

	# parse step log to extract generated metadata
	message_info $step "parse step log to extract generated metadata"
	# parse
	log_final=$ODIR/*txt.summary
	assigned=`grep "Assigned" $log_final | cut -f2`
	ambiguity=`grep "Ambiguity" $log_final | cut -f2`
	multimapping=`grep "MultiMapping" $log_final | cut -f2`
	no_features=`grep "NoFeatures" $log_final | cut -f2`
	message_info $step "assigned = $assigned"
	message_info $step "ambiguous = $ambiguity"
	message_info $step "multi-mapping = $multimapping"
	message_info $step "no features = $no_features"

	message_time_step $step $time0

}


# =================================================================================================
# Pseudo alignment and transcript quantification with kallisto
# =================================================================================================

quantification_kallisto() {

	step="quantification_kallisto"
	time0=$(date +"%s")

	# perform pseudoalignment and quantify abundances of transcripts
	# Using the option '--bias' produces an error
	# this has been reported and it should be fixed in the future:
	# https://groups.google.com/forum/#!searchin/kallisto-sleuth-users/bias|sort:date/kallisto-sleuth-users/d8nBIxrgESs/GSMKwhhfCgAJ
	message_info $step "performing pseudoalignment and quantifying abundances of transcripts using kallisto"
	message_info $step "using $kallisto_index as transcriptome reference"
	message_info $step "kallisto (transcripts) and featurecounts (genes) quantifications are not directly comparable"
	message_info $step "even if the *_mmtv version of the assembly is used, gene/transcript models are the same as for *"
	message_info $step "sequence based bias correction is only applied to single-end data, as it fails for paired-end"
	if [[ $sequencing_type == "SE" ]]; then
		ODIR=$KALLISTO_QUANT/single_end
		single1=$SINGLE/${sample_id}_read1.fastq.gz
		params="--single -l $fragment_length_avg -s $fragment_length_sd $single1 --bias"
		step_log=$LOGS/${sample_id}_${step}_single_end.log
		message_info $step "for single-end data, the user-provided fragment length average ($fragment_length_avg bp) is used"
		message_info $step "for single-end data, the user-provided fragment length standard deviation ($fragment_length_sd bp) is used"
	elif [[ $sequencing_type == "PE" ]]; then
		ODIR=$KALLISTO_QUANT/paired_end
		paired1=$PAIRED/${sample_id}_read1.fastq.gz
		paired2=$PAIRED/${sample_id}_read2.fastq.gz
		params="$paired1 $paired2"
		step_log=$LOGS/${sample_id}_${step}_paired_end.log
		message_info $step "for paired-end data, the fragment length average and standard deviation are inferred from the data"
	fi
	BOOTSTRAPS=$ODIR/bootstraps
	mkdir -p $BOOTSTRAPS
	$kallisto quant -i $kallisto_index -o $ODIR -t $slots -b $n_bootstraps $params >$step_log 2>&1
	message_info $step "converting form HDF5 to text"
	$kallisto h5dump -o $ODIR $ODIR/abundance.h5 >>$step_log 2>&1
	mv $ODIR/bs_abundance* $BOOTSTRAPS
	message_info $step "quantifications are in $ODIR"

	# parse step log to extract generated metadata
	message_info $step "parse step log to extract generated metadata"
	n_target_transcripts=`grep "number of targets:" $step_log | grep -v ',' |cut -f2 -d':' |sed "s/ //g"`
	n_pseudoaligned=`grep "pseudoaligned" $step_log |sed "s/ /;/g" |cut -f5 -d';' |sed "s/,//g"`
	message_info $step "transcripts quantified (number) = $n_target_transcripts"
	message_info $step "reads pseudoaligned (number) = $n_pseudoaligned"

	message_time_step $step $time0

}


# =================================================================================================
# Make RNA-seq read profiles
# =================================================================================================

make_profiles() {

	step="make_profiles"
	time0=$(date +"%s")

	message_info $step "make read profiles from STAR alignments"
	message_info $step "filtering valid pairs (for paired-end data only) and convert BAM to BED"

	if [[ $sequencing_type == 'SE' ]]; then
		IDIR=$STAR/single_end
		if [ -d $IDIR ]; then
			ODIR=$PROFILES/single_end
			mkdir -p $ODIR
	 		ibam=$IDIR/${sample_id}.Aligned.sortedByCoord.out.bam
	 		obed=$ODIR/${sample_id}.bed
 			step_log=$LOGS/${sample_id}_${step}_single_end.log
	 		$bamToBed -i $ibam > $obed
	 	else
			message_error $step "$IDIR not found. Exiting..."
		fi
	elif [[ $sequencing_type == 'PE' ]]; then
		IDIR=$STAR/paired_end
		if [ -d $IDIR ]; then
			ODIR=$PROFILES/paired_end
			mkdir -p $ODIR
	 		ibam=$IDIR/${sample_id}.Aligned.sortedByCoord.out.bam
	 		obed=$ODIR/${sample_id}.bed
 			step_log=$LOGS/${sample_id}_${step}_paired_end.log
	 		$samtools view -bf 0x2 $ibam | $bamToBed -i stdin > $obed
	 	else
			message_error $step "$IDIR not found. Exiting..."
		fi
	fi

	# convert BED to bigWig (more suitable for UCSC Genome Browser uploads)
	message_info $step "converting BED to bigBed (more suitable for UCSC Genome Browser uploads)"
	obb=$ODIR/${sample_id}.bb
	$bed2bb $obed $chrom_sizes $obb >$step_log 2>&1
	message_info $step "profiles are in $ODIR"

	# delete intermediate BED
	message_info $step "delete intermediate BED"
	rm $obed

	message_time_step $step $time0

}

main
