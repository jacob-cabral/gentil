#! /bin/bash
# Interrompe a execução em caso de erro.
set -e

# Importação da função utilitária isNotNull.
source util/is-not-null.sh

# Definição da função que torna o certificado da AC Raiz confiável para o sistema operacional.
setTrustedACCertificate() {
  dominio="$1"
  certificadoACRaiz="$2"

  isNotNull dominio
  isNotNull certificadoACRaiz

  echo "Configuração da confiabilidade do certificado da AC Raiz para o sistema operacional."
  sudo mkdir --parents /usr/local/share/ca-certificates/$dominio
  sudo cp "$certificadoACRaiz" /usr/local/share/ca-certificates/$dominio/
  sudo update-ca-certificates
  echo "Certificado da AC Raiz configurado como confiável para o sistema operacional."
}