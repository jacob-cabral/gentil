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

if [[ -z "$(isHelmChartInstalled monitoring loki-stack)" && "$isLokiStackEnabled" == "true" ]]
then
echo "Implantação dos serviços de monitoramento do cluster."
helm repo add grafana https://grafana.github.io/helm-charts
cat << EOF | helm upgrade loki-stack grafana/loki-stack --install --create-namespace --namespace=monitoring --values -
grafana:
  enabled: true
  ingress:
    annotations:
      cert-manager.io/cluster-issuer: emissor-ac-$subdominioComHifenSemPonto
    enabled: true
    hosts:
    - grafana.${subdominio}.${dominio}
    path: /
    pathType: Prefix
    tls:
    - hosts:
      - grafana.$subdominio.$dominio
      secretName: grafana-tls-secret
prometheus:
  enabled: true
EOF
echo "Os serviços de monitoramento do cluster foram implantados com sucesso."
elif [ "$isLokiStackEnabled" == "true" ]
then
echo "Os serviços de monitoramento do cluster já estão implantados."
fi
# TODO: Importar os painéis para o Grafana.
# https://grafana.com/grafana/dashboards/12019-loki-dashboard-quick-search/
# https://grafana.com/grafana/dashboards/11594-detailed-pods-resources/
# FIXME: remover parâmetros adicionais da consulta das métricas do CPU:
# ,container_name!=\"POD\",container_name!=\"\",container!=\"monitoring-daemon\"
# https://grafana.com/grafana/dashboards/1860
# https://grafana.com/grafana/dashboards/13639-logs-app/