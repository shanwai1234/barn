#!/usr/bin/env Rscript
suppressPackageStartupMessages(library("argparse"))

parser <- ArgumentParser(description = 'Add fastq stats to sample list')
parser$add_argument("samplelist", nargs=1, help="sample list table (*.tsv)")
parser$add_argument("fastqc", nargs=1, help="fastqc report table (*.txt)")
parser$add_argument("out", nargs=1, help="output sample list (*.tsv)")
args <- parser$parse_args()

f_sam = args$samplelist
f_fqc = args$fastqc
f_out = args$out

if( file.access(f_sam) == -1 )
    stop(sprintf("file ( %s ) cannot be accessed", f_sam))
if( file.access(f_fqc) == -1 )
    stop(sprintf("file ( %s ) cannot be accessed", f_fqc))

require(tidyverse)
get_fastqc <- function(sid, paired, tq) {
    #{{{
    if(paired) {
        ptn = sprintf("^%s_[12]", sid)
        tq1 = tq %>% filter(str_detect(sid, ptn))
        stopifnot(nrow(tq1) == 2)
        nread1 = tq1$nread[1]; nread2 =  tq1$nread[2]
        stopifnot(nread1 == nread2)
        len1 = tq1$avgLength[1]; len2 =  tq1$avgLength[2]
        spots = nread1
        len = round(len1 + len2)
    } else {
        tq1 = tq %>% filter(sid == !!sid)
        stopifnot(nrow(tq1) == 1)
        spots = tq1$nread[1]
        len = tq1$avgLength[1]
    }
    tibble(spots=spots, avgLength=len)
    #}}}
}

ti = read_tsv(f_sam)
tq = read_tsv(f_fqc) %>% select(sid=1, nread=5, avgLength=10)

cols_to_rm = c('interleaved','r0','r1','r2','spots','avgLength')
for(col_to_rm in cols_to_rm) {
    if(col_to_rm %in% colnames(ti)) ti = ti %>% select(-!!col_to_rm)
}

to = ti %>%
    mutate(data = map2(SampleID, paired, get_fastqc, tq=tq)) %>%
    unnest()

write_tsv(to, f_out, na='')



