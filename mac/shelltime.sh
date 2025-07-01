#!/bin/bash
source "$(dirname "$0")/common.sh"

shelltime() {
  echo -e "\n${COLOR_BOLD}${COLOR_LAVENDER}✨ ${COLOR_PINK}Measuring shell startup time...${COLOR_RESET}"
  local n=${1:-20}
  echo -e "   ${COLOR_BLUE}Running $n iterations...${COLOR_RESET}\n"
  
  local width=40 progress_char="${UI_PROGRESS_CHAR}" empty_char="${UI_EMPTY_CHAR}" times=()
  for i in $(seq 1 "$n"); do 
    local percentage=$((i * 100 / n))
    local filled=$(((percentage * width) / 100))
    local empty=$((width - filled))
    printf "\r  ["
    printf "%${filled}s" | tr ' ' "$progress_char"
    printf "%${empty}s" | tr ' ' "$empty_char"
    printf "] %d%%" "$percentage"
    times+=($(/usr/bin/time -p zsh -i -c exit 2>&1 | awk '/real/{print $2}'))
  done
  echo
  
  echo "${times[@]}" | tr ' ' '\n' | awk \
    -v green="$COLOR_GREEN" -v yellow="$COLOR_YELLOW" -v red="$COLOR_RED" \
    -v blue="$COLOR_BLUE" -v pink="$COLOR_PINK" -v lavender="$COLOR_LAVENDER" \
    -v reset="$COLOR_RESET" -v bold="$COLOR_BOLD" -v msg_fast="$MSG_FAST" \
    -v msg_medium="$MSG_MEDIUM" -v msg_slow="$MSG_SLOW" \
  '{
      sum+=$1; if($1>max||NR==1) max=$1
    } END {
      avg=sum/NR;
      printf "\n %s%sResults:%s\n", bold, lavender, reset;
      printf "   %sAverage shell startup time: %s%.3f seconds %s(max %.3fs)%s\n", bold, (avg<0.8?green:(avg<2?yellow:red)), avg, blue, max, reset;
      if(avg<0.8) printf "%s ✓ %s%s\n\n", green, msg_fast, reset;
      else if(avg<2) printf "%s ⚠ %s%s\n\n", yellow, msg_medium, reset;
      else printf "%s ✗ %s%s\n\n", red, msg_slow, reset
    }'
}

shelltime "$@"