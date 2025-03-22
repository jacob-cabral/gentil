#! /bin/bash
# Sai imediatamente se um comando sai com um status não-zero.
set -e

# Importação da função utilitária isNotNull.
source util/is-not-null.sh
source util/has-pod-not-running.sh

# Validação dos dados obrigatórios.
isNotNull dominio
isNotNull subdominio
isNotNull subdominioComHifenSemPonto

# Definição de variável.
cidr=$cidrBalanceadorCarga
ipReverso=$(echo $ipBalanceadorCarga | sed --expression='s/^\([0-9]\{1,3\}\)\.\([0-9]\{1,3\}\)\.\([0-9]\{1,3\}\).\+$/\3.\2.\1/')
octeto=$(echo $ipBalanceadorCarga | sed --expression='s/^\([0-9]\{1,3\}\).\+$/\1/')

# Ajustar a implantação do Bind9.
hasNamespace="$(kubectl get namespace bind9 --output json | jq '.kind')"

if [[ (-z "$hasNamespace" || -n "$(hasPodNotRunning bind9)") && "$isBind9Enabled" != "false" ]]
then
echo "Implantação do servidor de nomes (Bind9)."
cat << EOF | kubectl apply --namespace=bind9 --filename -
---
apiVersion: v1
kind: Namespace
metadata:
  name: bind9
spec:
  finalizers:
  - kubernetes
---
apiVersion: v1
kind: Service
metadata:
  name: bind9
  labels:
    app.kubernetes.io/name: bind9
  annotations:
    metallb.universe.tf/allow-shared-ip: "key-to-shared-ip"
spec:
  selector:
    app.kubernetes.io/name: bind9
  type: LoadBalancer
  loadBalancerIP: $ipBalanceadorCarga
  ports:
  - name: tcp
    port: 53
    targetPort: tcp
    protocol: TCP
  - name: udp
    port: 53
    targetPort: udp
    protocol: UDP
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: bind9
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: bind9
  template:
    metadata:
      labels:
        app.kubernetes.io/name: bind9
    spec:
      containers:
      - name: bind9
        image: ubuntu/bind9:edge
        env:
        ports:
        - name: tcp
          containerPort: 53
          protocol: TCP
        - name: udp
          containerPort: 53
          protocol: UDP
        volumeMounts:
        - name: conf
          mountPath: /etc/bind/named.conf.local
          subPath: named.conf.local
        - name: conf
          mountPath: /etc/bind/named.conf.options
          subPath: named.conf.options
        - name: conf
          mountPath: /etc/bind/db.$dominio
          subPath: db.$dominio
        - name: conf
          mountPath: /etc/bind/db.$octeto
          subPath: db.$octeto
      volumes:
      - name: conf
        configMap:
          name: bind9
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: bind9
data:
  named.conf.local: |
    //
    // Do any local configuration here
    //

    // Consider adding the 1918 zones here, if they are not used in your
    // organization
    //include "/etc/bind/zones.rfc1918";

    zone "$dominio" {
      type master;
      file "/etc/bind/db.$dominio";
    };

    zone "$ipReverso.in-addr.arpa" {
        type master;
        file "/etc/bind/db.$octeto";
    };
  named.conf.options: |
    options {
      directory "/var/cache/bind";

      // If there is a firewall between you and nameservers you want
      // to talk to, you may need to fix the firewall to allow multiple
      // ports to talk.  See http://www.kb.cert.org/vuls/id/800113

      // If your ISP provided one or more IP addresses for stable
      // nameservers, you probably want to use them as forwarders.
      // Uncomment the following block, and insert the addresses replacing
      // the all-0's placeholder.

      forwarders {
          1.0.0.1;
          1.1.1.1;
          8.8.4.4;
          8.8.8.8;
          9.9.9.9;
      };

      //========================================================================
      // If BIND logs error messages about the root key being expired,
      // you will need to update your keys.  See https://www.isc.org/bind-keys
      //========================================================================
      dnssec-validation no;

      listen-on { any; };
    };
  db.$dominio: |
    ;
    ; BIND arquivo de dados para o domínio $dominio.
    ;
    \$TTL    604800
    @                               IN      SOA     $dominio. root.$dominio. (
                                          1         ; Serial
                                     604800         ; Refresh
                                      86400         ; Retry
                                    2419200         ; Expire
                                     604800 )       ; Negative Cache TTL
    @                               IN      NS      nomes.$dominio.
    @                               IN      A       $ipServidorNomes
    nomes                           IN      A       $ipServidorNomes
    $(printf "%-29s" $subdominio)   IN      A       $ipBalanceadorCarga
    $(printf "*.%-29s" $subdominio) IN      CNAME   $subdominio
  db.$octeto: |
    ;
    ; BIND arquivo de dados reversos para a rede.
    ;
    \$TTL   604800
    @   IN  SOA  nomes.$dominio. root.$dominio. (
                    1   ; Serial
         604800   ; Refresh
          86400   ; Retry
        2419200   ; Expire
         604800 ) ; Negative Cache TTL
    ;
    @   IN  NS   nomes.
    10  IN  PTR  nomes.$dominio.
EOF
echo "O Bind9 foi implantado com sucesso."
elif [ "$isBind9Enabled" != "false" ]
then
echo "O Bind9 já está implantado."
fi