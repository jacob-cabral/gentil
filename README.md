# Gentil
O Gentil é um facilitador da execução de um cluster Kubernetes em ambiente local, sendo baseado na ferramenta [kind](https://sigs.k8s.io/kind), de onde também deriva o seu tão criativo nome.

## O que é que o Gentil tem?
O cluster executado pelo Gentil possui as seguintes características:
  - Baseado no Docker, executado em contêineres;
  - Cliente do servidor de nomes local (possivelmente, o Bind9);
  - Aplicações implantadas obrigatoriamente:
    - CertManager, o emissor de certificados SSL;
    - MetalLB, o balanceador de carga;
    - Nginx Ingress Controller, o controlador de entrada HTTP e HTTPS;
    - Sealed Secrets Controller, o controlador de dados sensíveis cifrados.
  - Aplicações implantadas em caráter opcional:
    - Bind9, o servidor de nomes (DNS), que resolve os nomes de domínio locais e repassa as consultas dos demais nomes ao Cloudflare, ao Google Public DNS ou ao Quad9;
    - Harbor, o repositório de imagens Docker;
    - Keycloak, o provedor de identidades;
    - Loki-Stack (Loki, Grafana, Promtail e Prometheus), a solução de:
      - centralização de logs e métricas e de construção e visualização de painéis gráficos;
      - monitoramento e alerta.
    - Longhorn, o serviço de armazenamento persistente com suporte a leitura e escrita múltiplas (RWX);
    - MailHog, o serviço SMTP;
    - PostgreSQL, o banco de dados relacional.

## Requisitos
Os atuais requisitos da execução do Gentil são:
- Sistema operacional Linux, tendo sido testado na distribuição Ubuntu 24.04 LTS (Noble Numbat);
- [Helm](https://helm.sh/);
- [kind](https://kind.sigs.k8s.io/);
- [kubectl](https://kubernetes.io/docs/reference/kubectl/);
- [kubeseal](https://github.com/bitnami-labs/sealed-secrets);
- [Docker](https://www.docker.com/).

## Configurações
A execução do Gentil é parametrizada pelas configurações abaixo:

| Nome | Valor padrão | Obrigatoriedade | Objetivo |
|------|:------------:|:---------------:|----------|
| dominio | - | Sim | Define o nome de domínio (DNS). |
| subdominio | - | Sim | Define o nome do subdomínio (DNS). |
| isBind9Enabled | true | Não | Define se o Bind9 deve ser implantado no cluster Kubernetes. |
| isHarborEnabled | - | Não | Define se o Harbor deve ser implantado no cluster Kubernetes. |
| isKeycloakEnabled | - | Não | Define se o Keycloak deve ser implantado no cluster Kubernetes. |
| isLokiStackEnabled | - | Não | Define se os serviços de monitoramento (Loki Stack) devem ser implantados no cluster Kubernetes. |
| isLonghornEnabled | - | Não | Define se o Longhorn deve ser implantado no cluster Kubernetes. |
| isMailHogEnabled | - | Não | Define se o MailHog deve ser implantado no cluster Kubernetes. |
| isPostgreSQLEnabled | - | Não | Define se o PostgreSQL deve ser implantado no cluster Kubernetes. |
| hasAdministrativePrivileges | - | Não | Define se a execução do Gentil deve incluir os procedimentos que exigem privilégios administrativos, a saber, a configuração do hospedeiro como cliente do servidor DNS e do certificado da AC Raiz como confiável. |

## Como usar?
O arquivo `setup.sh` é o ponto de entrada da execução do Gentil. Essa execução é demonstrada abaixo:
```bash
dominio=exemplo subdominio=nuvem ./setup.sh
```
A execução do `setup.sh` pode ser feita a partir do diretório de checkout do Gentil ou, preferencialmente, do diretório específico para manter os arquivos dos certificados SSL, criados juntamente ao cluster Kubernetes.
As definições dos valores das variáveis `dominio` e `subdominio` são obrigatórias. Esses valores são necessários para a configuração do servidor de nomes, a criação dos certificados SSL etc.