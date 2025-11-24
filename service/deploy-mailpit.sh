#! /bin/bash
# Sai imediatamente se um comando sai com um status não-zero.
set -e

# Importa utilitários locais
source util/is-not-null.sh
source util/has-pod-not-running.sh

# Validação dos dados obrigatórios.
isNotNull dominio
isNotNull subdominio
isNotNull subdominioComHifenSemPonto

# FIXME: Ajustar a implantação do Mailpit.
hasNamespace="$(kubectl get namespace mailpit --output json 2>/dev/null || true)"

if [[ (-z "$hasNamespace" || -n "$(hasPodNotRunning mailpit)") && "$isMailpitEnabled" == "true" ]]
then
echo "Implantação do serviço SMTP (Mailpit)"
cat << EOF | kubectl apply --namespace=mailpit --filename -
---
apiVersion: v1
kind: Namespace
metadata:
  name: mailpit
spec:
  finalizers:
  - kubernetes
---
apiVersion: v1
kind: Secret
metadata:
  name: mailpit-auth
type: Opaque
stringData:
  auth-file: |
    admin:\$2a\$04\$jJCi8GlkvkBIQCDXDzcuCuHOMrbtsX0JwVF3Gj6ItvR9tM0gVw04.
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: mailpit
  name: mailpit
spec:
  selector:
    matchLabels:
      app: mailpit
  template:
    metadata:
      labels:
        app: mailpit
    spec:
      containers:
      - name: mailpit
        image: axllent/mailpit:v1.27.11
        command:
        - ./mailpit
        args:
        - --smtp
        - 0.0.0.0:587
        - --listen
        - 0.0.0.0:8025
        - --smtp-tls-cert
        - /etc/tls/tls.crt
        - --smtp-tls-key
        - /etc/tls/tls.key
        - --smtp-require-starttls
        - --smtp-auth-file
        - /mnt/mailpit/auth-file
        ports:
        - name: smtp
          containerPort: 587
          protocol: TCP
        - name: http
          containerPort: 8025
          protocol: TCP
        resources:
          limits:
            cpu: 50m
            memory: 64Mi
        volumeMounts:
        - name: mailpit-auth
          mountPath: /mnt/mailpit
          readOnly: true
        - name: ingress-tls
          mountPath: /etc/tls
          readOnly: true
      volumes:
      - name: mailpit-auth
        secret:
          secretName: mailpit-auth
          items:
          - key: auth-file
            path: auth-file
          defaultMode: 0440
      - name: ingress-tls
        secret:
          secretName: mailpit-tls
          items:
          - key: tls.crt
            path: tls.crt
          - key: tls.key
            path: tls.key
          defaultMode: 0440
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
---
apiVersion: v1
kind: Service
metadata:
  labels:
    app: mailpit
  name: mailpit
spec:
  ports:
  - name: smtp
    port: 587
    protocol: TCP
    targetPort: 587
  - name: http
    port: 80
    protocol: TCP
    targetPort: 8025
  selector:
    app: mailpit
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    cert-manager.io/cluster-issuer: emissor-ac-$subdominioComHifenSemPonto
  name: mailpit
spec:
  ingressClassName: nginx
  rules:
  - host: mailpit.$subdominio.$dominio
    http:
      paths:
      - backend:
          service:
            name: mailpit
            port:
              name: http
        path: /
        pathType: Prefix
  tls:
  - hosts:
    - mailpit.$subdominio.$dominio
    secretName: mailpit-tls
---
EOF
echo "O Mailpit foi implantado com sucesso."
elif [ "$isMailpitEnabled" == "true" ]
then
echo "O Mailpit já está implantado."
fi