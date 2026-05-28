#!/usr/bin/env bash

printf "%s\n" "1. Checking dependencies..."
cat dependencies.ini | grep "=" |\
while IFS= read -r line; do
cmd="${line%%=*}"
inst="${line#*=}"

done