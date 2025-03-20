#! /bin/bash
# Interrompe a execução em caso de erro.
set -e

# Importação da função utilitária isNotNull.
source util/is-not-null.sh

# Definição da função que valida valores não nulos.
hasPodNotRunning() {
  namespace="$1"
  isNotNull namespace
  echo "$(kubectl --namespace $namespace get pods --output yaml | yq '.items[].status | select(.phase != "Running").phase')"
}