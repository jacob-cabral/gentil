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

# Implantação do Keycloak.
if [[ -z "$(isHelmChartInstalled idp keycloak)" && "$isKeycloakEnabled" == "true" ]]
then
echo "Implantação do Keycloak."

if [ -z "$(helm repo list --output yaml | yq '.[] | select(.name == "bitnami").name')"]
then
helm repo add bitnami https://charts.bitnami.com/bitnami
fi

cat << EOF | helm upgrade keycloak bitnami/keycloak --install --create-namespace --namespace=idp --version=12.2.0 --values -
auth:
  adminUser: admin
  adminPassword: password
resources:
  limits:
    cpu: "1"
    memory: 1Gi
service:
  type: ClusterIP
ingress:
  enabled: true
  hostname: keycloak.${subdominio}.${dominio}
  tls: true
  annotations:
    cert-manager.io/cluster-issuer: emissor-ac-$subdominioComHifenSemPonto
postgresql:
  enabled: false
externalDatabase:
  host: postgresql.databases.svc
  database: keycloak_db_local
  user: keycloak_user_local
  password: keycloak_pass_local
EOF
echo "O Keycloak foi implantado com sucesso."
elif [ "$isKeycloakEnabled" == "true" ]
then
echo "O Keycloak já está implantado."
fi