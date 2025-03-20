#! /bin/bash
# Sai imediatamente se um comando sai com um status não-zero.
set -e

# Importação da função utilitária.
source util/is-helm-chart-installed.sh

# Implantação do serviço controlador de Sealed Secrets.
if [ -z "$(isHelmChartInstalled kube-system sealed-secrets-controller)" ]
then
  echo "Implantação do serviço controlador de Sealed Secrets."
  
  if [ -z "$(helm repo list --output yaml | yq '.[] | select(.name == "bitnami-labs").name')" ]
  then
    helm repo add bitnami-labs https://bitnami-labs.github.io/sealed-secrets/
  fi

  helm upgrade sealed-secrets-controller bitnami-labs/sealed-secrets --install --namespace=kube-system --version=2.15.0 --timeout=10m0s
  echo "O serviço controlador de Sealed Secrets foi implantado com sucesso."
fi