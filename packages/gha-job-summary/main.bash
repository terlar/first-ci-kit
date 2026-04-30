jobs_data=""
page=1
# Exit cleanly if the summary pipe closes (e.g. on ARC runners with no output).
trap 'exit 0' PIPE
while true; do
	response=$(curl -fsSL \
		-H "Authorization: Bearer ${GH_TOKEN}" \
		-H "Accept: application/vnd.github+json" \
		"${GITHUB_API_URL}/repos/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}/jobs?per_page=100&page=${page}")

	# Extract job fields using awk.
	# The GitHub API returns fields in a consistent order within each job object:
	#   html_url (job-level, contains /job/<id>) -> status -> conclusion -> name -> steps
	# Since name appears before steps and we reset url after emitting each row,
	# step-level name/status/conclusion fields are safely ignored (url is empty then).
	page_jobs=$(printf '%s\n' "$response" | awk '
		BEGIN { url = ""; status_val = ""; conclusion_val = "" }
		/"html_url":/ && /\/job\// {
			val = $0
			gsub(/.*"html_url": "/, "", val)
			gsub(/".*/, "", val)
			url = val
		}
		url != "" && /"status": "/ {
			val = $0
			gsub(/.*"status": "/, "", val)
			gsub(/".*/, "", val)
			status_val = val
		}
		url != "" && /"conclusion": "/ {
			val = $0
			gsub(/.*"conclusion": "/, "", val)
			gsub(/".*/, "", val)
			conclusion_val = val
		}
		url != "" && /"conclusion": null/ {
			conclusion_val = ""
		}
		url != "" && /"name": "/ {
			val = $0
			gsub(/.*"name": "/, "", val)
			gsub(/".*/, "", val)
			eff = (conclusion_val != "" ? conclusion_val : status_val)
			print val "\t" eff "\t" url
			url = ""; status_val = ""; conclusion_val = ""
		}
	')

	jobs_data="${jobs_data}${page_jobs}"$'\n'

	total=$(printf '%s\n' "$response" | awk '/"total_count":/ { val = $0; gsub(/[^0-9]/, "", val); print val + 0 }')
	[ $((page * 100)) -ge "${total:-0}" ] && break
	page=$((page + 1))
done

{
	echo "## Workflow Job Summary"
	echo ""
	echo "| Status | Job |"
	echo "|--------|-----|"

	while IFS=$'\t' read -r name conclusion url; do
		[[ -z "$name" ]] && continue
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
} >>"$GITHUB_STEP_SUMMARY" || exit 0
