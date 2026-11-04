# Projeto IaC - Infraestrutura como Código (Linux)

Este repositório contém scripts de automação em Bash desenvolvidos durante o curso de Linux da [DIO.me](https://dio.me).

## 🚀 Objetivo
Automatizar a criação de toda a estrutura de usuários, grupos de departamentos, diretórios compartilhados e permissões de acesso em um sistema Linux de forma idêntica e rápida.

## 📂 Estrutura do Projeto
* **`iac1.sh`**: Script que cria os diretórios, grupos, usuários (com shell `/bin/bash` padrão) e aplica as permissões restritas.
* **`excluir_infra.sh`**: Script de limpeza completa que remove tudo o que foi gerado pelo primeiro script, permitindo resetar o ambiente de testes.

## 🛠️ Como Executar
1. Dê permissão de execução aos scripts:
   ```bash
   chmod +x iac1.sh excluir_infra.sh
   ```
2. Execute o script de criação como root:
   ```bash
   sudo ./iac1.sh
   ```
3. Se precisar resetar tudo, execute o script de exclusão:
   ```bash
   sudo ./excluir_infra.sh
   ```

---

## 👤 Autor
**Douglas D’Alcântara Guanaes**  
* GitHub: [M3NT41H34D](https://github.com/M3NT41H34D)
