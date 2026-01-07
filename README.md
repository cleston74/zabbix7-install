# Instalação automatizada Zabbix 7.0

## 🎯 Objetivo - A partir de uma VM, instalar o Zabbix na versão 7.x com banco de dados PostgreSQL 17 com TimescaleDB em modo "All In One" de forma totalmente automatizada através de script. Ideal para estudos e testes.

---

## Pré requisitos:

>VM Linux com Sistema Operacional RHEL Like na versão 9.x:
>
>1. RedHat
>2. Rocky Linux
>3. Alma Linux
>4. Oracle Linux
>
>Hardware mínimo
>
>4 vCPUs / 4 GB Ram / 40GB HD
>
>Acesso _root_ ao Linux
>
>Acesso a internet
>
> Git instalado

## Antes de instalar

Atualize seu Linux

```bash
dnf update ; dnf upgrade
```

Instale o git

```bash
dnf -y install git
```

Clone o projeto

```bash
git clone https://github.com/cleston74/zabbix7-install.git
```

Acesse a pasta do projeto

```bash
cd zabbix7-install/scripts
```

Torne o script em executável

```bash
chmod +x install_zabbix.sh
```

## Modo de Uso:

## 🔧 O script aceita os parametros abaixo:

>1. Hostname
>2. Banco de Dados
>3. Usuário
>4. Senha
>
>Caso os parametros sejam omitidos, valores padrão serãm assumidos. Estes podem ser conferidos dentro do script.

Exemplos:

![Opções de Instalação](<images/zbx-01.png>)

## Instalação do Zabbix Server

```bash
./install_zabbix.sh --host spappzbx01 --password s3nh4f0Rt3
```

![Opções de Instalação](<images/zbx-02.png>)

>-O tempo de instalação vai variar de acordo com a velovidade de sua internet.

## Ao final da instalação, serão exibidos dados de acesso.

![Opções de Instalação](<images/zbx-03.png>)

## Primeiro acesso

![Opções de Instalação](<images/zbx-04.png>)

![Opções de Instalação](<images/zbx-05.png>)

## O script já realiza as alterações necessárias no Banco de Dados para que o host no Zabbix tenha o nome e o ip definidos no momento da instalação.

![Opções de Instalação](<images/zbx-06.png>)

## Se quiser monitorar seu PostgreSQL, edite o host e adicione o template conforme a imagem e adicione na macro a senha utilizada na instalação.

![Opções de Instalação](<images/zbx-07.png>)

![Opções de Instalação](<images/zbx-08.png>)

## Depois é só acompanhar as informações no _Latest data_

![Opções de Instalação](<images/zbx-09.png>)

Esse é um projeto para caso de estudo, não deve ser utilizado em produção.

Pode ser alterado e distribuido conforme necessário. Se for melhorar, faça um PR no git.
