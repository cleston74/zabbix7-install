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
>- 4 vCPUs / 4 GB Ram / 40GB HD
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

## Modo de Uso:

## 🔧 Para iniciar um novo projeto de documentação, navegue até o diretório onde deseja criar o projeto e execute:

```bash
mkdocs new Void_Artigos
```

## Isso criará um novo diretório chamado Void_Artigos com a estrutura básica do MkDocs.

## 2. Usar o Tema Material (Opcional)

## 🧩 Se você criou um novo projeto, edite o arquivo de configuração mkdocs.yml dentro do diretório do projeto (Void_Artigos/mkdocs.yml) e adicione a configuração do tema Material:

```bash
site_name: Void Artigos
nav:
    - Home: index.md
    - Sobre: about.md

theme:
  name: material # Adicione esta linha para usar o tema Material
```

## 3. Iniciar o Servidor de Desenvolvimento

## Para visualizar sua documentação localmente enquanto a edita, navegue até o diretório do projeto e inicie o servidor de desenvolvimento:

```bash
cd void-Artigos
```

```bash
mkdocs serve
```

## O servidor será iniciado e você poderá acessar a documentação no seu navegador, geralmente em http://127.0.0.1:8000. O MkDocs monitorará automagicamente as alterações nos seus arquivos e recarregará a página.

## Para servir a rede interna, disponibilize o ip e a porta do Servidor

```bash
mkdocs serve 192.168.70.100:8000
```

## Sendo acessível de qualquer navegador da rede interna

```bash
http://192.168.70.100:8000
```

## 4. Construir a Documentação Estática

## Quando sua documentação estiver pronta para ser publicada, construa os arquivos estáticos:

```bash
mkdocs build
```

## Isso criará um diretório chamado site/ contendo todos os arquivos HTML, CSS e JavaScript necessários para hospedar sua documentação em qualquer servidor web. Em resumo, o fato de estar no Void Linux não altera o fluxo de trabalho do MkDocs, graças ao uso do pipx que isola a aplicação de forma eficaz.

---

🎯 THAT'S ALL FOLKS!

👉 Contato: zerolies@disroot.org
👉 https://t.me/z3r0l135
