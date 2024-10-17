runner=${1:-'runners'}  #runners = check all runnings files, all = check running and done
choice=${2:-''}  #check run,done or fail output
slurm_jobname=${3:-'*'} # name of job to look up 'sleepy8'
SLURM_DIR=${4:-$PWD/work/slurm}

source "$SLURM_DIR"/slurm_utils/slurm_utils.sh $SLURM_DIR

# CHECK RUNNING OUT FILES
if [[ $runner == 'runners' ]]; then
  echo -e '\nChecking running slurm statuses..\n'
  readarray -t t < <(squeue | grep $CLUSTER_USER | grep $CLUSTER_NAME | awk '{print $1}')
  for p in $(echo ${t[@]}); do
    file=$(find "$SLURM_OUT"/ -type f -name "*$p*.err")
    echo -e 'File: '$(basename $file) '\t(Slurm ID: '$p')'
    echo -e '\t * Last updated: '$(ls -la $(dirname $file) | grep $p | grep '.err' | awk '{print $8}')
    echo -e '\t * Run time: '$(squeue | grep $p | awk '{print $6}')
    #echo -e '\t * Status:'  $(grep -R 'tuning' $file| tail -n 1)
    echo -e "\n"
  done
  echo -e '_____________\n\n  Total running: ' ${#t[@]} '\n_____________\n'
fi

# CHECK ALL OUT FILES
if [[ $runner == 'all' ]]; then
  TOTAL=$(find "$SLURM_OUT"/err -type f | wc -l)
  DUNZO=0
  FAIL=0
  RUNNERS=0

  LONGO=()
  echo -e '\nChecking .err and out file statuses (n='$TOTAL')...\n'
  #choice=''
  for file in $(find "$SLURM_OUT"/err -type f -name "*$slurm_jobname*"); do
    emoji=❔
    status=''
    run_name=${file%%.err}
    run_name=$(basename "$run_name")
    outfile=$(find "$SLURM_OUT"/out/ -type f -name "*$run_name*")
    run_message=$big_break
    run_message+=$'\nFile: '$(basename "$file")
    run_message+=$'\n\t * read .err: '$(grep -R 'tuning' "$file" | tail -n 1)

    if grep -R 'Execution halted' "$file" > /dev/null ; then
      (( FAIL++ ))
      status="failed"
      emoji=$flag
      run_message+=$'\n\t * err file:\n'
      run_message+=$(tail -n 5 "$file")
    fi
    if grep -R 'CANCELLED' "$file" > /dev/null ; then
      (( FAIL++ ))
      status="failed"
      emoji=$cancel
      run_message+=$'\n\t * err file:\n'
      run_message+=$(tail -n 1 "$file")
    fi


    if grep -R 'workflow completed' "$outfile" > /dev/null ; then
      (( DUNZO++ ))
      status="finished"
      emoji=$tick
      run_message+=$'\n\t * Duration :\n'
      run_message+=$(tail -n 11 "$outfile")
    fi

    string=$(echo "$run_name" | sed -E 's/.*-([0-9]+)$/\1/')
    run_id=$(squeue | grep "$string" | awk '{print $1}')
    if [ ${#run_id} -gt 0 ]; then
      (( RUNNERS++ ))
      #echo -e 'Run id: '$run_id
      run_message+=$'\n\t * run time: '$(squeue | grep "$string" | awk '{print $6}')
      status="running"
      emoji=$run

      file_mtime=$(stat -c %Y "$file")
      current_time=$(date +%s)
      time_diff=$(( (current_time - file_mtime) / 60 ))
      err_check=$(ls -la "$file" | awk '{print $8}')
      run_message+=$'\n\t * slurm id: '$run_id
      run_message+=$'\n\t * err updated: '$err_check
      run_message+=$'\n\t * last update: '$time_diff' mins'
      run_message+=$'\n\t * out file:\n'
      run_message+=$(tail -n 5 "$outfile")

      if [ "$time_diff" -gt 30 ]; then
        LONGO+=$run_message
      fi
    fi

    run_message+=$'\n\n '"$emoji$emoji$emoji$emoji$emoji$emoji$emoji$emoji$emoji$emoji$emoji$emoji$emoji $status $emoji$emoji$emoji$emoji$emoji$emoji$emoji$emoji$emoji$emoji$emoji$emoji$emoji"

    if [ ${#choice} -eq 0 ]; then
      echo -e "$run_message"
    else
      if echo "$choice" | grep -q "done"; then
        if [[ $status == 'finished' ]]; then
          echo -e "$run_message"
        fi
      fi

      if echo "$choice" | grep -q "run"; then
        if [[ $status == 'running' ]]; then
          echo -e "$run_message"
        fi
      fi

      if echo "$choice" | grep -q "fail"; then
        if [[ $status == 'failed' ]]; then
          echo -e "$run_message"
        fi
      fi

    fi
  done

  echo -e '_____________\n\n  Long bois: '
  for longbois in "${LONGO[@]}"; do
    echo -e "$longbois"
  done

  echo -e  '\n_____________\n'

  echo -e '_____________\n\n  Total: '$TOTAL
  echo -e '\t * Failed:' $FAIL
  echo -e '\t * Running:' $RUNNERS
  echo -e '\t * Finished:' $DUNZO
  echo -e  '\n_____________\n'

fi
