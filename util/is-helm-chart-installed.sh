#! /bin/bash
# Interrompe a execução em caso de erro.
set -e

# Importação da função utilitária isNotNull.
source util/is-not-null.sh

# Definição da função que valida valores não nulos.
isHelmChartInstalled() {
  namespace="$1"
  helmChartName="$2"

  isNotNull namespace
  isNotNull helmChartName

  charts=$(helm list --namespace $namespace --short)
  installed=""

  for installedHelmChartName in ${charts[@]}
  do
    if [ "$helmChartName" == "$installedHelmChartName" ]
    then
      installed=true
      break
    fi
  done

  echo "$installed"
}