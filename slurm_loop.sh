#!/bin/bash
SLURM_DIR=${1:-$PWD/work/slurm}
SLURM_UTILS=$SLURM_DIR/slurm_utils
source "$SLURM_UTILS"/slurm_utils.sh $SLURM_DIR

if [ "$sleeponit" -eq 1 ]; then
  echo -e 'Having a little nap... '
  sleep 5h
  echo -e 'Checking the uninitiated... '
  for l in $(squeue | grep 0:00 | grep $CLUSTER_USER | awk '{print $1}'); do
    echo -e '\n* Slurm ID:' $l;
    squeue | grep $l
    scancel $l
  done
fi

#make directories
mkdir -p "$SLURM_OUT/run/" "$SLURM_OUT/err/" "$SLURM_OUT/out/" "$SLURM_OUT/failed/" "$SLURM_OUT/finished/"

#Check for results in results dir
total_ex=()
results=()
echo -e '\n-------------------------------\nChecking results csvs... '

for path in $(find $RESULTS_DIR -type f -name "*$MOD_STR*.csv"); do
    csv=$(basename $path)
    string=${csv//}
    string=${string%%_results-top.csv}
    results+=("$string")
    total_ex+=("$string")
    find "$SLURM_OUT/out/" -type f -name "*$string*" -exec mv {} "$SLURM_OUT/finished" \;
    find "$SLURM_OUT/err/" -type f -name "*$string*" -exec mv {} "$SLURM_OUT/finished" \;
done

len_res=${#results[@]}
echo -e '\n\nResults files to exclude: '
echo -e '\t * Results: ' $len_res
echo -e '-------------------------------'

if [ "$search_out" -eq 1 ]; then
  out_files=()
  echo -e 'Checking slurm IDs... '

  for sID in $(squeue | grep mollyi | awk '{print $1}'); do
    path=$(find $SLURM_OUT/out/ -type f -name  "*$MOD_STR*$sID*")
    if [ -n "$path"  ]; then
      path=$(basename $path)
      string=$(echo "$path" | sed -E 's/-[0-9]+\.out$//')
      total_ex+=("$string")
      out_files+=("$out_files")
      echo -e "\t * Slurm ID: $sID\t  * File: "$string
    fi
  done

  len_out=${#out_files[@]}
  echo -e '\n\n .out files to exclude: '
  echo -e '\t * .out: ' $len_out
  echo -e '-------------------------------'
  echo -e '* Total excluded: ' $(($len_out++$len_res))
fi

len_total=${#total_ex[@]}
echo '-------------------------------'

#counters
N=$(find $SCRIPT_DIR -type f -name "*$MOD_STR*.R" | wc -l)
LEFT=$N
COUNTER=0
MATCHES=0
#run lists
skipped=()
running=()

echo -e '\n\t\t  Searching for files to run...\n'
for script in $(find $SCRIPT_DIR -type f -name "*$MOD_STR*.R"); do
  match_found=0
  for string in "${total_ex[@]}"; do
      check=$(basename $script)
      check=${check%%.R}

      if echo "$string" | grep -q "$check"; then
        match_found=1
        (( MATCHES ++ ))
        (( LEFT -- ))
        break
      fi
    done
  if [ "$match_found" -eq 0 ]; then  #Optional breakpoint
    if [ "$breaktime" -eq 1 ]; then
      if [ "$COUNTER" -eq $max_loop ]; then
        echo -e '\n\n\t\t\t-------------------------------'
        echo -e "\t\t\t Break point at $max_loop"
        echo -e "\t\t\t\t * Matches:    $MATCHES"
        echo -e '\t\t\t-------------------------------'
        break
      fi
    else
      max_loop=$LEFT
    fi

    #Run if no match found
    (( COUNTER++ ))
    file_name=$(basename $script)
    FILE_ID=${file_name%%".R"}
    SLURM_SCRIPT="$SLURM_OUT/run/"$FILE_ID".script"
    find "$SLURM_OUT/run/" -type f -name "*$FILE_ID*" -exec rm {} \;
  	find "$SLURM_OUT/err/" -type f -name "*$FILE_ID*" -exec mv {} "$SLURM_OUT/failed" \;
  	find "$SLURM_OUT/out/" -type f -name "*$FILE_ID*" -exec mv {} "$SLURM_OUT/failed" \;

    $SLURM_UTILS/slurm_gen.sh $SLURM_ID $script $FILE_ID $SLURM_SCRIPT $SLURM_DIR #$THREADS $TASKS $MEMORY
    job_id=$(sbatch  $SLURM_SCRIPT)
    echo -e "\t * Run #$COUNTER (ID: $job_id)  :" $(basename $SLURM_SCRIPT)
  else
    skipped+=($(basename "$script"))
  fi
done


echo -e '\n--------------------------------------------------------------\n Skipped files:\n'
echo -e '\t * Results: ' $len_res
echo -e '\t * .out: ' $len_out
echo -e '* Total: ' $(($len_out++$len_res))

echo -e '\n\n--------------------------------------------------------------\n Final run details:'
echo -e "\t * Total files:" $N
echo -e "\t * Files to run:" $LEFT
echo -e "\t * Run count:" $COUNTER
echo -e '\n Cluster run details:'
echo -e "\t * Cores per task:" $THREADS
echo -e "\t * Tasks per node:" $TASKS
echo -e "\t * Memory (GB):" $MEMORY
echo -e "\t * Duration:" $HOURS
echo -e "\t * Job ID:" $SLURM_ID
echo -e '--------------------------------------------------------------\n'
