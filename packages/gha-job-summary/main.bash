jobs_data=$(gh api \
	"/repos/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}/jobs" \
	--paginate \
	--jq '.jobs[] | [.name, (.conclusion // .status), .html_url] | @tsv')

{
	echo "## Workflow Job Summary"
	echo ""
	echo "| Status | Job |"
	echo "|--------|-----|"

	while IFS=$'\t' read -r name conclusion url; do
		[[ "$conclusion" == "skipped" ]] && continue
		[[ "$name" == "$SUMMARY_JOB_NAME" ]] && continue

		case "$conclusion" in
		success) icon="✅" ;;
		failure) icon="❌" ;;
		cancelled) icon="⚠️" ;;
		in_progress) icon="⏳" ;;
		*) icon="❓" ;;
		esac

		printf '| %s | [%s](%s) |\n' "$icon" "$name" "$url"
	done <<<"$jobs_data"
} >>"$GITHUB_STEP_SUMMARY"
