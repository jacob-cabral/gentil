#! /bin/bash
# Interrompe a execução em caso de erro.
set -e

# Importação da função utilitária isNotNull.
source util/is-not-null.sh

# Definição da função responsável por configurar o hospedeiro como cliente do serviço DNS.
setHostAsDNSClient() {
  dominio="$1"
  ipServidorNomes="$2"

  isNotNull dominio
  isNotNull ipServidorNomes

  configuracaoDNS=/etc/systemd/resolved.conf
  fallbackDNS=$(grep --regexp='^nameserver.\+' /etc/resolv.conf | grep --only-matching --regexp='[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}')

  if [ -z $(grep --regexp=^DNS=$ipServidorNomes$ $configuracaoDNS) ]
  then
    echo "Configuração do hospedeiro como cliente do serviço DNS."
    sudo sed --in-place --expression="s/^#\?\(DNS\)=.*$/\1=$ipServidorNomes/" $configuracaoDNS
    sudo sed --in-place --expression="s/^#\?\(FallbackDNS\)=.*$/\1=$fallbackDNS/" $configuracaoDNS
    sudo sed --in-place --expression="s/^#\?\(Domains\)=.*$/\1=$dominio/" $configuracaoDNS
    sudo systemctl restart systemd-resolved.service
    echo "O hospedeiro foi configurado como cliente do serviço DNS."
  else
    echo "Hospedeiro já configurado como cliente do serviço DNS."
  fi
}