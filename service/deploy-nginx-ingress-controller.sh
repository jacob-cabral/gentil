#! /bin/bash
# Sai imediatamente se um comando sai com um status não-zero.
set -e

# Importação da função utilitária.
source util/is-helm-chart-installed.sh

# Implantação do controlador de entrada HTTP e HTTPS (Nginx Ingress Controller).
if [ -z "$(isHelmChartInstalled ingress-nginx ingress-nginx)" ]
then
echo "Implantação do controlador de entrada HTTP e HTTPS (Nginx Ingress Controller)."
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
cat << EOF | helm upgrade ingress-nginx ingress-nginx/ingress-nginx --install --create-namespace --namespace=ingress-nginx --version=4.9.0 --values -
controller:
  config:
    allow-snippet-annotations: true
  ingressClassResource:
    default: true
EOF
echo "O Nginx Ingress Controller foi implantado com sucesso."
fi