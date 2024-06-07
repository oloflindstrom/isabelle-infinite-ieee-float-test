#!/bin/bash

set -e

function error() {
  echo "mktests_error: " $@ >> OUTPUT_errors.log
}

# Berkeley TestFloat
TESTFLOAT=./TestFloat-3e/build/Linux-x86_64-GCC

TFGEN=$TESTFLOAT/testfloat_gen

format="$1"
opr="$2"
rmode="$3"
t_case="$4"
modechecker="$5"
numtests="$6"
compare_var="$7"
debug="$8"

# Lockfiles for handling concurrent writes
# to log files
S_LOCK=./lockfile_A
F_LOCK=./lockfile_B
E_LOCK=./lockfile_C
D_LOCK=./lockfile_D

# Sleep between 0.6--0.9 s
function sleep_random() {
  sleep .$(( $RANDOM % 4 + 6 ))
}

# Try to acquire lock before writing to output file
function acquire_lock() {
  while ! (set -o noclobber; echo "$$" > "$1") 2> /dev/null; do
    sleep_random
  done
}

# Parse rounding and translate to TestFloat syntax
function xrm() {
  if   [[ $1 == "=0" ]]; then  echo "near_even";
  elif [[ $1 == "0" ]]; then  echo "minMag";
  elif [[ $1 == ">" ]]; then  echo "max"
  elif [[ $1 == "<" ]]; then  echo "min"
  else
    acquire_lock "$E_LOCK"
    error "Unknown_rounding_mode:_'$1'"
    rm -f "$E_LOCK"
  fi
}

# Parse operator and translate to TestFloat syntax
function xop() {
  if   [[ $1 == "+" ]]; then echo "add"
  elif [[ $1 == "-" ]]; then  echo "sub"
  elif [[ $1 == "*" ]]; then  echo "mul"
  elif [[ $1 == "/" ]]; then  echo "div"
  elif [[ $1 == "V" ]]; then  echo "sqrt"
  elif [[ $1 == "*+" ]]; then  echo "mulAdd"
  elif [[ $1 == "ceq" ]]; then  echo "eq"
  elif [[ $1 == "cle" ]]; then  echo "le"
  elif [[ $1 == "clt" ]]; then  echo "lt"
  elif [[ $1 == "cge" ]]; then  echo "le"
  elif [[ $1 == "cgt" ]]; then  echo "lt"  
  else 
    acquire_lock "$E_LOCK"
    error "Unknown_operation:_'$1'"
    rm -f "$E_LOCK"
  fi
}

# Align prints to `OUTPUT_stats.log`
# for better readability
function print_align() {
  if [[ $1 == ">" ]] || [[ $1 == "<" ]]
  then
    echo -e "\t"
  elif [[ ${1:0:1} == "c" ]]
  then
    echo " ("$1")"
  fi
}

# Allow for inf test cases and restrict
# numtests to non-zero natural numbers
function if_forever() {
  if [ "$numtests" == "inf" ]; then
    cat
  elif [[ "$numtests" =~ ^[0-9]+$ ]] && [[ ! "${numtests:0:1}" == "0" ]]; then
    head -n "$numtests"
  else 
    acquire_lock "$E_LOCK"
    error "Invalid_n_variable_'$numtests'"
    rm -f "$E_LOCK"
  fi
}

# Generate, format, and handle TestFloat vectors
function gen_tf() {
  level=$1
  forever=$2

  i=1

  $TFGEN "f${format}_$(xop "$opr")" "-r$(xrm "$rmode")" -level "$level" "$forever" \
  | if [ "$modechecker" == "normal" ]; then
      # Proper test vector
      gawk -v compare_var="$compare_var" '{ for (i=1;i<NF-compare_var;++i) \
      $(i) = " 0x" $(i); NF=NF-1; print }'
    elif [ "$modechecker" == "fcheck" ]; then
      # Set up test vector to fail
      gawk -v compare_var="$compare_var" '{ for (i=1;i<NF-compare_var;++i) \
      $(i) = substr(" 0x" $(i), 1, length(" 0x" $(i))-1) "3"; NF=NF-1; print }'
    elif [ "$modechecker" == "echeck" ]; then
      # Set up test vector to err
      gawk -v compare_var="$compare_var" '{ for (i=1;i<NF-compare_var;++i) \
      $(i) = " 0x" $(i); print }'
    fi \
  | sed "s|^|b${format}${opr} ${rmode} |" \
  | if_forever \
  | while IFS= read -r testvector; do
      # Write test vectors to debug file (optional)
      if [ "$debug" == "debug" ]; then
        acquire_lock "$D_LOCK"
        echo "$testvector" >> OUTPUT_debug.log
        rm -f "$D_LOCK"
      fi
      # Pipe formatted test vectors to fp_test
      ./fp_test/fp_test "$testvector" | while IFS= read -r failedtest; do
        if [[ $failedtest == FAIL* ]]; then
          acquire_lock "$F_LOCK"
          echo "$failedtest" >> OUTPUT_failed.log
          rm -f "$F_LOCK"
        fi
        if [[ ! $failedtest == FAIL* ]]; then
          acquire_lock "$E_LOCK"
          echo "$failedtest" >> OUTPUT_errors.log
          rm -f "$E_LOCK"
        fi
      done
      # Frequency of stats/iterations updates
      if (( i % 10000 == 0 )) || \
         (( i <= 100000 && i % 1000 == 0 )) || \
         (( i <= 10000 && i % 500 == 0 )) || \
         (( i <= 100 && i % 10 == 0 )) || \
         (( i == numtests ))
      then
        acquire_lock "$S_LOCK"

        # Writing stats and iterations
        sed -i "${t_case}s/.*/"f${format}_$(xop "$opr")"$(print_align "$opr") \t \
"-r$(xrm "$rmode")"$(print_align "$rmode") \t n: ${i}/" OUTPUT_stats.log

        rm -f "$S_LOCK"
      fi
      i=$((i+1))
    done
}

gen_tf 2 -forever
