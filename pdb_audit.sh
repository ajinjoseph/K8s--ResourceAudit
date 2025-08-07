#!/usr/bin/env bash
set -euo pipefail

NS="${NS:-nr-entain}"
TMP_PDB=$(mktemp)

# Cache PDB selectors
kubectl get pdb -n "$NS" -o json |
  jq -r '.items[] | [.metadata.name, (.spec.selector.matchLabels // {} | tojson)] | @tsv' \
  > "$TMP_PDB"

printf '%-12s %-45s %s\n' "KIND" "NAME" "HAS_PDB"

for KIND in deployment statefulset replicaset; do
  kubectl get "$KIND" -n "$NS" -o json |
    jq -r --arg kind "$KIND" '
      .items[] | [.metadata.name, (.spec.selector.matchLabels // {} | tojson)] | @tsv
    ' | while IFS=$'\t' read -r NAME SEL_JSON; do
        MATCH=false
        while IFS=$'\t' read -r _ PDB_SEL; do
          [[ "$SEL_JSON" == "$PDB_SEL" ]] && { MATCH=true; break; }
        done < "$TMP_PDB"
        printf '%-12s %-45s %s\n' "$KIND" "$NAME" "$MATCH"
      done
done | sort | column -t

rm -f "$TMP_PDB"