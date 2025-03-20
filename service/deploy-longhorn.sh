#! /bin/bash
# Sai imediatamente se um comando sai com um status não-zero.
set -e

# Importações das funções utilitárias.
source util/is-not-null.sh
source util/is-helm-chart-installed.sh

# Validação dos dados obrigatórios.
isNotNull dominio
isNotNull subdominio

# Implantação do Longhorn.
if [[ -z "$(isHelmChartInstalled longhorn longhorn)" && "$isLonghornEnabled" == "true" ]]
then
echo "Implantação do Longhorn."
cat << EOF | helm upgrade longhorn longhorn/longhorn --install --create-namespace --namespace longhorn-system --values -
ingress:
  enabled: true
  tls: true
  host: longhorn.${subdominio}.${dominio}
EOF
echo "O Longhorn foi implantado com sucesso."
elif [ "$isLonghornEnabled" == "true" ]
then
echo "O Longhorn já está implantado."
fi