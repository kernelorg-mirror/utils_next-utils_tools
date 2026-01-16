# SPDX-License-Identifier: GPL-2.0
#
# Copyright IBM Corp. 2008,2025
#
# shared check_dups funcion
#
# This file assumes that common.sh has been included first so that
# top_dir and bin_dir are defined
#

check_dups()
{
	# "In POSIX sh, 'local' is undefined."
	# shellcheck disable=SC3043
	local name base sha dfile o ol oh

	name="$1"
	base="$2"
	sha="$3"
	if [ "$base" = "HEAD" ]; then
		dfile="$top_dir/duplicates/next/$name"
	else
		dfile="$top_dir/duplicates/linus/$name"
	fi

	# if there is anything in this tree, then check for duplicates
	if [ "$(git rev-list --count --no-merges "$base".."$sha")" -eq 0 ]; then
		rm -f "$dfile"
		return;
	fi

	dups=$(git cherry "$base" "$sha" | sed -n 's/^- //p' |
		xargs -r -n 1 "$bin_dir"/clog | sort)

	if [ -n "$dups" ]; then
		for o in $(get_branches "$name"); do
			ol="$top_dir/duplicates/linus/$o"
			if [ -f "$ol" ]; then
				dups=$(printf '%s\n' "$dups" | comm -23 - "$ol")
			fi
			if [ -z "$dups" ]; then
				break
			fi
			if ! [ "$base" = "HEAD" ]; then
				continue
			fi
			ol="$top_dir/duplicates/linus/$name"
			if [ -f "$ol" ]; then
				dups=$(printf '%s\n' "$dups" | comm -23 - "$ol")
			fi
			if [ -z "$dups" ]; then
				break
			fi
			oh="$top_dir/duplicates/next/$o"
			if [ -f "$oh" ]; then
				dups=$(printf '%s\n' "$dups" | comm -23 - "$oh")
			fi
			if [ -z "$dups" ]; then
				break
			fi
		done
	fi
	if [ -z "$dups" ]; then
		rm -f "$dfile"
	elif ! [ -f "$dfile" ]; then
		printf '%s\n' "$dups" | tee "$dfile"
	elif ! printf '%s\n' "$dups" | cmp -s - "$dfile"; then
		printf '%s\n' "$dups" | comm -23 - "$dfile"
		printf '%s\n' "$dups" >"$dfile"
	fi
}

true
