#!/bin/bash

NAMESPACE="nr-entain"
echo "🔍 Reporting Deployments in '$NAMESPACE' with NO matching PDB"
echo "=============================================================="

# Collect PDB selectors into a temporary file
kubectl get pdb -n "$NAMESPACE" -o json | jq -r '.items[] | [.metadata.name, (.spec.selector.matchLabels | tojson)] | @tsv' > /tmp/pdb_selectors.tsv

# Loop through Deployments
kubectl get deployment -n "$NAMESPACE" -o json | jq -r '.items[] | [.metadata.name, (.spec.selector.matchLabels | tojson)] | @tsv' | while IFS=$'\t' read -r deploy_name deploy_selector_json; do
  matched="false"

  while IFS=$'\t' read -r pdb_name pdb_selector_json; do
    if [[ "$deploy_selector_json" == "$pdb_selector_json" ]]; then
      matched="true"
      break
    fi
  done < /tmp/pdb_selectors.tsv

  if [[ "$matched" == "false" ]]; then
    echo "❌ Missing PDB for Deployment: $deploy_name"
  fi
done

# Clean up
rm -f /tmp/pdb_selectors.tsv
