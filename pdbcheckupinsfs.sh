#!/bin/bash

NAMESPACE="nr-entain"
echo "🔍 Reporting StatefulSets in '$NAMESPACE' with NO matching PDB"
echo "=============================================================="

# Collect PDB selectors into a temporary file (avoids declare -A compatibility issues)
kubectl get pdb -n "$NAMESPACE" -o json | jq -r '.items[] | [.metadata.name, (.spec.selector.matchLabels | tojson)] | @tsv' > /tmp/pdb_selectors.tsv

# Loop through StatefulSets
kubectl get statefulset -n "$NAMESPACE" -o json | jq -r '.items[] | [.metadata.name, (.spec.selector.matchLabels | tojson)] | @tsv' | while IFS=$'\t' read -r sts_name sts_selector_json; do
  matched="false"

  while IFS=$'\t' read -r pdb_name pdb_selector_json; do
    if [[ "$sts_selector_json" == "$pdb_selector_json" ]]; then
      matched="true"
      break
    fi
  done < /tmp/pdb_selectors.tsv

  if [[ "$matched" == "false" ]]; then
    echo "❌ Missing PDB for StatefulSet: $sts_name"
  fi
done

# Clean up
rm -f /tmp/pdb_selectors.tsv
