#!/bin/bash
set -e

echo "=== Smart Financial Advisor — Destroy ==="
echo ""
echo "WARNING: This will delete ALL resources."
echo ""

read -p "Are you sure? (y/N) " confirm
if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
  echo "Aborted."
  exit 0
fi

terraform destroy -auto-approve

echo ""
echo "=== All resources destroyed ==="
