#!/usr/bin/env bash
set -euo pipefail

NS="${NS:-nr-entain}"
printf '%-12s %-40s %-18s %-4s\n' "KIND" "NAME" "ZONES(seen)" "OK?"

# Build a quick lookup of zone labels for each Pod
kubectl get pods -n "$NS" -o json | jq -r '
  .items[] |
  [ (.metadata.ownerReferences[0].kind   // "Pod"),
    (.metadata.ownerReferences[0].name   // .metadata.name),
    (.metadata.labels["topology.kubernetes.io/zone"] // "unknown") ] | @tsv' |
while IFS=$'\t' read -r KIND NAME ZONE; do
  key="$KIND:$NAME"
  ZONES[$key]="${ZONES[$key]},$ZONE"
  COUNTS[$key]="${COUNTS[$key]:-0}+1"
  eval COUNTS[$key]=$((${COUNTS[$key]}+0))
done

# Print aggregated view
for key in "${!ZONES[@]}"; do
  IFS=: read KIND NAME <<<"$key"
  IFS=',' read -ra arr <<<"${ZONES[$key]#,}"
  uniq=$(printf '%s\n' "${arr[@]}" | sort -u | tr '\n' ',' | sed 's/,$//')
  count=$(printf '%s\n' "${arr[@]}" | sort -u | wc -l)
  status=$([[ $count -gt 1 ]] && echo "✅" || echo "❌")
  printf '%-12s %-40s %-18s %-4s\n' "$KIND" "$NAME" "$uniq" "$status"
done | sort | column -t