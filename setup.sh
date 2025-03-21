#! /bin/bash
# Interrompe a execução em caso de erro.
set -e

# Definição do diretório raiz das configurações.
diretorioRaiz=$(dirname "$(realpath "$0")")
cd "${diretorioRaiz}"

# Importação de funções utilitárias.
source util/is-not-null.sh
source util/set-host-as-dns-client.sh
source util/set-trusted-ac-certificate.sh

# Validação dos dados de entrada obrigatórios.
isNotNull dominio
isNotNull subdominio

# Criação da rede do cluster, se for o caso.
identificadorRede="$(docker network ls --format=json | jq --raw-output 'select(.Name == "kind").ID')"

if [ -z "$identificadorRede" ]
then
  identificadorRede="$(docker network create kind | cut --characters=1-12)"
fi

# Definição de variáveis.
subdominioComHifenSemPonto=$(echo -n $subdominio | sed --expression 's/\./\-/g')
ifname="br-$identificadorRede"
gateway=$(ip -json address show $ifname | jq --raw-output 'limit(1; .[].addr_info[] | select(.family == "inet") | .local)')
prefixoRede=$(ip -json address show $ifname | jq --raw-output 'limit(1; .[].addr_info[] | select(.family == "inet") | .prefixlen)')
ipBalanceadorCarga=$(echo $gateway | sed --expression='s/^\(.\+\)\(\.[0-9]\{1,3\}\)\(\.[0-9]\{1,3\}\)$/\1.100\3/g')
cidrBalanceadorCarga=$ipBalanceadorCarga/32
[ -z "$ipServidorNomes" ] && ipServidorNomes="$ipBalanceadorCarga"
[ -z "$diretorioCertificados" ] && diretorioCertificados="${OLDPWD:-.}"
[ -z "$chavePrivadaACRaiz" ] && chavePrivadaACRaiz="$diretorioCertificados/ac.$dominio.key"
[ -z "$certificadoACRaiz" ] && certificadoACRaiz="$diretorioCertificados/ac.$dominio.crt"
[ -z "$chavePrivadaSubdominio" ] && chavePrivadaSubdominio="$diretorioCertificados/$subdominio.$dominio.key"
[ -z "$requisicaoAssinaturaCertificadoSubdominio" ] && requisicaoAssinaturaCertificadoSubdominio="$diretorioCertificados/$subdominio.$dominio.csr"
[ -z "$certificadoSubdominio" ] && certificadoSubdominio="$diretorioCertificados/$subdominio.$dominio.crt"

# Emissão dos certificados SSL, se for o caso.
if [[ ! -f "$certificadoACRaiz" || ! -f "$certificadoSubdominio" ]]
then
  diretorioCertificados="$diretorioCertificados" chavePrivadaACRaiz="$chavePrivadaACRaiz" certificadoACRaiz="$certificadoACRaiz" chavePrivadaSubdominio="$chavePrivadaSubdominio" certificadoSubdominio="$certificadoSubdominio" requisicaoAssinaturaCertificadoSubdominio="$requisicaoAssinaturaCertificadoSubdominio" ./create-certificates.sh
else
  echo "Os certificados das AC já existem."
fi

# Implantação do cluster Kubernetes.
clusters=$(kind get clusters)
isClusterCreated=""

if test -n "$clusters"
then
  for cluster in ${clusters[@]}
  do
    if test "$subdominio" == "$cluster"
    then
      isClusterCreated=true
      break
    fi
  done
fi

if test -z "$isClusterCreated"
then
  echo "Criação do cluster $subdominio."
  certificadoACRaiz=$certificadoACRaiz subdominioComHifenSemPonto="$subdominioComHifenSemPonto" ./create-kubernetes-cluster.sh
else
  echo "O cluster $subdominio já existe."
fi

# Implantação dos serviços do Kubernetes.
subdominioComHifenSemPonto="$subdominioComHifenSemPonto" certificadoSubdominio="$certificadoSubdominio" chavePrivadaSubdominio="$chavePrivadaSubdominio" cidrBalanceadorCarga="$cidrBalanceadorCarga" ipBalanceadorCarga="$ipBalanceadorCarga" ipServidorNomes="$ipServidorNomes" ./deploy-kubernetes-services.sh

# Configurações que requerem privilégios administrativos.
if [ "$hasAdministrativePrivileges" == "true" ]
then
  setTrustedACCertificate "$dominio" "$certificadoACRaiz"

  if [ "$isBind9Enabled" != "false" ]
  then
    setHostAsDNSClient "$dominio" "$ipServidorNomes"
  fi

  echo "Convém configurar o navegador para confiar no certificado da AC Raiz ($certificadoACRaiz)."
else
  echo "Convém configurar o sistema operacional e o navegador para confiarem no certificado da AC Raiz ($certificadoACRaiz)."

  if [ "$isBind9Enabled" != "false" ]
  then
    echo "Além disso, deve ser configurada a resolução de nomes pelo servidor DNS de IP $ipServidorNomes."
  fi
fi