# AutoServer 🚀🐧

**AutoServer** é um script profissional em Bash para **instalar e configurar um servidor web LEMP completo** (Linux, Nginx, MariaDB, PHP) de forma 100% automatizada.

Com um único comando, você transforma uma máquina Linux "limpa" em um servidor de alta performance pronto para hospedar:
- Sites, blogs e e-commerces em PHP (como WordPress, Laravel, etc.)
- Dashboards e painéis de controle
- Aplicações web e APIs
- E muito mais!

---

## 📦 O que o AutoServer faz por você

- ✅ **Verificação Inicial:** Garante que o script seja executado com permissões de administrador (`root`).
- 🔄 **Atualização do Sistema:** Executa `apt update` e `apt upgrade` para garantir que todos os pacotes do sistema estejam atualizados.
- ⚙️ **Instalação da Stack LEMP:** Instala Nginx, MariaDB e uma versão moderna e estável do PHP-FPM.
- 🔒 **Segurança Automatizada:**
    - Cria uma senha forte e aleatória para o usuário `root` do MariaDB.
    - Remove usuários anônimos e bancos de dados de teste.
- 🔌 **Configuração Inteligente:**
    - Configura o Nginx para se comunicar perfeitamente com o PHP-FPM.
    - Instala o phpMyAdmin **sem** o servidor Apache2, evitando conflitos.
- 🗃️ **Acesso Fácil ao Banco:** Disponibiliza o phpMyAdmin para gerenciamento web do banco de dados.
- 📜 **Logs de Sucesso:** Ao final, exibe de forma clara as credenciais de acesso para você não se perder.

---

## 🚀 Por que essa Stack? (LEMP + AutoServer)

A stack **LEMP** é a escolha de gigantes da tecnologia por sua performance e eficiência. O AutoServer une essas tecnologias da melhor forma:

-   **Nginx:** É extremamente rápido e consome menos memória que outros servidores, ideal para servir tanto conteúdo estático quanto dinâmico de forma otimizada.
-   **MariaDB:** Um fork do MySQL mantido pela comunidade, totalmente compatível e com performance aprimorada. É o coração do seu banco de dados.
-   **PHP-FPM:** A forma mais moderna e eficiente de rodar PHP com o Nginx, garantindo que suas aplicações sejam rápidas e escaláveis.

É a escolha perfeita para **hospedagem de alta performance** e **ambientes de produção robustos**.

---

## ⚙️ Requisitos

- Um servidor ou máquina virtual com **Debian** ou **Ubuntu**.
- Acesso à internet para baixar os pacotes.
- Acesso ao terminal com permissões de superusuário (`sudo`).

---

## 🛠️ Como Usar (É muito fácil!)

O AutoServer foi projetado para ser "zero-config". Você só precisa baixar e executar.

**1. Baixe o script**
Use o `wget` para baixar o arquivo diretamente no seu servidor.
```bash
wget https://[URL_PARA_SEU_ARQUIVO_AUTOSERVER.SH]
```

**2. Dê permissão de execução**
Torne o script executável.
```bash
chmod +x autoserver.sh
```

**3. Execute com sudo!**
Este é o único comando que você precisa para que a mágica aconteça.
```bash
sudo ./autoserver.sh
```
Agora é só pegar um café ☕ e esperar. O script fará todo o trabalho pesado.

---
### ✨ Customização (Opcional)

Se quiser usar uma versão diferente do PHP, basta editar a variável `PHP_VERSION` no topo do arquivo `autoserver.sh` antes de executá-lo.

```bash
# Define a versão específica do PHP que será instalada.
PHP_VERSION="8.2" # Mude aqui para "8.1", "8.3", etc.
```

---

## ✅ Pós-Instalação: Seus Próximos Passos

Ao final da execução, o script exibirá a senha do banco de dados.

- **Acesse o phpMyAdmin:** `http://<IP_DO_SEU_SERVIDOR>/phpmyadmin`
- **Usuário:** `root`
- **Senha:** *(será exibida no final da instalação)*
- **Coloque os arquivos do seu site em:** `/var/www/html`