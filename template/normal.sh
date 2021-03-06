#!/usr/bin/env bash
### ==============================================================================
### SO HOW DO YOU PROCEED WITH YOUR SCRIPT?
### 1. define the options/parameters and defaults you need in list_options()
### 2. implement the different actions in main() with helper functions
### 3. implement helper functions you defined in previous step
### 4. add binaries your script needs (e.g. ffmpeg, jq) to require_binaries
### ==============================================================================

### Created by author_name ( author_username ) on meta_thisday
script_version="1.1.1" # if there is a VERSION.md in this script's folder, it will take priority for version number
readonly script_author="author@email.com"
readonly script_created="meta_thisday"
readonly run_as_root=-1 # run_as_root: 0 = don't check anything / 1 = script MUST run as root / -1 = script MAY NOT run as root

list_options() {
  ### Change the next lines to reflect which flags/options/parameters you need
  ### flag:   switch a flag 'on' / no extra parameter
  ###     flag|<short>|<long>|<description>
  ###     e.g. "-v" or "--verbose" for verbose output / default is always 'off'
  ### option: set an option value / 1 extra parameter
  ###     option|<short>|<long>|<description>|<default>
  ###     e.g. "-e <extension>" or "--extension <extension>" for a file extension
  ### param:  comes after the options
  ###     param|<type>|<long>|<description>
  ###     <type> = 1 for single parameters - e.g. param|1|output expects 1 parameter <output>
  ###     <type> = ? for optional parameters - e.g. param|1|output expects 1 parameter <output>
  ###     <type> = n for list parameter    - e.g. param|n|inputs expects <input1> <input2> ... <input99>
  echo -n "
#commented lines will be filtered
flag|h|help|show usage
flag|q|quiet|no output
flag|v|verbose|output more
flag|f|force|do not ask for confirmation (always yes)
option|l|log_dir|folder for log files |$HOME/log/$script_prefix
option|t|tmp_dir|folder for temp files|.tmp
option|w|width|width to use|800
param|1|action|action to perform: analyze/convert
param|?|input|input file
param|?|output|output file
" |
    grep -v '^#' |
    sort
}

list_dependencies() {
  ### Change the next lines to reflect which binaries(programs) or scripts are necessary to run this script
  # Example 1: a regular package that should be installed with apt/brew/yum/...
  #curl
  # Example 2: a program that should be installed with apt/brew/yum/... through a package with a different name
  #convert|imagemagick
  # Example 3: a package with its own package manager: basher (shell), go get (golang), cargo (Rust)...
  #progressbar|basher install pforret/progressbar
  echo -n "
awk
" | grep -v "^#"
}

#####################################################################
## Put your main script here
#####################################################################

main() {
  log "Program: $script_basename $script_version"
  log "Created: $script_created"
  log "Updated: $script_modified"
  log "Run as : $USER@$HOSTNAME"

  require_binaries
  log_to_file "[$script_basename] $script_version started"
  time_started=$(date '+%s')

  action=$(lower_case "$action")
  case $action in
  check)
    #TIP: use «$script_prefix check» to check if this script is ready to execute (all necessary binaries/scripts exist)
    #TIP:> $script_prefix check
    echo -n "$char_succ Dependencies: "
    list_dependencies | cut -d'|' -f1 | sort | xargs
    ;;

  analyze)
    #TIP: use «$script_prefix analyze» to analyze an input file
    #TIP:> $script_prefix analyze input.txt
    # shellcheck disable=SC2154
    do_analyze "$input"
    ;;

  convert)
    #TIP: use «$script_prefix convert» to convert input into output
    #TIP:> $script_prefix convert input.txt output.pdf
    do_convert "$input" "$output"
    ;;

  *)
    die "action [$action] not recognized"
    ;;
  esac
  time_ended=$(date '+%s')
  time_elapsed=$((time_ended - time_started))
  log_to_file "[$script_basename] ended after $time_elapsed secs"
  #TIP: >>> bash script created with «pforret/bashew»
  #TIP: >>> for developers, also check «pforret/setver»
}

#####################################################################
## Put your helper scripts here
#####################################################################

do_analyze() {
  log_to_file "Analyze [$input]"
  # < "$1"  do_analysis_stuff
}

do_convert() {
  log_to_file "Convert [$input] -> [$output]"
  # < "$1"  do_conversion_stuff > "$2"
}

#####################################################################
################### DO NOT MODIFY BELOW THIS LINE ###################

# set strict mode -  via http://redsymbol.net/articles/unofficial-bash-strict-mode/
# removed -e because it made basic [[ testing ]] difficult
set -uo pipefail
IFS=$'\n\t'
# shellcheck disable=SC2120
hash() {
  length=${1:-6}
  # shellcheck disable=SC2230
  if [[ -n $(which md5sum) ]]; then
    # regular linux
    md5sum | cut -c1-"$length"
  else
    # macos
    md5 | cut -c1-"$length"
  fi
}

force=0
help=0

## ----------- TERMINAL OUTPUT STUFF

verbose=0
#to enable verbose even before option parsing
[[ $# -gt 0 ]] && [[ $1 == "-v" ]] && verbose=1
quiet=0
#to enable quiet even before option parsing
[[ $# -gt 0 ]] && [[ $1 == "-q" ]] && quiet=1

[[ -t 1 ]] && piped=0 || piped=1 # detect if output is piped
if [[ $piped -eq 0 ]]; then
  col_reset="\033[0m"
  col_red="\033[1;31m"
  col_grn="\033[1;32m"
  col_ylw="\033[1;33m"
else
  col_reset=""
  col_red=""
  col_grn=""
  col_ylw=""
fi

[[ $(echo -e '\xe2\x82\xac') == '€' ]] && unicode=1 || unicode=0 # detect if unicode is supported
if [[ $unicode -gt 0 ]]; then
  char_succ="✔"
  char_fail="✖"
  char_alrt="➨"
  char_wait="…"
else
  char_succ="OK "
  char_fail="!! "
  char_alrt="?? "
  char_wait="..."
fi

readonly nbcols=$(tput cols 2>/dev/null || echo 80)
#readonly nbrows=$(tput lines)
readonly wprogress=$((nbcols - 5))

out() { ((quiet)) || printf '%b\n' "$*"; }

progress() {
  ((quiet)) || (
    if is_set ${piped:-0}; then
      out "$*" >&2
    else
      printf "... %-${wprogress}b\r" "$*                                             " >&2
    fi
  )
}

die() {
  tput bel
  out "${col_red}${char_fail} $script_basename${col_reset}: $*" >&2
  safe_exit
  #exit 1
}

alert() { out "${col_red}${char_alrt}${col_reset}: $*" >&2; } # print error and continue

success() { out "${col_grn}${char_succ}${col_reset}  $*"; }

announce() {
  out "${col_grn}${char_wait}${col_reset}  $*"
  sleep 1
}

log() { ((verbose)) && out "${col_ylw}# $* ${col_reset}" >&2; }

log_to_file() {
  echo "$(date '+%H:%M:%S') | $*" >>"$log_file"
}

lower_case() { echo "$*" | awk '{print tolower($0)}'; }
upper_case() { echo "$*" | awk '{print toupper($0)}'; }

slugify() {
  # shellcheck disable=SC2020
  lower_case "$*" |
    tr \
      'àáâäæãåāçćčèéêëēėęîïííīįìłñńôöòóœøōõßśšûüùúūÿžźż' \
      'aaaaaaaaccceeeeeeeiiiiiiilnnoooooooosssuuuuuyzzz' |
    awk '{
    gsub(/[^0-9a-z ]/,"");
    gsub(/^\s+/,"");
    gsub(/^s+$/,"");
    gsub(" ","-");
    print;
    }' |
    cut -c1-50
}

confirm() {
  is_set $force && return 0
  read -r -p "$1 [y/N] " -n 1
  echo " "
  [[ $REPLY =~ ^[Yy]$ ]]
}

ask() {
  # $1 = variable name
  # $2 = question
  # $3 = default value
  # not using read -i because that doesn't work on MacOS
  local ANSWER
  read -r -p "$2 ($3) > " ANSWER
  if [[ -z "$ANSWER" ]]; then
    eval "$1=\"$3\""
  else
    eval "$1=\"$ANSWER\""
  fi
}

error_prefix="${col_red}>${col_reset}"
trap "die \"ERROR \$? after \$SECONDS seconds \n\
\${error_prefix} last command : '\$BASH_COMMAND' \" \
\$(< \$script_install_path awk -v lineno=\$LINENO \
'NR == lineno {print \"\${error_prefix} from line \" lineno \" : \" \$0}')" INT TERM EXIT
# cf https://askubuntu.com/questions/513932/what-is-the-bash-command-variable-good-for
# trap 'echo ‘$BASH_COMMAND’ failed with error code $?' ERR
safe_exit() {
  log "Start exit sequence"
  [[ -n "${tmp_file:-}" ]] && [[ -f "$tmp_file" ]] && rm "$tmp_file"
  trap - INT TERM EXIT
  log "$script_basename finished after $SECONDS seconds"
  log "Exit now"
  exit
}

is_set() { [[ "$1" -gt 0 ]]; }
is_empty() { [[ -z "$1" ]]; }
is_not_empty() { [[ -n "$1" ]]; }

is_file() { [[ -f "$1" ]]; }
is_dir() { [[ -d "$1" ]]; }

show_usage() {
  out "Program: ${col_grn}$script_basename $script_version${col_reset} by ${col_ylw}$script_author${col_reset}"
  out "Updated: ${col_grn}$script_modified${col_reset}"

  echo -n "Usage: $script_basename"
  list_options |
    awk '
  BEGIN { FS="|"; OFS=" "; oneline="" ; fulltext="Flags, options and parameters:"}
  $1 ~ /flag/  {
    fulltext = fulltext sprintf("\n    -%1s|--%-12s: [flag] %s [default: off]",$2,$3,$4) ;
    oneline  = oneline " [-" $2 "]"
    }
  $1 ~ /option/  {
    fulltext = fulltext sprintf("\n    -%1s|--%-12s: [option] %s",$2,$3 " <?>",$4) ;
    if($5!=""){fulltext = fulltext "  [default: " $5 "]"; }
    oneline  = oneline " [-" $2 " <" $3 ">]"
    }
  $1 ~ /secret/  {
    fulltext = fulltext sprintf("\n    -%1s|--%s <%s>: [secr] %s",$2,$3,"?",$4) ;
      oneline  = oneline " [-" $2 " <" $3 ">]"
    }
  $1 ~ /param/ {
    if($2 == "1"){
          fulltext = fulltext sprintf("\n    %-17s: [parameter] %s","<"$3">",$4);
          oneline  = oneline " <" $3 ">"
     }
     if($2 == "?"){
          fulltext = fulltext sprintf("\n    %-17s: [parameter] %s (optional)","<"$3">",$4);
          oneline  = oneline " <" $3 "?>"
     }
     if($2 == "n"){
          fulltext = fulltext sprintf("\n    %-17s: [parameters] %s (1 or more)","<"$3">",$4);
          oneline  = oneline " <" $3 " …>"
     }
    }
    END {print oneline; print fulltext}
  '
}

show_tips() {
  grep <"${BASH_SOURCE[0]}" -v "\$0" |
    awk "
  /TIP: / {\$1=\"\"; gsub(/«/,\"$col_grn\"); gsub(/»/,\"$col_reset\"); print \"*\" \$0}
  /TIP:> / {\$1=\"\"; print \" $col_ylw\" \$0 \"$col_reset\"}
  " |
    awk \
      -v script_basename="$script_basename" \
      -v script_prefix="$script_prefix" \
      '{
    gsub(/\$script_basename/,script_basename);
    gsub(/\$script_prefix/,script_prefix);
    print ;
    }'
}

init_options() {
  local init_command
  init_command=$(list_options |
    awk '
    BEGIN { FS="|"; OFS=" ";}
    $1 ~ /flag/   && $5 == "" {print $3 "=0; "}
    $1 ~ /flag/   && $5 != "" {print $3 "=\"" $5 "\"; "}
    $1 ~ /option/ && $5 == "" {print $3 "=\"\"; "}
    $1 ~ /option/ && $5 != "" {print $3 "=\"" $5 "\"; "}
    ')
  if [[ -n "$init_command" ]]; then
    eval "$init_command"
  fi
}

require_binaries() {
  os_name=$(uname -s)
  os_version=$(uname -prm)
  log "Running: $os_name ($os_version)"
  [[ -n "${ZSH_VERSION:-}" ]] && log "Running: zsh $ZSH_VERSION"
  [[ -n "${BASH_VERSION:-}" ]] && log "Running: bash $BASH_VERSION"
  local required_binary
  local install_instructions

    while read -r line; do
      required_binary=$(echo "$line" | cut -d'|' -f1)
      [[ -z "$required_binary" ]] && continue
      # shellcheck disable=SC2230
      log "Check for existence of [$required_binary]"
      [[ -n $(which "$required_binary") ]] && continue
      required_package=$(echo "$line" | cut -d'|' -f2)
      if [[ $(echo $required_package | wc -w) -gt 1 ]] ; then
        # example: setver|basher install setver
        install_instructions="$required_package"
      else
        [[ -z "$required_package" ]] && required_package="$required_binary"
        if [[ -n "$install_package" ]] ; then
          install_instructions="$install_package $required_package"
        else
          install_instructions="(install $required_package with your package manager)"
        fi
      fi
      alert "$script_basename needs [$required_binary] but it cannot be found"
      alert "1) install package  : $install_instructions"
      alert "2) check path       : export PATH=\"[path of your binary]:\$PATH\""
      die "Missing program/script [$required_binary]"
    done < <(list_dependencies)
}

folder_prep() {
  if [[ -n "$1" ]]; then
    local folder="$1"
    local max_days=${2:-365}
    if [[ ! -d "$folder" ]]; then
      log "Create folder : [$folder]"
      mkdir -p "$folder"
    else
      log "Cleanup folder: [$folder] - delete files older than $max_days day(s)"
      find "$folder" -mtime "+$max_days" -type f -exec rm {} \;
    fi
  fi
}

expects_single_params() {
  list_options | grep 'param|1|' >/dev/null
}
expects_optional_params() {
  list_options | grep 'param|?|' >/dev/null
}
expects_multi_param() {
  list_options | grep 'param|n|' >/dev/null
}

count_words() {
  wc -w |
    awk '{ gsub(/ /,""); print}'
}

parse_options() {
  if [[ $# -eq 0 ]]; then
    show_usage >&2
    safe_exit
  fi

  ## first process all the -x --xxxx flags and options
  while true; do
    # flag <flag> is saved as $flag = 0/1
    # option <option> is saved as $option
    if [[ $# -eq 0 ]]; then
      ## all parameters processed
      break
    fi
    if [[ ! $1 == -?* ]]; then
      ## all flags/options processed
      break
    fi
    local save_option
    save_option=$(list_options |
      awk -v opt="$1" '
        BEGIN { FS="|"; OFS=" ";}
        $1 ~ /flag/   &&  "-"$2 == opt {print $3"=1"}
        $1 ~ /flag/   && "--"$3 == opt {print $3"=1"}
        $1 ~ /option/ &&  "-"$2 == opt {print $3"=$2; shift"}
        $1 ~ /option/ && "--"$3 == opt {print $3"=$2; shift"}
        $1 ~ /secret/ &&  "-"$2 == opt {print $3"=$2; shift"}
        $1 ~ /secret/ && "--"$3 == opt {print $3"=$2; shift"}
        ')
    if [[ -n "$save_option" ]]; then
      if echo "$save_option" | grep shift >>/dev/null; then
        local save_var
        save_var=$(echo "$save_option" | cut -d= -f1)
        log "Found  : ${save_var}=$2"
      else
        log "Found  : $save_option"
      fi
      eval "$save_option"
    else
      die "cannot interpret option [$1]"
    fi
    shift
  done

  ((help)) && (
    echo "### USAGE"
    show_usage
    echo ""
    echo "### TIPS & EXAMPLES"
    show_tips
    safe_exit
  )

  ## then run through the given parameters
  if expects_single_params; then
    single_params=$(list_options | grep 'param|1|' | cut -d'|' -f3)
    list_singles=$(echo "$single_params" | xargs)
    single_count=$(echo "$single_params" | count_words)
    log "Expect : $single_count single parameter(s): $list_singles"
    [[ $# -eq 0 ]] && die "need the parameter(s) [$list_singles]"

    for param in $single_params; do
      [[ $# -eq 0 ]] && die "need parameter [$param]"
      [[ -z "$1" ]] && die "need parameter [$param]"
      log "Assign : $param=$1"
      eval "$param=\"$1\""
      shift
    done
  else
    log "No single params to process"
    single_params=""
    single_count=0
  fi

  if expects_optional_params; then
    optional_params=$(list_options | grep 'param|?|' | cut -d'|' -f3)
    optional_count=$(echo "$optional_params" | count_words)
    log "Expect : $optional_count optional parameter(s): $(echo "$optional_params" | xargs)"

    for param in $optional_params; do
      log "Assign : $param=${1:-}"
      eval "$param=\"${1:-}\""
      shift
    done
  else
    log "No optional params to process"
    optional_params=""
    optional_count=0
  fi

  if expects_multi_param; then
    #log "Process: multi param"
    multi_count=$(list_options | grep -c 'param|n|')
    multi_param=$(list_options | grep 'param|n|' | cut -d'|' -f3)
    log "Expect : $multi_count multi parameter: $multi_param"
    ((multi_count > 1)) && die "cannot have >1 'multi' parameter: [$multi_param]"
    ((multi_count > 0)) && [[ $# -eq 0 ]] && die "need the (multi) parameter [$multi_param]"
    # save the rest of the params in the multi param
    if [[ -n "$*" ]]; then
      log "Assign : $multi_param=$*"
      eval "$multi_param=( $* )"
    fi
  else
    multi_count=0
    multi_param=""
    [[ $# -gt 0 ]] && die "cannot interpret extra parameters"
  fi
}

get_from_env(){
  # $1 = variable name
  # $2 = input file (if any)
  if [[ -n ${2:-} ]] ; then
    [[ ! -f "$2" ]] && die "Cannot find env file [$2]"
    < "$2" grep -E "^$1="
  else
    grep -E "^$1="
  fi \
  | cut -d'=' -f2- \
  | sed -e 's/^"//' -e 's/"$//'
}

lookup_script_data() {
  readonly script_prefix=$(basename "${BASH_SOURCE[0]}" .sh)
  readonly script_basename=$(basename "${BASH_SOURCE[0]}")
  readonly execution_day=$(date "+%Y-%m-%d")

  # cf https://stackoverflow.com/questions/59895/how-to-get-the-source-directory-of-a-bash-script-from-within-the-script-itself
  # get installation folder of this script, resolving symlinks if necessary
  script_install_path="${BASH_SOURCE[0]}"
  log "Script path: $script_install_path"
  script_install_folder="$(cd -P "$(dirname "$script_install_path")" >/dev/null 2>&1 && pwd)"
  while [ -h "$script_install_path" ]; do
    # resolve symbolic links
    script_install_path="$(readlink "$script_install_path")"
   log "Linked to: $script_install_path"
   script_install_folder="$(cd -P "$(dirname "$script_install_path")" >/dev/null 2>&1 && pwd)"
    [[ "$script_install_path" != /* ]] && script_install_path="$script_install_folder/$script_install_path"
  done

  # get shell/operating system/versions
  shell_brand="sh"
  shell_version="?"
  [[ -n "${ZSH_VERSION:-}" ]]  && shell_brand="zsh"  && shell_version="$ZSH_VERSION"
  [[ -n "${BASH_VERSION:-}" ]] && shell_brand="bash" && shell_version="$BASH_VERSION"
  [[ -n "${FISH_VERSION:-}" ]] && shell_brand="fish" && shell_version="$FISH_VERSION"
  [[ -n "${KSH_VERSION:-}" ]]  && shell_brand="ksh"  && shell_version="$KSH_VERSION"
  log "Detected shell: $shell_brand - version $shell_version"

  readonly os_kernel=$(uname -s)
  os_version=$(uname -r)
  os_machine=$(uname -m)
  install_package=""
  case "$os_kernel" in
  CYGWIN*|MSYS*|MINGW*)
    os_name="Windows"
    ;;
  Darwin)
    os_name=$(sw_vers -productName) # macOS
    os_version=$(sw_vers -productVersion) # 11.1
    install_package="brew install"
    ;;
  Linux|GNU*)
    if [[ $(which lsb_release) ]] ; then
      # 'normal' Linux distributions
      os_name=$(lsb_release -i) # Ubuntu
      os_version=$(lsb_release -r) # 20.04
    else
      # Synology, QNAP,
      os_name="Linux"
    fi
    [[ -x /bin/apt-cyg ]]       && install_package="apt-cyg install" # Cygwin
    [[ -x /bin/dpkg ]]          && install_package="dpkg -i"      # Synology
    [[ -x /opt/bin/ipkg ]]      && install_package="ipkg install" # Synology
    [[ -x /usr/sbin/pkg ]]      && install_package="pkg install"  # BSD
    [[ -x /usr/bin/pacman ]]    && install_package="pacman -S"    # Arch Linux
    [[ -x /usr/bin/zypper ]]    && install_package="zypper install" # Suse Linux
    [[ -x /usr/bin/emerge ]]    && install_package="emerge"       # Gentoo
    [[ -x /usr/bin/yum ]]       && install_package="yum install"  # RedHat RHEL/CentOS/Fedora
    [[ -x /usr/bin/apk ]]       && install_package="apk add"      # Alpine
    [[ -x /usr/bin/apt-get ]]   && install_package="apt-get install"  # Debian
    [[ -x /usr/bin/apt ]]       && install_package="apt install"  # Ubuntu
  esac
  log "System    : $os_name ($os_kernel) $os_version on $os_machine"
  log "Installer : $install_package"


  # get last modified date of this script
  script_modified="??"
  [[ "$os_name" == "Linux" ]] && script_modified=$(stat -c %y "$script_install_path" 2>/dev/null | cut -c1-16) # generic linux
  [[ "$os_name" == "Darwin" ]] && script_modified=$(stat -f "%Sm" "$script_install_path" 2>/dev/null)          # for MacOS

  log "Executing : [$script_install_path]"
  log "In folder : [$script_install_folder]"

  # get script version from VERSION.md file - which is automatically updated by pforret/setver
  [[ -f "$script_install_folder/VERSION.md" ]] && script_version=$(cat "$script_install_folder/VERSION.md")

  # if run inside a git repo, detect for which remote repo it is
  if git status >/dev/null 2>&1; then
    readonly in_git_repo=1
    readonly git_repo_remote=$(git remote -v | awk '/(fetch)/ {print $2}')
    log "git remote: $git_repo_remote"
    readonly git_repo_root=$(git rev-parse --show-toplevel)
    log "git local : $git_repo_root"
  else
    readonly in_git_repo=0
    readonly git_repo_root=""
    readonly git_repo_remote=""
  fi

}

prep_log_and_temp_dir() {
  tmp_file=""
  log_file=""
  # shellcheck disable=SC2154
  if is_not_empty "$tmp_dir"; then
    folder_prep "$tmp_dir" 1
    tmp_file=$(mktemp "$tmp_dir/$execution_day.XXXXXX")
    log "tmp_file: $tmp_file"
    # you can use this temporary file in your program
    # it will be deleted automatically if the program ends without problems
  fi
  # shellcheck disable=SC2154
  if [[ -n "$log_dir" ]]; then
    folder_prep "$log_dir" 7
    log_file=$log_dir/$script_prefix.$execution_day.log
    log "log_file: $log_file"
  fi
}

import_env_if_any() {
  if [[ -f "$script_install_folder/.env" ]]; then
    log "Read config from [$script_install_folder/.env]"
    # shellcheck disable=SC1090
    source "$script_install_folder/.env"
  fi
  if [[ -f "./.env" ]]; then
    log "Read config from [./.env]"
    # shellcheck disable=SC1090
    source "./.env"
  fi
}

[[ $run_as_root == 1 ]] && [[ $UID -ne 0 ]] && die "user is $USER, MUST be root to run [$script_basename]"
[[ $run_as_root == -1 ]] && [[ $UID -eq 0 ]] && die "user is $USER, CANNOT be root to run [$script_basename]"

lookup_script_data

# set default values for flags & options
init_options

# overwrite with .env if any
import_env_if_any

# overwrite with specified options if any
parse_options "$@"

# clean up log and temp folder
prep_log_and_temp_dir

# run main program
main

# exit and clean up
safe_exit
