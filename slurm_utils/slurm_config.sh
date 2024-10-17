#!/bin/bash

# User inputted values for slurm script

#   * Slurm settings
THREADS=12
TASKS=1
MEMORY=15000
NODES=1
HOURS=30
SLURM_ID=jobname        # slurm job name

#   * Cluster details
CLUSTER_USER=username
CLUSTER_NAME=clustername    # cluster name
CLUSTER_ACC=clusteraccount   # cluster account name

#   * Script looping settings
breaktime=0     # run all scripts (0) or specify a number of files with max_loop (1)
max_loop=2      # number of scripts to run
MOD_STR="*"     # identifier for scripts to run: "*" for all mods or T1w= "*T1w*"
search_out=1    # run scripts that are currently running (0) or not (1)
sleeponit=0     # choice to sleep for 5hours before running the loop

#   * directories
SCRIPT_DIR=$PWD/work/run_files       # scripts to run
RESULTS_DIR=$PWD/results/top         # outputted results from completed scripts
