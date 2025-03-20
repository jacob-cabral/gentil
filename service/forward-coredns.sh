#! /bin/bash
# Sai imediatamente se um comando sai com um status não-zero.
set -e

# Importação da função utilitária isNotNull.
source util/is-not-null.sh

# Validação dos dados obrigatórios.
isNotNull dominio
isNotNull ipServidorNomes

# Definição do cluster como cliente do serviço DNS.
if [ -z "$(kubectl --namespace kube-system get configmap coredns-custom)" ]
then
echo "Configuração do cluster como cliente do serviço DNS."
cat << EOF | kubectl apply --namespace=kube-system --filename -
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns-custom
data:
  $dominio.server: |
    $dominio:53 {
      errors
      cache 30
      forward . $ipServidorNomes
    }
EOF
echo "Configuração bem-sucedida do cliente do serviço DNS."
else
echo "O cluster já é um cliente do serviço DNS."
fi