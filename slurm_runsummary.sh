
SLURM_DIR=${1:-$PWD/work/slurm}
source "$SLURM_DIR"/slurm_utils/slurm_utils.sh $SLURM_DIR


# CHECK ALL OUT FILES
TOTAL=$(find $fin_dir -type f -name '*.err' | wc -l)
DUNZO=0
FAIL=0
durations=()
LONGO=0
echo -e '\nChecking finished scripts (n='$TOTAL')...\n'
declare -A dur_array

for file in $(find $fin_dir -type f -name '*.err'); do
  emoji=❔
  status=''
  run_name=${file%%.err}
  run_name=$(basename "$run_name")

  outfile=$(find $fin_dir -type f -name "*$run_name*.out")
  run_message=$big_break
  run_message+=$'\nFile: '$(basename "$file")
  run_message+=$'\n\t * read .err: '$(grep -R 'tuning' "$file" | tail -n 1)

  if grep -R 'Execution halted' "$file" > /dev/null ; then
    (( FAIL++ ))
    status="failed"
    emoji=$flag
    run_message+=$'\n\t * err file:\n'
    run_message+=$(tail -n 5 "$file")
    rm -vf $file

  fi
  if grep -R 'CANCELLED' "$file" > /dev/null ; then
    (( FAIL++ ))
    status="failed"
    emoji=$cancel
    run_message+=$'\n\t * err file:\n'
    run_message+=$(tail -n 1 "$file")
    rm -vf $file
  fi


  if grep -R 'workflow completed' "$outfile" > /dev/null ; then
    (( DUNZO++ ))
    status="finished"
    emoji=$tick
    run_message+=$'\n\t * '
    duration_str=$(tail -n 2 "$outfile"  | head -n 1)
    run_message+=$duration_str

    duration=$(echo $duration_str | grep -oP '\d+\.\d+' | awk '{print $1}')

    if echo "$duration_str" | grep -q "mins"; then
      hours=$(echo "$duration / 60" | bc -l)
      hours=$(printf "%.3f" "$hours")
      duration=$hours
    fi
    durations+=($duration)
    dur_array["$duration"]=$run_message
    if (( $(echo "$duration > $LONGO" | bc -l) )); then
      LONGO=$duration
    fi

  fi

  run_message+=$'\n '"$emoji$emoji$emoji$emoji$emoji$emoji$emoji$emoji$emoji$emoji$emoji$emoji$emoji $status $emoji$emoji$emoji$emoji$emoji$emoji$emoji$emoji$emoji$emoji$emoji$emoji$emoji"
  echo -e "$run_message"
done

sort_durs=($(for i in "${durations[@]}"; do echo $i; done | sort -gr))



echo -e  '\n\n>< >< >< >< >< >< >< >< >< >< >< >< >< >< >< >< >< >< >< ><>< >< >< >< >< >< >< >< >< >< >< >< >< ><\n'
echo -e '\t\t🐌🐌🐌🐌 Longest :' $LONGO 'hours 🐌🐌🐌🐌'
for key in "${sort_durs[@]:0:3}"; do
  echo -e "${dur_array[$key]}"
done

echo -e '\n\n\t\t🐎🐎🐎🐎 Shortest running 🐎🐎🐎🐎'
for key in "${sort_durs[@]: -3}"; do
  echo -e "${dur_array[$key]}"
done

echo -e '\n\n  Total: '$TOTAL
echo -e  '\n>< >< >< >< >< >< >< >< >< >< >< >< >< >< >< >< >< >< >< ><>< >< >< >< >< >< >< >< >< >< >< >< >< ><\n'



# stop_key="R is aborting now"
# echo $stop_key
# for p in $(ls slurm/slurm_output/err/); do
#   if grep -q "$stop_key" slurm/slurm_output/err/$p; then
#     sid=$(echo $p | grep -oE '[0-9]{8}')
#     echo -e '\t * File:' $p | sed -E 's/-[0-9]+\.err$//'
#     echo -e  '\t\t * Checking slurm id:' $sid
#     #scancel $sid
#     rm -fv slurm/slurm_output/err/$p
#   fi
# done

#CHECK ERRORS
#for f in $(ls work/slurm/slurm_output/err/ | grep err); do
  #in=$(grep -q 'Error in serialize' work/slurm/slurm_output/err/$f)
  #if [ -n $in ];then
    #echo -e 'Removing: '$f;
  #fi;
#done

#CHECK ERRORS
#for f in $(ls work/slurm/slurm_output/err/ | grep err); do
  #in=$(grep -q 'Error in serialize' work/slurm/slurm_output/err/$f)
  #if [ -n $in ];then
    #echo -e 'Removing: '$f;
  #fi;
#done
