#! /bin/bash
# Sai imediatamente se um comando sai com um status não-zero.
set -e

# Importação da função utilitária.
source util/is-helm-chart-installed.sh

# Implantação do controlador de entrada HTTP e HTTPS (Nginx Ingress Controller).
if [ -z "$(isHelmChartInstalled ingress-nginx ingress-nginx)" ]
then
echo "Implantação do controlador de entrada HTTP e HTTPS (Nginx Ingress Controller)."

if [ -z "$(helm repo list --output yaml | yq '.[] | select(.name == "ingress-nginx").name')"]
then
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
fi

cat << EOF | helm upgrade ingress-nginx ingress-nginx/ingress-nginx --install --create-namespace --namespace=ingress-nginx --version=4.9.0 --values -
controller:
  config:
    allow-snippet-annotations: true
  ingressClassResource:
    default: true
  service:
    annotations:
      metallb.universe.tf/allow-shared-ip: "key-to-shared-ip"
    loadBalancerIP: $ipBalanceadorCarga
EOF
echo "O Nginx Ingress Controller foi implantado com sucesso."
fi