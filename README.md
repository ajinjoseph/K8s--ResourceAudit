# K8s--ResourceAudit
These Bash scripts audit workload configuration and placement in a given namespace.  They share the same prerequisites:  kubectl configured for the target cluster  jq installed (sudo apt install jq or brew install jq)  Set the namespace once via the NS environment variable before running any script.  
# example – audit the staging namespace first
export NS=nr-entain-test

export NS=nr-entain-test   # staging
export NS=nr-entain        # production

# Audit anti‑affinity policy
bash anti_affinity_policy_audit.sh

# Audit PDB coverage
bash pdb_audit.sh

# Audit real zone distribution
bash zone_distribution_audit.sh
