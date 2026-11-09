# 🐧 Projeto IaC — Infraestrutura como Código (Linux)

![Shell](https://img.shields.io/badge/shell-bash-4EAA25?logo=gnubash&logoColor=white)
![Plataforma](https://img.shields.io/badge/plataforma-Linux-FCC624?logo=linux&logoColor=black)
![ShellCheck](https://img.shields.io/badge/lint-ShellCheck-blue)

Scripts em Bash para provisionar, validar e remover de forma **automatizada, idempotente e testável** toda a estrutura de usuários, grupos de departamentos, diretórios compartilhados e permissões de um servidor Linux. Projeto desenvolvido durante o curso de Linux da [DIO.me](https://dio.me).

---

## 📑 Sumário

- [Visão geral](#-visão-geral)
- [Arquitetura de diretórios e permissões](#-arquitetura-de-diretórios-e-permissões)
- [Usuários e grupos](#-usuários-e-grupos)
- [Estrutura do repositório](#-estrutura-do-repositório)
- [Pré-requisitos](#-pré-requisitos)
- [Passo a passo de execução](#-passo-a-passo-de-execução)
- [Testes automatizados](#-testes-automatizados)
- [Boas práticas aplicadas](#-boas-práticas-aplicadas)
- [Personalização](#-personalização)
- [Solução de problemas](#-solução-de-problemas)
- [Autor](#-autor)

---

## 🔭 Visão geral

```text
                ┌───────────────┐
                │  config.sh    │  ← fonte única da verdade (dirs, grupos, usuários, modos)
                └──────┬────────┘
        ┌──────────────┼──────────────────┐
        ▼              ▼                  ▼
  ┌───────────┐  ┌─────────────┐  ┌──────────────────┐
  │ iac1.sh   │  │ test_iac.sh │  │ excluir_infra.sh │
  │ provisiona│  │ valida      │  │ remove tudo      │
  └───────────┘  └─────────────┘  └──────────────────┘
```

O fluxo típico é **provisionar → testar → (opcional) remover → testar ausência**.

## 🗂 Arquitetura de diretórios e permissões

| Diretório  | Dono   | Grupo     | Modo (octal) | Modo (simbólico) | Quem tem acesso                                   |
|------------|--------|-----------|:------------:|------------------|---------------------------------------------------|
| `/publico` | `root` | `root`    | `777`        | `rwxrwxrwx`      | Todos os usuários do sistema (leitura e escrita)  |
| `/adm`     | `root` | `GRP_ADM` | `770`        | `rwxrwx---`      | Somente `root` e membros do departamento ADM      |
| `/ven`     | `root` | `GRP_VEN` | `770`        | `rwxrwx---`      | Somente `root` e membros do departamento VEN      |
| `/sec`     | `root` | `GRP_SEC` | `770`        | `rwxrwx---`      | Somente `root` e membros do departamento SEC      |

**Como ler o modo `770`:** dono (`7` = leitura+escrita+execução), grupo (`7` = idem), outros (`0` = nenhum acesso — nem listar o conteúdo).

## 👥 Usuários e grupos

| Grupo     | Departamento   | Usuários                         | Diretório com acesso |
|-----------|----------------|----------------------------------|----------------------|
| `GRP_ADM` | Administrativo | `carlos`, `maria`, `joao`        | `/adm`, `/publico`   |
| `GRP_VEN` | Vendas         | `debora`, `sebastiana`, `roberto`| `/ven`, `/publico`   |
| `GRP_SEC` | Secretariado   | `josefina`, `amanda`, `rogerio`  | `/sec`, `/publico`   |

Todos os usuários são criados com diretório home (`-m`), shell `/bin/bash` (`-s`) e o grupo do departamento como **grupo primário** (`-g`).

> ⚠️ Os usuários são criados **sem senha** (conta bloqueada para login por senha). Defina uma com `sudo passwd <usuario>` se necessário.

## 📁 Estrutura do repositório

| Arquivo            | Descrição                                                                                  |
|--------------------|--------------------------------------------------------------------------------------------|
| `config.sh`        | Configuração compartilhada (diretórios, grupos, usuários, modos) e funções de log/cores.  |
| `iac1.sh`          | Provisiona diretórios, grupos, usuários, `chown` e `chmod`. Idempotente.                   |
| `test_iac.sh`      | Testes automatizados: existência, donos, permissões, grupos, usuários e acesso efetivo.    |
| `excluir_infra.sh` | Remove tudo o que foi criado (com confirmação). Idempotente.                               |

## ✅ Pré-requisitos

| Requisito             | Detalhes                                                                                     |
|-----------------------|----------------------------------------------------------------------------------------------|
| Sistema operacional   | Distribuição Linux (testado no **Ubuntu 24.04 LTS**; compatível com Debian, RHEL, Fedora etc.) |
| Shell                 | **Bash 4.0+** (necessário para arrays associativos) — verifique com `bash --version`         |
| Privilégios           | Acesso **root** ou `sudo`                                                                    |
| Utilitários           | `useradd`, `usermod`, `userdel`, `groupadd`, `groupdel` (pacote `passwd`/`shadow-utils`), `getent`, `stat`, `su` |
| Opcional              | [`shellcheck`](https://www.shellcheck.net/) para análise estática dos scripts               |

> 💡 **Recomendação:** execute em uma VM, container ou ambiente de laboratório. Os scripts criam diretórios na raiz (`/`) e o script de exclusão **apaga** esses diretórios e os homes dos usuários.

## 🚀 Passo a passo de execução

**1. Clone o repositório**

```bash
git clone https://github.com/M3NT41H34D/linux-projeto1-iac.git
cd linux-projeto1-iac
```

**2. Dê permissão de execução aos scripts**

```bash
chmod +x iac1.sh test_iac.sh excluir_infra.sh
```

**3. Provisione a infraestrutura**

```bash
sudo ./iac1.sh
```

Cada etapa exibe `[OK]` (item criado/ajustado) ou `[SKIP]` (já existia). O script pode ser executado novamente a qualquer momento: ele corrige desvios (por exemplo, um `chmod` alterado manualmente) sem gerar erros.

**4. Valide com os testes automatizados**

```bash
sudo ./test_iac.sh
```

**5. (Opcional) Remova toda a infraestrutura**

```bash
sudo ./excluir_infra.sh          # pede confirmação interativa
sudo ./excluir_infra.sh --yes    # sem confirmação (CI / automação)
sudo ./test_iac.sh --absent      # confirma que tudo foi removido
```

## 🧪 Testes automatizados

O `test_iac.sh` não altera o sistema (apenas cria e remove arquivos temporários durante os testes de acesso) e retorna **código de saída `0`** em caso de sucesso ou **`1`** se algum teste falhar — pronto para uso em pipelines de CI.

| Categoria                  | O que é verificado                                                                      |
|----------------------------|-----------------------------------------------------------------------------------------|
| Diretórios                 | Existência de `/publico`, `/adm`, `/ven`, `/sec`                                        |
| `chown`                    | Dono (`root`) e grupo esperado de cada diretório                                        |
| `chmod`                    | Modo octal (`777` / `770`) de cada diretório                                            |
| Grupos                     | Existência de `GRP_ADM`, `GRP_VEN`, `GRP_SEC`                                           |
| Usuários                   | Existência, grupo primário correto, shell `/bin/bash` e diretório home                  |
| Acesso efetivo *(root)*    | Cada usuário **consegue** escrever em `/publico` e no diretório do seu grupo, e é **bloqueado** nos diretórios dos outros grupos |
| Modo `--absent`            | Diretórios, grupos, usuários e homes foram removidos                                    |

Exemplo de saída:

```text
=== Testes da infraestrutura (modo: present) ===
==> Diretórios, donos e permissões (chown/chmod)
    [PASS] Diretório /adm existe
    [PASS] /adm dono = root
    [PASS] /adm grupo = GRP_ADM
    [PASS] /adm permissão = 770
...
==> Controle de acesso efetivo (escrita como cada usuário)
    [PASS] carlos pode escrever em /adm
    [PASS] carlos bloqueado em /sec
...
Resumo: 82 passaram, 0 falharam, 0 ignorados
RESULTADO: SUCESSO
```

Sem root, os testes de acesso efetivo são marcados como `[SKIP]` e os demais continuam sendo executados.

**Ciclo completo de validação:**

```bash
sudo ./iac1.sh && sudo ./iac1.sh \
  && sudo ./test_iac.sh \
  && sudo ./excluir_infra.sh --yes \
  && sudo ./test_iac.sh --absent
```

**Análise estática (opcional):**

```bash
shellcheck -x iac1.sh excluir_infra.sh test_iac.sh config.sh
```

## 🛡 Boas práticas aplicadas

| Prática                    | Implementação                                                                                    |
|----------------------------|--------------------------------------------------------------------------------------------------|
| Tratamento de erros        | `set -Eeuo pipefail` + `trap ERR` que informa linha e comando que falhou                         |
| Verificação de root        | `require_root` interrompe com mensagem clara se `EUID != 0`                                      |
| Idempotência               | Checagens com `getent group`, `id` e `[[ -d ]]` antes de criar/remover; `usermod` garante convergência de usuários existentes |
| Mensagens claras           | Saída colorida (`[OK]`, `[SKIP]`, `[ERRO]`), desativada automaticamente fora de terminal ou com `NO_COLOR=1` |
| Fonte única da verdade     | `config.sh` compartilhado por criação, exclusão e testes                                         |
| Operações destrutivas      | `excluir_infra.sh` exige confirmação interativa ou `--yes`                                       |
| Qualidade                  | Todos os scripts passam no `shellcheck` sem avisos                                               |

## ⚙ Personalização

Para adicionar um departamento, usuário ou alterar permissões, edite **apenas** o `config.sh`:

```bash
declare -A DIR_GROUP=(
    [/adm]="GRP_ADM"
    [/ven]="GRP_VEN"
    [/sec]="GRP_SEC"
    [/ti]="GRP_TI"          # novo diretório
)

declare -A USER_GROUP=(
    # ...
    [ana]="GRP_TI"          # novo usuário
)

readonly GROUPS_LIST=("GRP_ADM" "GRP_VEN" "GRP_SEC" "GRP_TI")
```

Os três scripts passam a considerar a nova configuração automaticamente.

## 🩺 Solução de problemas

| Sintoma                                                  | Causa / solução                                                         |
|----------------------------------------------------------|-------------------------------------------------------------------------|
| `[ERRO] Este script precisa ser executado como root`     | Execute com `sudo`.                                                     |
| `declare: -A: invalid option`                            | Bash anterior à versão 4 (ex.: macOS). Use uma distribuição Linux.      |
| `Execução não interativa: use '--yes'`                   | `excluir_infra.sh` rodando sem terminal; adicione `--yes`.             |
| Testes de acesso aparecem como `[SKIP]`                  | `test_iac.sh` foi executado sem root; use `sudo ./test_iac.sh`.        |
| `test_iac.sh` reporta `[FAIL]`                           | Rode `sudo ./iac1.sh` novamente para convergir o estado e teste de novo. |

---

## 👤 Autor

**Douglas D’Alcântara Guanaes**
* GitHub: [M3NT41H34D](https://github.com/M3NT41H34D)
