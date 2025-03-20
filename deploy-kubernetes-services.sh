#! /bin/bash
# Sai imediatamente se um comando sai com um status não-zero.
set -e

# Implantação dos serviços no cluster Kubernetes.
for file in $(ls service)
do
  installer=service/${file}
  chmod ug+x ${installer}
  ${installer}
done

# DISPONIBILIZAR STORAGE CLASS VIA NFS V4 NO LXC. Ref. RNP2021-108032.
# https://help.ubuntu.com/community/NFSv4Howto#NFSv4_Server
# https://gitlab.rnp.br/fsen/documentacao/-/blob/main/instalacao-do-nfs-v4.md
# CONSIDERAR DOMÍNIOS NIP.IO (https://nip.io/)
# https://keda.sh/
# https://kyverno.io/
# https://www.fairwinds.com/
# https://trivy.dev/
# https://medium.com/@petr.ruzicka/trivy-operator-dashboard-in-grafana-3d9cc733e6ab
# https://sentry.io/welcome/
# Instalar o Min.IO
# https://github.com/minio/minio/tree/master/helm/minio