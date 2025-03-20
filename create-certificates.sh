#! /bin/bash
# Sai imediatamente se um comando sai com um status não-zero.
set -e

# Importação da função utilitária isNotNull.
source util/is-not-null.sh

# Validação dos dados obrigatórios.
isNotNull dominio
isNotNull subdominio
isNotNull chavePrivadaACRaiz
isNotNull certificadoACRaiz
isNotNull chavePrivadaSubdominio
isNotNull requisicaoAssinaturaCertificadoSubdominio
isNotNull certificadoSubdominio

# Emissão do certificado SSL da AC Raiz, caso não exista.
if [ ! -f "$certificadoACRaiz" ]
then
  isNotNull organizacao
  echo "Emissão do certificado SSL da AC Raiz $organizacao."
  if [ -z "$nomeComumOrganizacao" ]
  then
    nomeComumOrganizacao="AC Raiz $organizacao"
  fi
  openssl genrsa -out "$chavePrivadaACRaiz" 2048
  openssl req -new -x509 -days 365 -key "$chavePrivadaACRaiz" -subj "/C=BR/ST=RJ/L=Rio de Janeiro/O=$organizacao/CN=$nomeComumOrganizacao" -out "$certificadoACRaiz"
  echo "O certificado da $nomeComumOrganizacao foi emitido com sucesso."
fi

# Emissão do certificado SSL da AC do subdomínio, caso não exista.
if [ ! -f "$certificadoSubdominio" ]
then
  isNotNull organizacao
  isNotNull unidadeOrganizacional

  if [ -z "$nomeComumUnidadeOrganizacional" ]
  then
    nomeComumUnidadeOrganizacional="AC $unidadeOrganizacional"
  fi
  echo "Criação da chave privada e emissão do certificado SSL da unidade organizacional."
  openssl req -newkey rsa:2048 -nodes -keyout "$chavePrivadaSubdominio" -subj "/C=BR/ST=RJ/L=Rio de Janeiro/O=$organizacao/OU=$unidadeOrganizacional/CN=$nomeComumUnidadeOrganizacional" -out "$requisicaoAssinaturaCertificadoSubdominio"
  openssl x509 -req -extfile <(printf "subjectKeyIdentifier = hash\nauthorityKeyIdentifier = keyid:always,issuer\nbasicConstraints = critical, CA:true, pathlen:0\nkeyUsage = critical, digitalSignature, cRLSign, keyCertSign\nsubjectAltName=DNS:$subdominio.$dominio,DNS:*.$subdominio.$dominio") -days 365 -CA "$certificadoACRaiz" -CAkey "$chavePrivadaACRaiz" -CAcreateserial -in "$requisicaoAssinaturaCertificadoSubdominio" -out "$certificadoSubdominio"
  echo "A chave privada e o certificado SSL da unidade organizacional, $nomeComumUnidadeOrganizacional, foi emitido com sucesso."
fi