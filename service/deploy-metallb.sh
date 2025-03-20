#! /bin/bash
# Sai imediatamente se um comando sai com um status não-zero.
set -e

# Importações das funções utilitárias.
source util/has-pod-not-running.sh
source util/is-not-null.sh
source util/is-helm-chart-installed.sh

# Validação dos dados obrigatórios.
isNotNull cidrBalanceadorCarga

# Implantação do balanceador de carga MetalLB.
if [ -z "$(isHelmChartInstalled metallb-system metallb)" ]
then
echo "Implantação do balanceador de carga MetalLB."

if [ -z "$(helm repo list --output yaml | yq '.[] | select(.name == "metallb").name')" ]
then
helm repo add metallb https://metallb.github.io/metallb
fi

helm upgrade metallb metallb/metallb --install --create-namespace --namespace metallb-system
echo "O MetalLB foi implantado com sucesso."
else
echo "O MetalLB já está implantado."
fi

while [ -n "$(hasPodNotRunning metallb-system)" ]
do
  echo "Aguardando a inicialização do serviço do MetalLB..."
  sleep 10
done

if [ -z "$(kubectl --namespace metallb-system get ipaddresspools.metallb.io)" ]
then
cat << EOF | kubectl --namespace metallb-system apply --filename -
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  creationTimestamp: null
  name: metallb-ip-address-pool
  namespace: metallb-system
spec:
  addresses:
  - $cidrBalanceadorCarga
EOF
echo "O IPAddressPool do MetalLB foi criado com sucesso."
else
echo "O IPAddressPool do MetalLB já existe."
fi

if [ -z "$(kubectl --namespace metallb-system get l2advertisements.metallb.io)" ]
then
cat << EOF | kubectl --namespace metallb-system apply --filename -
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: metallb-l2-advertisement
  namespace: metallb-system
spec:
  ipAddressPools:
  - metallb-ip-address-pool
EOF
echo "O L2Advertisement do MetalLB foi criado com sucesso."
else
echo "O L2Advertisement do MetalLB já existe."
fi