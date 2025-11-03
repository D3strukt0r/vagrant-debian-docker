#!/bin/bash
set -e -u -o pipefail
IFS=$'\n\t'

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
PROJECT_DIR=$( cd -- "$SCRIPT_DIR/.." &> /dev/null && pwd )

# Load Libs
scriptsCommonUtilities="$SCRIPT_DIR/../lib/bertrand-benoit/scripts-common/utilities.sh"
[[ ! -f "$scriptsCommonUtilities" ]] && echo -e "ERROR: scripts-common utilities not found, you must initialize your git submodule once after you cloned the repository:\ngit submodule init\ngit submodule update" >&2 && exit 1
# shellcheck disable=1090
. "$scriptsCommonUtilities"

[[ -t 1 ]] && SH_PIPED=true || SH_PIPED=false # detect if output is piped
if [[ $SH_PIPED == true ]]; then
  TEXT_RESET=$(tput sgr0)
  TEXT_ERROR=$(tput setaf 160)
  TEXT_INFO=$(tput setaf 2)
  TEXT_WARN=$(tput setaf 214)
  TEXT_BOLD=$(tput bold)
  TEXT_ITALIC=$(tput sitm || true) # not supported on MacOS
  TEXT_UNDERLINE=$(tput smul)
else
  TEXT_RESET=""
  TEXT_ERROR=""
  TEXT_INFO=""
  TEXT_WARN=""
  TEXT_BOLD=""
  TEXT_ITALIC=""
  TEXT_UNDERLINE=""
fi

[[ $(echo -e '\xe2\x82\xac') == '€' ]] && SH_UNICODE=true || SH_UNICODE=false # detect if unicode is supported
if [[ $SH_UNICODE == true ]]; then
  ICON_SUCCESS="✅"
  ICON_FAIL="⛔"
  ICON_ALERT="✴️"
  ICON_WAIT="⏳"
  ICON_INFO="🌼"
  ICON_CONFIG="🌱"
  ICON_CLEAN="🧽"
  ICON_REQUIRE="🔌"
else
  ICON_SUCCESS="OK "
  ICON_FAIL="!! "
  ICON_ALERT="?? "
  ICON_WAIT="..."
  ICON_INFO="(i)"
  ICON_CONFIG="[c]"
  ICON_CLEAN="[c]"
  ICON_REQUIRE="[r]"
fi

usage() {
  echo "CI/CD script for Jenkins to build and upload docker image.

Usage:
  $0 -b <name>
  $0 --branch <name> --push
  $0 --branch <name> --verbose
  $0 -h | --help

Options:
  -h --help                Show this screen.
  -v --verbose             Verbose mode [default: false].
  -b --branch <x>          Branch to clone and build docker image with.
  -p --push --pushregistry Whether to push to Docker Hub (if build succeeded) [default: false].
  -n --builder <x>         Docker builder to use [default: builder-default]."
}

FLAGS_GETOPT_CMD="getopt"
if [[ "$(uname -s)" == "Darwin" ]]; then
  # Overwrite this when running on MacOS
  checkPath "$(brew --prefix gnu-getopt)/bin/getopt" && FLAGS_GETOPT_CMD="$(brew --prefix gnu-getopt)/bin/getopt"
fi
set +e
OPTS=$( $FLAGS_GETOPT_CMD --options hu:t:b:v:p: --longoptions help,verbose,user:,token:,box:,version:,provider: --name "$0" -- "$@" )
if (( $? != 0 )); then errorMessage "${ICON_FAIL}${TEXT_ERROR} Incorrect options provided ... exiting.${TEXT_RESET}"; fi
set -e
eval set -- "$OPTS"

VAGRANT_CLOUD_USER=D3strukt0r
VAGRANT_CLOUD_TOKEN=
VAGRANT_CLOUD_BOX=debian-docker
VAGRANT_CLOUD_VERSION=
VAGRANT_CLOUD_PROVIDER=virtualbox
VAGRANT_CLOUD_FILE=./build/package.box
while true; do
  case "$1" in
    -h | --help )
      usage
      exit 0
      ;;
    --verbose )
      # shellcheck disable=2034
      BSC_VERBOSE=1
      ;;
    -u | --user )
      shift
      VAGRANT_CLOUD_USER=$1
      ;;
    -t | --token )
      shift
      VAGRANT_CLOUD_TOKEN=$1
      ;;
    -b | --box )
      shift
      VAGRANT_CLOUD_BOX=$1
      ;;
    -v | --version )
      shift
      VAGRANT_CLOUD_VERSION=$1
      ;;
    -p | --provider )
      shift
      VAGRANT_CLOUD_PROVIDER=$1
      ;;
    # -- means the end of the arguments; drop this, and break out of the while loop
    -- ) shift; break ;;
    # If invalid options were passed, then getopt should have reported an error,
    # which we checked as VALID_ARGUMENTS when getopt was called...
    * ) writeMessage "${ICON_FAIL}${TEXT_ERROR} Unexpected option: $1 - this should not happen.${TEXT_RESET}"; usage; exit 2 ;;
  esac
  shift
done

# Create a new version
curl \
  --request POST \
  --header "Content-Type: application/json" \
  --header "Authorization: Bearer $VAGRANT_CLOUD_TOKEN" \
  "https://app.vagrantup.com/api/v1/box/$VAGRANT_CLOUD_USER/$VAGRANT_CLOUD_BOX/versions" \
  --data "{ \"version\": { \"version\": \"$VAGRANT_CLOUD_VERSION\" } }"

# Create a new provider
curl \
  --request POST \
  --header "Content-Type: application/json" \
  --header "Authorization: Bearer $VAGRANT_CLOUD_TOKEN" \
  "https://app.vagrantup.com/api/v1/box/$VAGRANT_CLOUD_USER/$VAGRANT_CLOUD_BOX/version/$VAGRANT_CLOUD_VERSION/providers" \
  --data "{ \"provider\": { \"name\": \"$VAGRANT_CLOUD_PROVIDER\" } }"

# Prepare the provider for upload/get an upload URL
response=$(curl \
  --request GET \
  --header "Authorization: Bearer $VAGRANT_CLOUD_TOKEN" \
  "https://app.vagrantup.com/api/v1/box/$VAGRANT_CLOUD_USER/$VAGRANT_CLOUD_BOX/version/$VAGRANT_CLOUD_VERSION/provider/$VAGRANT_CLOUD_PROVIDER/upload")

# Extract the upload URL from the response (requires the jq command)
upload_path=$(echo "$response" | jq --raw-output .upload_path)

# Perform the upload
curl --request PUT "${upload_path}" --upload-file "$VAGRANT_CLOUD_FILE"

# Release the version
curl \
  --request PUT \
  --header "Authorization: Bearer $VAGRANT_CLOUD_TOKEN" \
  "https://app.vagrantup.com/api/v1/box/$VAGRANT_CLOUD_USER/$VAGRANT_CLOUD_BOX/version/$VAGRANT_CLOUD_VERSION/release"
