#!/bin/bash

# /*********************************************************************************
# * Projeto:   AutoServer
# * Autor:     Carlos Henrique Tourinho Santana
# * GitHub:    https://github.com/henriquetourinho/autoserver
# * Versão:    1.0
# * Data:      12 de junho de 2025
# *
# * Descrição:
# * Este script realiza a instalação e configuração completa de um servidor web
# * com a stack LEMP (Linux, Nginx, MariaDB, PHP) em sistemas operacionais
# * baseados em Debian/Ubuntu. Além da stack principal, ele também provisiona
# * o phpMyAdmin como interface de gerenciamento para o banco de dados.
# * O design do script foca em uma execução de "ponta a ponta" sem necessidade
# * de qualquer intervenção do usuário, tornando-o ideal para deploys rápidos,
# * ambientes de teste ou para usuários com menos experiência em administração
# * de sistemas.
# *
# * Funcionalidades Principais:
# * - Instalação "One-Click": Executa todo o processo com um único comando.
# * - Segurança por Padrão: Gera uma senha forte e aleatória para o usuário
# * root do MariaDB, evitando credenciais fixas e inseguras.
# * - Configuração Inteligente: Instala o phpMyAdmin de forma limpa, evitando
# * o conflito comum da instalação do servidor Apache2 como dependência.
# * - Integração Nginx + PHP: Configura automaticamente o Nginx para processar
# * scripts PHP através do PHP-FPM, utilizando a versão correta.
# * - Robusto e à Prova de Falhas: O script para imediatamente se um erro ocorre,
# * verifica privilégios de root e testa as configurações do Nginx antes de
# * aplicá-las para evitar a quebra do serviço web.
# * - Customizável: As configurações chave, como a versão do PHP, são definidas
# * em variáveis no topo do arquivo para fácil alteração.
# *********************************************************************************/


# --------------------------------------------------------------------------------------
# SEÇÃO 1: PREPARAÇÃO E VERIFICAÇÕES DE SEGURANÇA
# --------------------------------------------------------------------------------------

# Garante que o script pare imediatamente se qualquer comando retornar um erro.
# Isso previne instalações parciais ou configurações incorretas. 'e' é para 'exit'.
set -e

# Garante que o script seja executado com privilégios de superusuário (root).
# Comandos de instalação e configuração de sistema exigem permissão de administrador.
if [ "$(id -u)" -ne 0 ]; then
  echo "❌ ERRO: Este script precisa ser executado com privilégios de root."
  echo "   Por favor, salve o arquivo como 'autoserver.sh' e tente novamente usando: sudo ./autoserver.sh"
  exit 1 # Encerra o script com um código de erro.
fi


# --------------------------------------------------------------------------------------
# SEÇÃO 2: VARIÁVEIS DE CONFIGURAÇÃO
#
# Centralizar as variáveis aqui facilita a customização do script no futuro
# sem precisar alterar a lógica principal.
# --------------------------------------------------------------------------------------

# Gera uma senha forte e aleatória para o usuário 'root' do banco de dados.
# Usar `openssl rand` é um método criptograficamente seguro e robusto.
# `tr -d` remove caracteres que podem causar problemas em linhas de comando.
DB_ROOT_PASS=$(openssl rand -base64 16 | tr -d '/+=')

# Define a versão específica do PHP que será instalada.
# Fixar a versão (ex: 8.2) garante consistência e evita surpresas caso a
# distribuição Linux mude a sua versão padrão. PHP 8.2 é uma escolha moderna
# com bom desempenho e suporte de longo prazo (LTS).
PHP_VERSION="8.2"

# Define o diretório raiz para os arquivos do site.
# /var/www/html é o padrão na maioria dos sistemas.
WEB_ROOT="/var/www/html"


# --------------------------------------------------------------------------------------
# SEÇÃO 3: EXECUÇÃO DA INSTALAÇÃO
# --------------------------------------------------------------------------------------

# O script começa a executar as tarefas. As mensagens `echo` informam o usuário
# sobre o progresso de cada etapa.
echo "🚀 INICIANDO A INSTALAÇÃO E CONFIGURAÇÃO DO SERVIDOR LEMP..."
sleep 2 # Uma pequena pausa para o usuário poder ler a mensagem inicial.

# ETAPA 1: ATUALIZAÇÃO DO SISTEMA
echo "🔄 [ETAPA 1/6] Atualizando a lista de pacotes e o sistema operacional..."
apt-get update      # Sincroniza a lista de pacotes disponíveis com os repositórios.
apt-get upgrade -y  # Atualiza todos os pacotes instalados para suas versões mais recentes.
                    # O '-y' responde 'sim' automaticamente a todas as perguntas.

# ETAPA 2: INSTALAÇÃO DOS PACOTES PRINCIPAIS
echo "📦 [ETAPA 2/6] Instalando Nginx, MariaDB e a versão ${PHP_VERSION} do PHP..."
# Instala o servidor web, o servidor de banco de dados e o cliente de linha de comando.
apt-get install -y nginx mariadb-server mariadb-client

# Instala a versão específica do PHP-FPM (FastCGI Process Manager), que é a forma
# como o Nginx se comunica com o PHP, e os módulos PHP mais comuns e necessários
# para a maioria das aplicações web (ex: conexão com banco de dados, manipulação
# de XML, strings, etc.).
apt-get install -y \
  php${PHP_VERSION}-fpm \
  php${PHP_VERSION}-mysql \
  php${PHP_VERSION}-cli \
  php${PHP_VERSION}-curl \
  php${PHP_VERSION}-xml \
  php${PHP_VERSION}-mbstring \
  php${PHP_VERSION}-zip \
  php${PHP_VERSION}-bcmath \
  php-json \
  php-common

# ETAPA 3: CONFIGURAÇÃO SEGURA DO BANCO DE DADOS (MARIADB)
echo "🔒 [ETAPA 3/6] Configurando e protegendo o servidor de banco de dados MariaDB..."

# Garante que o serviço do MariaDB seja iniciado agora e também automaticamente
# toda vez que o servidor for reiniciado.
systemctl enable mariadb
systemctl start mariadb

# Executa uma série de comandos SQL para realizar a "configuração segura" de forma
# totalmente automatizada. Isso é mais confiável do que tentar automatizar o script
# interativo `mysql_secure_installation`.
mysql -u root <<EOF
-- 1. Define a senha para o usuário 'root', usando a senha aleatória gerada.
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASS}';
-- 2. Remove os usuários anônimos, que são um risco de segurança.
DELETE FROM mysql.user WHERE User='';
-- 3. Remove o banco de dados 'test', que é criado por padrão e não é necessário.
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
-- 4. Aplica todas as alterações de privilégios imediatamente.
FLUSH PRIVILEGES;
EOF

echo "🔑 Senha do usuário 'root' do MariaDB foi definida com sucesso."

# ETAPA 4: CONFIGURAÇÃO DO NGINX PARA PROCESSAR PHP
echo "⚙️  [ETAPA 4/6] Configurando o Nginx para se comunicar com o PHP-FPM..."

# Este bloco cria o arquivo de configuração do site padrão do Nginx.
# Ele substitui o arquivo original por um que sabe como lidar com PHP.
# A diretiva `location ~ \.php$` é a mais importante, pois redireciona
# todas as requisições para arquivos terminados em .php para o PHP-FPM.
cat > /etc/nginx/sites-available/default <<EOF
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    root ${WEB_ROOT};
    index index.php index.html index.htm; # Prioriza 'index.php' como página inicial.

    server_name _; # Responde a qualquer nome de domínio.

    location / {
        try_files \$uri \$uri/ =404;
    }

    # Bloco de configuração crucial para o PHP
    location ~ \.php$ {
        include snippets/fastcgi-php.conf; # Inclui configurações padrão do FastCGI.
        # Passa a requisição para o socket do PHP-FPM da versão que instalamos.
        # O caminho do socket é dinâmico, baseado na variável \$PHP_VERSION.
        fastcgi_pass unix:/run/php/php${PHP_VERSION}-fpm.sock;
    }

    # Proíbe o acesso a arquivos como .htaccess, comum em servidores Apache.
    location ~ /\.ht {
        deny all;
    }
}
EOF

# Verifica se a sintaxe do arquivo de configuração do Nginx está correta
# antes de tentar reiniciar o serviço. Isso evita que o servidor web falhe.
nginx -t

echo "✅ Configuração do Nginx para PHP finalizada com sucesso."

# ETAPA 5: INSTALAÇÃO DO PHPMYADMIN (SEM CONFLITOS)
echo "🗃️ [ETAPA 5/6] Instalando o painel de gerenciamento phpMyAdmin..."

# Este comando é um truque essencial para automação. Ele pré-configura a resposta
# para a pergunta que o instalador do phpMyAdmin faria sobre qual servidor web
# reconfigurar. Ao escolher 'none', evitamos que ele tente instalar o 'apache2'
# como dependência, o que causaria conflito com nosso Nginx.
echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect none" | debconf-set-selections

# Instala o phpMyAdmin, mas sem pacotes "recomendados" para evitar lixo.
apt-get install -y phpmyadmin --no-install-recommends

# O phpMyAdmin é instalado em /usr/share/phpmyadmin. Precisamos criar um atalho
# (link simbólico) para dentro do nosso diretório web para que ele fique acessível
# pelo navegador.
ln -s /usr/share/phpmyadmin ${WEB_ROOT}/phpmyadmin

# ETAPA 6: FINALIZAÇÃO E REINICIALIZAÇÃO DOS SERVIÇOS
echo "🔄 [ETAPA 6/6] Reiniciando e habilitando os serviços para aplicar as mudanças..."

# Reinicia os serviços para que todas as novas configurações entrem em vigor.
systemctl restart mariadb
systemctl restart "php${PHP_VERSION}-fpm"
systemctl restart nginx

# Habilita os serviços para que eles iniciem automaticamente com o sistema.
systemctl enable "php${PHP_VERSION}-fpm"
systemctl enable nginx


# --------------------------------------------------------------------------------------
# SEÇÃO 4: MENSAGEM DE SUCESSO E INFORMAÇÕES FINAIS
# --------------------------------------------------------------------------------------
echo ""
echo "==================================================================="
echo "✅  S U C E S S O !  O seu servidor foi provisionado pelo AutoServer."
echo "==================================================================="
echo ""
echo "O ambiente está pronto para uso. Aqui estão suas informações de acesso:"
echo ""
echo "🔗 Para gerenciar seus bancos de dados, acesse o phpMyAdmin:"
echo "   URL: http://<IP_DO_SEU_SERVIDOR>/phpmyadmin"
echo ""
echo "🔐 Credenciais de acesso ao Banco de Dados (MariaDB):"
echo "   Usuário: root"
echo "   Senha:   ${DB_ROOT_PASS}"
echo ""
echo "==================================================================="
echo "⚠️  IMPORTANTE: Anote esta senha e guarde-a em um local seguro! ⚠️"
echo "==================================================================="
echo ""