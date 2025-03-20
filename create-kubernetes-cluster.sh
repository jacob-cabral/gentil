#! /bin/bash
# Sai imediatamente se um comando sai com um status não-zero.
set -e

# Importação da função utilitária isNotNull.
source util/is-not-null.sh

# Validação dos dados obrigatórios.
isNotNull dominio
isNotNull subdominio
isNotNull certificadoACRaiz
isNotNull subdominioComHifenSemPonto

# Criação do cluster Kubernetes.
echo "Criação do cluster Kubernetes intitulado $subdominioComHifenSemPonto."
cat << EOF | kind create cluster --wait 10m --config -
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: $subdominioComHifenSemPonto
nodes:
  - role: control-plane
    image: kindest/node:v1.29.12
    extraMounts:
      - hostPath: "$certificadoACRaiz"
        containerPath: "/etc/ssl/certs/ac.$dominio.pem"
  - role: worker
    image: kindest/node:v1.29.12
    extraMounts:
      - hostPath: "$certificadoACRaiz"
        containerPath: "/etc/ssl/certs/ac.$dominio.pem"
  - role: worker
    image: kindest/node:v1.29.12
    extraMounts:
      - hostPath: "$certificadoACRaiz"
        containerPath: "/etc/ssl/certs/ac.$dominio.pem"
  - role: worker
    image: kindest/node:v1.29.12
    extraMounts:
      - hostPath: "$certificadoACRaiz"
        containerPath: "/etc/ssl/certs/ac.$dominio.pem"
EOF
echo "O cluster $subdominio foi criado com sucesso."