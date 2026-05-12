if [[ "${FORCE_RUN_ALL:-}" == "true" ]]; then
	change_lines=()
	for p in $DIFF_PATHS; do
		group="${p%:*}"
		change_lines+=("\"$group\":true")
	done
	change_object_body="$(printf '%s\n' "${change_lines[@]}" | paste -sd,)"
	echo "changes={$change_object_body}" >>"$GITHUB_OUTPUT"
	echo "## All jobs affected (change detection skipped)" >>"$GITHUB_STEP_SUMMARY"
	exit 0
fi

case "$GITHUB_EVENT_NAME" in
push)
	first_commit="$GITHUB_EVENT_BEFORE"
	last_commit="$GITHUB_EVENT_AFTER"
	git fetch origin "$first_commit"
	;;
pull_request)
	first_commit="origin/$GITHUB_BASE_REF"
	last_commit="origin/$GITHUB_HEAD_REF"
	git fetch origin "$GITHUB_BASE_REF" "$GITHUB_HEAD_REF"
	;;
esac

files=$(git diff --name-only --diff-filter=d "${first_commit}" "${last_commit}")
change_lines=()
for p in $DIFF_PATHS; do
	group="${p%:*}"
	pattern="${p##*:}"
	# Convert glob pattern to ERE for grep.
	# Use placeholders for ** patterns first, then convert *, then restore
	# placeholders — this prevents the * in ERE replacements (e.g. .*)
	# from being incorrectly re-converted by the s|\*|[^/]*| step.
	#   /**/   →  /(.*/)?   (zero or more intermediate directories)
	#   /**    →  (/.*)?    (optional slash + anything, at end)
	#   **/    →  (.*/)?    (zero or more leading directories)
	#   **     →  .*        (any characters including slashes)
	#   *      →  [^/]*     (any characters within a single path component)
	#   .      →  \.        (literal dot)
	regex=$(printf '%s' "$pattern" |
		sed \
			-e 's/\./\\./g' \
			-e 's|/\*\*/|__DIRANY__|g' \
			-e 's|/\*\*|__SLASHANY__|g' \
			-e 's|\*\*/|__ANYSLASH__|g' \
			-e 's|\*\*|__ANYANY__|g' \
			-e 's|\*|[^/]*|g' \
			-e 's|__DIRANY__|/(.*/)?|g' \
			-e 's|__SLASHANY__|(/.*)?|g' \
			-e 's|__ANYSLASH__|(.*/)?|g' \
			-e 's|__ANYANY__|.*|g')
	if echo "$files" | grep -qE "^(${regex})$"; then
		change_lines+=("\"$group\":true")
	else
		change_lines+=("\"$group\":false")
	fi
done

change_object_body="$(printf '%s\n' "${change_lines[@]}" | paste -sd,)"
echo "changes={$change_object_body}" >>"$GITHUB_OUTPUT"

affected_jobs=()
for line in "${change_lines[@]}"; do
	if [[ "$line" == *":true"* ]]; then
		affected_jobs+=("${line//\"/}")
		affected_jobs[-1]="${affected_jobs[-1]%:*}"
	fi
done

if [[ ${#affected_jobs[@]} -gt 0 ]]; then
	echo "Affected jobs (${#affected_jobs[@]}):"
	printf '  %s\n' "${affected_jobs[@]}"
	{
		echo "## Affected jobs (${#affected_jobs[@]})"
		printf -- '- %s\n' "${affected_jobs[@]}"
	} >>"$GITHUB_STEP_SUMMARY"
else
	echo "No affected jobs."
	echo "## No affected jobs" >>"$GITHUB_STEP_SUMMARY"
fi
