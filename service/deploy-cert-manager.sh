#! /bin/bash
# Sai imediatamente se um comando sai com um status não-zero.
set -e

# Importações das funções utilitárias.
source util/is-not-null.sh
source util/is-helm-chart-installed.sh

# Validação dos dados obrigatórios.
isNotNull subdominio
isNotNull certificadoSubdominio
isNotNull chavePrivadaSubdominio
isNotNull subdominioComHifenSemPonto

# Implantação do serviço do cert-manager.
if [ -z "$(isHelmChartInstalled cert-manager cert-manager)" ]
then
echo "Implantação do serviço de emissão de certificados SSL (cert-manager)."

if [ -z "$(helm repo list --output yaml | yq '.[] | select(.name == "jetstack").name')" ]
then
helm repo add jetstack https://charts.jetstack.io
fi

helm upgrade cert-manager jetstack/cert-manager --install --create-namespace --namespace=cert-manager --set=crds.enabled=true
cat << EOF | kubectl apply --namespace=cert-manager --filename -
apiVersion: v1
kind: Secret
metadata:
  name: chaves-ac-$subdominioComHifenSemPonto
type: kubernetes.io/tls
data:
  tls.crt: $(base64 --wrap=0 "$certificadoSubdominio")
  tls.key: $(base64 --wrap=0 "$chavePrivadaSubdominio")
---
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: emissor-ac-$subdominioComHifenSemPonto
  namespace: cert-manager
spec:
  ca:
    secretName: chaves-ac-$subdominioComHifenSemPonto
EOF
echo "O cert-manager foi implantado com sucesso."
else
echo "O cert-manager já está implantado."
fi