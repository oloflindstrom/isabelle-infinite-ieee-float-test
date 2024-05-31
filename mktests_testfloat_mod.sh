#!/bin/bash

MODECHECKER="$1"
NUMTESTS="$2"
DEBUG="$3"

i=0

if ls lockfile* 1> /dev/null 2>&1; then
  echo "Error: lockfile detected. Please remove it using 'make kill'."
  exit 1
fi

echo -e "\nWarning: sudo right are needed to abort the large number of \
processes that will be created.\nThis is done using 'make kill', or by \
killing all the instances of 'mktests_testfloat_mod_aux.sh' in some other way.\n\
No warranty is provided for potentially lost sessions.\n
Do you wish to continue? y/n"

read user_input
while [[ "$user_input" != "y" && "$user_input" != "Y" && \
"$user_input" != "n" && "$user_input" != "N" ]]; do
  read user_input
done
if [[ $user_input == "y" || $user_input == "Y" ]]; then  :
elif [[ $user_input == "n" || $user_input == "N" ]]; then
  echo "Exiting"
  exit 1
fi

rm -f ./*.log
touch OUTPUT_stats.log OUTPUT_failed.log OUTPUT_errors.log

# Prepare empty lines needed for altering of prints with sed
for j in {1..116}
do
  echo "" >> OUTPUT_stats.log
done

# Create combinations for FP arithmetic and FP comparison
for format in 16 32 64 128; do
  for ari_opr in '+' '-' '*' '/' 'V' '*+'; do
    for rmode in '0' '=0' '<' '>'; do
      i=$((i+1))
      nohup bash mktests_testfloat_mod_aux.sh "$format" "$ari_opr" "$rmode" "$i" \
      "$MODECHECKER" "$NUMTESTS" 0 "$DEBUG" > /dev/null 2> testfloat_gen_error.log &
    done
  done
  for comp_opr in 'ceq' 'cle' 'clt' 'cge' 'cgt'; do
    i=$((i+1))
    nohup bash mktests_testfloat_mod_aux.sh "$format" "$comp_opr" '0' "$i" \
    "$MODECHECKER" "$NUMTESTS" 1 "$DEBUG" > /dev/null 2> testfloat_gen_error.log &
  done
done
