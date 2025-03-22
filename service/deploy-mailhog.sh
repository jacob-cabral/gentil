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

# FIXME: Ajustar a implantação do MailHog.
hasNamespace="$(kubectl get namespace mailhog --output json | jq '.kind')"

if [[ (-z "$hasNamespace" || -n "$(hasPodNotRunning mailhog)" && "$isMailHogEnabled" == "true" ]]
then
echo "Implantação do serviço SMTP (MailHog)."
cat << EOF | kubectl apply --namespace=mailhog --filename -
---
apiVersion: v1
kind: Namespace
metadata:
  name: mailhog
spec:
  finalizers:
  - kubernetes
---
apiVersion: v1
kind: Secret
metadata:
  name: mailhog
type: Opaque
stringData:
  auth-file: |
    admin:\$2a\$04\$jJCi8GlkvkBIQCDXDzcuCuHOMrbtsX0JwVF3Gj6ItvR9tM0gVw04.
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: mailhog
  name: mailhog
spec:
  selector:
    matchLabels:
      app: mailhog
  template:
    metadata:
      labels:
        app: mailhog
    spec:
      containers:
      - name: mailhog
        image: mailhog/mailhog:v1.0.1
        command:
        - MailHog
        args:
        - -auth-file=/mnt/mailhog/auth-file
        resources:
          limits:
            cpu: 10m
            memory: 16Mi
        volumeMounts:
        - name: mailhog
          mountPath: /mnt/mailhog
          readOnly: false
      volumes:
      - name: mailhog
        secret:
          secretName: mailhog
          items:
          - key: auth-file
            path: auth-file
          defaultMode: 0444
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
---
apiVersion: v1
kind: Service
metadata:
  labels:
    app: mailhog
  name: mailhog
spec:
  ports:
  - name: smtp
    port: 25
    protocol: TCP
    targetPort: 1025
  - name: http
    port: 80
    protocol: TCP
    targetPort: 8025
  selector:
    app: mailhog
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    cert-manager.io/cluster-issuer: emissor-ac-$subdominioComHifenSemPonto
  name: mailhog
spec:
  ingressClassName: nginx
  rules:
  - host: mailhog.$subdominio.$dominio
    http:
      paths:
      - backend:
          service:
            name: mailhog
            port:
              name: http
        path: /
        pathType: Prefix
  tls:
  - hosts:
    - mailhog.$subdominio.$dominio
    secretName: mailhog-tls
---
EOF
echo "O MailHog foi implantado com sucesso."
elif [ "$isMailHogEnabled" == "true" ]
then
echo "O MailHog já está implantado."
fi