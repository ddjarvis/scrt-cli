#!/usr/bin/env bash

function trap_sig() {
	printf "\nCaught signal: xxx. Exiting...\n"
	exit 1
}
trap trap_sig SIGINT SIGTERM

list_lv=()
list_labels=(
	"15 Seconds"
	"30 Seconds"
	"1 Minute"
	"2 Minutes"
	"5 Minutes"
	"10 Minutes"
	"Custom"
)
list_values=(
	"15" "30" "60"
	"120" "300" "600"
	"0"
)
for (( i = 0; i < ${#list_labels[@]}; i++ )); do {
	lv="${list_labels[$i]}:${list_values[$i]}"
	list_lv+=("${lv}")
} done

function getCustomTimeInput() {
	gum input \
		--no-show-help \
		--header="Custom Time (S)"$'\n' \
		--prompt="⏳ " \
		--header.foreground="220" \
		--cursor.foreground="136" \
		--placeholder="Enter time in seconds..."
}
function getCustomTime() {
	local input time_s time_hms
	local regex="[[:space:]]*0*(([[:digit:]]+)?(\.[[:digit:]]*[1-9])?)0*[[:space:]]*"
	
	local confirmed=0
	local valid=0
	local err=0
	
	while (( valid == 0 && confirmed == 0 )); do {
		valid=0; time_s=""
		input="$(getCustomTimeInput)"; err=$?
		if (( err == 130 )); then {
			printf "\e[2F\e[0J%s\n" "Operation canceled." >&2
			return 130
		} fi
		if [[ "${input}" =~ ${regex} ]]; then {
			time_s="${BASH_REMATCH[1]}"
		} fi
		if [[ -n "${time_s:+x}" ]]; then {
			valid=1
		} else {
			printf "Invalid Entry: %s" "${input}" >&2
			sleep 1.2
			printf "\r\e[0J" >&2
		} fi
		
		(( valid == 0 )) && continue
		
		gum confirm --no-show-help && confirmed=1; err=$?
		if (( err == 130 )); then {
			printf "\e[2F\e[0J%s\n" "Operation canceled." >&2
			return 130
		} fi
		
		echo "${time_s}"
	} done
}
function convertToMS() {
	local sec="$1"
	echo "scale=0; (${sec} * 1000) / 1" | bc
}

function getTime() {
	local time err
	time="$(gum choose --label-delimiter=":" "${list_lv[@]}")"; err=$?
	if (( err == 130 )); then {
		printf "\e[2F\e[0J%s\n" "Operation canceled." >&2
		return 130
	} fi
	
	if (( time == 0 )); then
		time="$(getCustomTime)"; err=$?
	fi
	echo "${time}"
}

time_s="$(getTime)"
time_ms="$(convertToMS "${time_s}")"

adb shell settings put system screen_off_timeout "${time_ms}"

echo "Updated screen timeout: ${time_s}s"