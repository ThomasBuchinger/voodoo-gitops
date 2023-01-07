#/bin/bash
set -e

kubeonconfig_file="kubeconfig"
BRANCH=${1:-main}

if [ -f "${kubeonconfig_file}"  ]; then
  export KUBECONFIG=${kubeonconfig_file}
else
  echo "no kubeconfig found in current directory"
fi

echo "Switch GitRepository voodoo-gitops to: ${BRANCH}"
kubectl patch gitrepo voodoo-gitops --namespace flux-system --type merge -p "{\"spec\":{\"ref\":{\"branch\": \"${BRANCH}\"}}}"
flux reconcile source git voodoo-gitops
