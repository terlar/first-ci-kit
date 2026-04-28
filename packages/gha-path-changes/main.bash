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
	# Convert glob pattern to ERE for grep:
	#   /**/   →  /(.*/)?   (zero or more intermediate directories)
	#   /**    →  (/.*)?    (optional slash + anything, at end)
	#   **     →  .*        (any characters including slashes)
	#   *      →  [^/]*     (any characters within a single path component)
	#   .      →  \.        (literal dot)
	regex=$(printf '%s' "$pattern" |
		sed \
			-e 's/\./\\./g' \
			-e 's|/\*\*/|/(.*/)?|g' \
			-e 's|/\*\*|(/.*)?|g' \
			-e 's|\*\*/|(.*/)?|g' \
			-e 's|\*\*|.*|g' \
			-e 's|\*|[^/]*|g')
	if echo "$files" | grep -qE "^(${regex})$"; then
		change_lines+=("\"$group\":true")
	else
		change_lines+=("\"$group\":false")
	fi
done

change_object_body="$(printf '%s\n' "${change_lines[@]}" | paste -sd,)"
echo "changes={$change_object_body}" >>"$GITHUB_OUTPUT"
