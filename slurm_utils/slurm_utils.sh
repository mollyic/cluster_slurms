#!/bin/bash

# Slurm formatting applied across all scripts
SLURM_DIR=$1

source "$SLURM_DIR"/slurm_utils/slurm_config.sh

#   * directories
SLURM_OUT=$SLURM_DIR/slurm_output    #output slurm scripts (.err/.out)
fin_dir=$SLURM_OUT/finished  #successfully finished scripts

#   * Line formatting
big_break='\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~'
flag=🚩
tick=✅
run=💧
cancel=🔒
