#! /bin/bash
# Sai imediatamente se um comando sai com um status não-zero.
set -e

# Importações das funções utilitárias.
source util/is-not-null.sh
source util/is-helm-chart-installed.sh

# Validação dos dados obrigatórios.
isNotNull dominio
isNotNull subdominio
isNotNull subdominioComHifenSemPonto

# Implantação do Harbor.
# https://artifacthub.io/packages/helm/harbor/harbor
# https://docs.docker.com/engine/security/certificates/
if [[ -z "$(isHelmChartInstalled harbor harbor)" && "$isHarborEnabled" == "true" ]]
then
echo "Implantação do serviço do Harbor."

if [ -z "$(helm repo list --output yaml | yq '.[] | select(.name == "harbor").name')"]
then
helm repo add harbor https://helm.goharbor.io
fi

cat << EOF | helm upgrade harbor harbor/harbor --install --create-namespace --namespace=harbor --version=1.14.0 --timeout=10m0s --values -
database:
  internal:
    password: Y2hhbmdlaXQK
expose:
  # Set how to expose the service. Set the type as "ingress", "clusterIP", "nodePort" or "loadBalancer"
  # and fill the information in the corresponding section
  type: ingress
  tls:
    # Enable TLS or not.
    # Delete the "ssl-redirect" annotations in "expose.ingress.annotations" when TLS is disabled and "expose.type" is "ingress"
    # Note: if the "expose.type" is "ingress" and TLS is disabled,
    # the port must be included in the command when pulling/pushing images.
    # Refer to https://github.com/goharbor/harbor/issues/5291 for details.
    enabled: true
    # The source of the tls certificate. Set as "auto", "secret"
    # or "none" and fill the information in the corresponding section
    # 1) auto: generate the tls certificate automatically
    # 2) secret: read the tls certificate from the specified secret.
    # The tls certificate can be generated manually or by cert manager
    # 3) none: configure no tls certificate for the ingress. If the default
    # tls certificate is configured in the ingress controller, choose this option
    certSource: secret
    secret:
      secretName: harbor-tls
  ingress:
    hosts:
      core: harbor.${subdominio}.${dominio}
    className: nginx
    annotations:
      # note different ingress controllers may require a different ssl-redirect annotation
      # for Envoy, use ingress.kubernetes.io/force-ssl-redirect: "true" and remove the nginx lines below
      ingress.kubernetes.io/ssl-redirect: "true"
      ingress.kubernetes.io/proxy-body-size: "0"
      nginx.ingress.kubernetes.io/ssl-redirect: "true"
      nginx.ingress.kubernetes.io/proxy-body-size: "0"
      cert-manager.io/cluster-issuer: emissor-ac-$subdominioComHifenSemPonto
externalURL: https://harbor.${subdominio}.${dominio}
harborAdminPassword: password
EOF
echo "O Harbor foi implantado com sucesso."
elif [ "$isHarborEnabled" == "true" ]
then
echo "O Harbor já está implantado."
fi