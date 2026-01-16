# SPDX-License-Identifier: GPL-2.0
#
# Copyright IBM Corp. 2008,2025
#
# Common setup for linux-next scripts
#

# Just in case this gets included twice ...
if [ "$_next_common_included" ]; then
	return 0
fi
_next_common_included=1

bin_dir=$(realpath "$(dirname "$0")")
top_dir=$(realpath '..')

if [ -z "$LOG_FILE" ]; then
	LOG_FILE="$top_dir/merge.log"
fi
# "... appears unused"
# shellcheck disable=SC2034
SHA1_FILE="$top_dir/SHA1s"
CTRL_FILE="$top_dir/etc/control"

build_host="ash"
build_dir="$HOME/next/next"
j_factor=$(nproc)

if [ "$NEXT_BUILD_HOST" ]; then
	build_host="$NEXT_BUILD_HOST"
	if [ "$build_host" = "none" ]; then
		build_host=""
	fi
fi
if [ "$NEXT_BUILD_DIR" ]; then
	build_dir="$NEXT_BUILD_DIR"
fi
if [ "$NEXT_J_FACTOR" ]; then
	j_factor="$NEXT_J_FACTOR"
fi

if [ -z "$_next_common_no_args" ]; then
	if [ -n "$1" ]; then
		build_host="$1"
		shift
	fi
	if [ -n "$1" ]; then
		build_dir="$1"
		shift
	fi
fi

export NEXT_BUILD_HOST="${build_host:-none}"
export NEXT_BUILD_DIR="$build_dir"
export NEXT_J_FACTOR="$j_factor"

# Support functions
_TAB=$(printf '\t')

get_control_field()
{
	# if the field is just '-' print nothing
	awk -F "$_TAB" -v branch="$1" -v field="$2" '/^[^-#]/ && $3==branch { if ($f=="-") print""; else print $field; }' "$CTRL_FILE"
}

get_branches()
{
	awk -F "$_TAB" -v stop="$1" '/^[^-#]/ && $2=="git" { if ($3==stop) { exit 0 }; print $3 }' "$CTRL_FILE"
}

get_pending_branches()
{
	awk -F "$_TAB" '
		BEGIN { show=0 }
		/^#/ { next }
		$2=="switch" { if ($3=="fs-current" || $3=="master" ) show=1
			else if ($3=="fs-next") show=0
			next }
		$2=="branch" && $3=="pending-fixes" { exit }
		$2=="git" && $3=="fs-current" { next }
		$2=="git" { if (show == 1) print $3 }' "$CTRL_FILE"
}

get_contacts()
{
	get_control_field "$1" 1
}

get_type()
{
	get_control_field "$1" 2
}

get_url()
{
	if ! git remote get-url "$1" 2>/dev/null; then
		printf 'linux-next\n'
	fi
}

get_remote_branch()
{
	get_control_field "$1" 5
}

get_build_flag()
{
	get_control_field "$1" 6
}

true
