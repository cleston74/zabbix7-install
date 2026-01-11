# 🚀 Instalação Automatizada do Zabbix 7.0 (All-in-One)

## 📌 Visão Geral

![License](https://img.shields.io/badge/license-MIT-green)
![Status](https://img.shields.io/badge/status-lab%2Fstudy-blue)
![Zabbix](https://img.shields.io/badge/Zabbix-7.x-red)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-17-blue)
![TimescaleDB](https://img.shields.io/badge/TimescaleDB-enabled-orange)

Este projeto tem como objetivo realizar a **instalação totalmente automatizada do Zabbix Server 7.x** em modo **All-in-One**, utilizando:

- Zabbix Server 7.x
- PostgreSQL 17
- TimescaleDB
- Nginx
- PHP-FPM
- Zabbix Agent 2

Todo o processo é executado a partir de uma **máquina virtual limpa**, através de um único script em **Shell Script**, de forma simples, reprodutível e rápida.

> 🔬 Projeto voltado para **estudos, testes e laboratórios**  
> ⚠️ **Não recomendado para ambientes de produção**

---

## 🧰 Pré-requisitos

### Sistema Operacional (RHEL-like 9.x)

Compatível com:

- Red Hat Enterprise Linux 9
- Rocky Linux 9
- AlmaLinux 9
- Oracle Linux 9

### Hardware mínimo recomendado

- **4 vCPUs**
- **4 GB de RAM**
- **40 GB de disco**

### Requisitos adicionais

- Acesso **root**
- Conexão com a **internet**
- **Git** instalado

---

## ⚙️ Preparação do Ambiente

### Atualize o sistema operacional

```bash
dnf update -y && dnf upgrade -y
```

### Instale o Git

```bash
dnf -y install git
```

### Clone o repositório

```bash
git clone https://github.com/cleston74/zabbix7-install.git
```

### Acesse o diretório do projeto

```bash
cd zabbix7-install/scripts
```

### Torne o script executável

```bash
chmod +x install_zabbix.sh
```

---

## ▶️ Modo de Uso

O script pode ser executado **sem parâmetros**, utilizando valores padrão, ou com **parâmetros personalizados**.

### 🔧 Parâmetros aceitos

| Parâmetro | Descrição |
|----------|----------|
| --host | Hostname do Zabbix Server |
| --db | Nome do banco de dados |
| --user | Usuário do banco |
| --password | Senha do usuário |
| -h, --help | Exibe a ajuda |

> Caso algum parâmetro seja omitido, o script utilizará **valores padrão**, definidos internamente.

---

## 📌 Exemplos de Execução

### Instalação com valores padrão

```bash
./install_zabbix.sh
```

### Instalação personalizada

```bash
./install_zabbix.sh --host spappzbx01 --password s3nh4f0Rt3
```

---

## ✅ Final da Instalação

Ao final da execução, serão exibidos:

- URL de acesso ao Zabbix
- Credenciais padrão
- Hostname configurado
- IP local do servidor

---

## 🌐 Primeiro Acesso

Acesse via navegador:

![Opções de Instalação](<images/zbx-03.png>)

```
http://IP_DO_SERVIDOR/
ou
http://HOSTNAME/
```

Credenciais padrão:

- **Usuário:** Admin
- **Senha:** zabbix

![Opções de Instalação](<images/zbx-04.png>)

![Opções de Instalação](<images/zbx-05.png>)

---

## 🖥️ Configuração Automática do Host

O script realiza automaticamente:

- Atualização do hostname no banco do Zabbix
- Atualização do IP local
- Ajuste do host padrão **Zabbix server**

![Opções de Instalação](<images/zbx-06.png>)

---

## 🐘 Monitoramento do PostgreSQL

Para monitorar o PostgreSQL local:

1. Edite o host no Zabbix
2. Associe o **template PostgreSQL**
3. Configure a **macro de senha** com a senha utilizada na instalação

![Opções de Instalação](<images/zbx-07.png>)

![Opções de Instalação](<images/zbx-08.png>)

---

## 📊 Visualização das Métricas

Acesse:

Monitoring → Latest data

![Opções de Instalação](<images/zbx-09.png>)

---

## ⚠️ Aviso Importante

Este projeto foi desenvolvido **exclusivamente para fins educacionais**.

- ❌ Não utilizar em produção
- ✔️ Pode ser modificado e redistribuído
- 🤝 Contribuições são bem-vindas via **Pull Request**

---

## 👨‍💻 Autor

Cleiton Maia  
📧 cleiton.maia@pm.me  
🐙 GitHub: https://github.com/cleston74
