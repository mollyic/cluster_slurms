#!/bin/bash
SLURM_ID=$1
RUN_FILE=$2
FILE_ID=$3
SLURM_SCRIPT=$4
SLURM_DIR=$5

source "$SLURM_DIR"/slurm_utils/slurm_utils.sh $SLURM_DIR
# #SBATCH --mem=$MEM
echo "#!/bin/bash
#SBATCH --job-name=$SLURM_ID
#SBATCH --account=$CLUSTER_ACC
#SBATCH --time=0-$HOURS:00:00
#SBATCH --output=$SLURM_OUT/out/"$SLURM_ID"_"$FILE_ID"-%j.out
#SBATCH --error=$SLURM_OUT/err/"$SLURM_ID"_"$FILE_ID"-%j.err
#SBATCH --mem-per-cpu=$MEMORY
#SBATCH --cpus-per-task=$THREADS               #CPUs: (or cores) per task: (6: 30s to 7.5s, 12: 7.5 to 4.5)
#SBATCH --nodes=$NODES                         #NODE: number of computers in cluster
#SBATCH --ntasks-per-node=$TASKS               #TASK:  tasks (instances of program) per node


module load R/4.4.0
Rscript $RUN_FILE

">> $SLURM_SCRIPT
