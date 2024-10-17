# Slurm script generator and monitor for HPCs

Script generates individual slurm script files for individual run files to be run on HPC. There are 3 functional scripts:
1. `slurm_loop.sh`: generates slurm scripts and runs them on the cluster
2. `slurm_checks.sh`: checks the duration and last updates on running jobs and checks the status of completed jobs
3. `slurm_runsummary.sh`: provides a summary of the runtime durations for completed jobs



## Requirements
**Run files**: the individual scripts to run on the cluster. Each slurm job corresponds to a single script. For example a directory of R scripts (.py) that execute the main script with different sets of parameters.

#### Run files example
`file1.R` and `file2.R` run the main script with different variables. The `slurm_loop.sh` will run each of these R files as a job on the HPC.

```
# file1.R
var1<-  5
var2<-  10
source('main.R')

# file2.R
var1<-  2000
var2<-  2
source('main.R')
```

## Configuration

### 1. Slurm script generator
The `slurm_utils/slurm_gen.sh` is the default template for generating the slurm script. It is necessary to load the packages to run the script in the slurm job (e.g. pandas) and execute the file in the correct language (e.g. Python).

- The current template is configured to run R scripts:
```
# add modules (e.g. R)
module load R/4.4.0

#add interpreter (e.g. Rscript) to read and execute script
Rscript $RUN_FILE
```
- Python example:
```
# add modules (e.g. R)
module load fsl/6.0.5.1
module load ants
module load freesurfer/7.4.0
export FSLOUTPUTTYPE=NIFTI_GZ

#add interpreter (e.g. Rscript) to read and execute script
python3 $RUN_FILE
```


### 2. Slurm job configuration
Input parameters should be provided to the file `slurm_utils/slurm_config.sh` file:

- slurm job details
```
#   * Slurm settings
THREADS=12              # threads for the job
TASKS=1                 # tasks per node for the job
MEMORY=15000            # memory per node for the job
NODES=1                 # total nodes for the job
HOURS=30                # duration for the job
SLURM_ID=jobname        # slurm job name
```

- HPC details
```
#   * Cluster details
CLUSTER_USER=username        # HPC username
CLUSTER_NAME=clustername     # HPC name
CLUSTER_ACC=clusteraccount   # HPC account name
```

- Configure identifiers and number of scripts to run on cluster
```
#   * Script looping settings
breaktime=0     # run all scripts (0) or specify a number of files with max_loop (1)
max_loop=2      # number of scripts to run
MOD_STR="*"     # identifier for scripts to run: "*" for all mods or T1w= "*T1w*"
search_out=1    # rerun scripts that are already running (0) or not (1)
sleeponit=0     # choice to sleep for 5hours before running the loop
```

  - Input and output directories
```
#   * directories
SCRIPT_DIR=$PWD/work/run_files       # directory with scripts to run
RESULTS_DIR=$PWD/results/top         # outputted results from completed scripts
```


## `slurm_loop.sh` usage

Generate and run slurm scripts.

```
# uses default slurm directory: $PWD/work/slurm
bash slurm_loop.sh

# specify slurm directory:
bash slurm_loop.sh $PWD/slurm
```

### Example output
- the script only runs jobs if the script has no result file
```
-------------------------------
Checking results csvs...        


Results files to exclude:
	 * Results:  0
-------------------------------
```
- or if it is already running
```
Checking slurm IDs...


 .out files to exclude:
	 * .out:  0
-------------------------------
* Total excluded:  0
-------------------------------
```
- The job ids are then shown alongside the newly generated script filenames
```

		  Searching for files to run...

	 * Run #1 (ID: )  : name1.script
	 * Run #2 (ID: )  : name2.script


			-------------------------------
			 Break point at 2
				 * Matches:    0
			-------------------------------
```
- If any files are skipped, as they are completed or still running, a summary is shown
```
--------------------------------------------------------------
 Skipped files:

	 * Results:  0
	 * .out:  0
* Total:  0

```
- A summary of the total running jobs is provided at the end
```
--------------------------------------------------------------
 Final run details:
	 * Total files: 27
	 * Files to run: 27
	 * Run count: 2

 Cluster run details:
	 * Cores per task: 12
	 * Tasks per node: 1
	 * Memory (GB): 15000
	 * Duration: 30
	 * Job ID: jobname
--------------------------------------------------------------
```


## `slurm_checks.sh` usage
Check on running and completed slurm scripts

```
# Provides summary of running jobs:
bash slurm_checks.sh

# Provides more detailed overview of running, failed and completed jobs:
bash slurm_checks.sh all

# Provides more detailed overview of completed jobs:
bash slurm_checks.sh all done

# Provides more detailed overview of failed jobs:
bash slurm_checks.sh all fail

# Provides more detailed overview of running jobs:
bash slurm_checks.sh all run

```
### Example output
- `slurm_checks.sh`: quick overview of each job, the 'out file' field prints last lines of job .out file

```
File: cls_qlty_FLAIR_pccomps-20_weights-w_invsqr_type-avg_quality_mode-classification-299987.err 	(Slurm ID: 299987)
	 * Last updated: 12:09
	 * Run time: 2:25:08
	 * Status:


File: cls_qlty_FLAIR_pccomps-20_weights-w_inverse_type-avg_quality_mode-classification-299988.err 	(Slurm ID: 299988)
	 * Last updated: 12:09
	 * Run time: 2:25:08
	 * Status:
```
- `slurm_checks.sh all`: detailed summary of each job, the 'out file' field prints last lines of job .out file
```
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
File: jobfilename-254599987.err
	 * read .err:
	 * run time: 51:45
	 * slurm id: 254599987
	 * err updated: 12:09
	 * last update: 51 mins
	 * out file:

# last lines of job .out file

 💧💧💧💧💧💧💧💧💧💧💧💧💧 running 💧💧💧💧💧💧💧💧💧💧💧💧💧

```

## `slurm_runsummary.sh` usage
- Present summary of completed scripts
```
bash slurm_runsummary.sh
```
