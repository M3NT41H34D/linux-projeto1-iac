#!/bin/bash
#
# iac1.sh - Provisiona diretórios, grupos, usuários e permissões.
# Idempotente: pode ser executado várias vezes sem erro e sempre converge
# o sistema para o estado definido em config.sh.

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=config.sh
source "${SCRIPT_DIR}/config.sh"

trap 'log_error "Falha na linha ${LINENO}: \"${BASH_COMMAND}\" (código $?)"' ERR

require_root

echo "${C_BOLD}=== Iniciando a criação da infraestrutura de usuários ===${C_RESET}"

log_step "1. Criando diretórios públicos e restritos..."
for dir in "${PUBLIC_DIR}" $(printf '%s\n' "${!DIR_GROUP[@]}" | sort); do
    if [[ -d "${dir}" ]]; then
        log_skip "Diretório ${dir} já existe"
    else
        mkdir -p "${dir}"
        log_info "Diretório ${dir} criado"
    fi
done

log_step "2. Criando grupos de usuários..."
for group in "${GROUPS_LIST[@]}"; do
    if getent group "${group}" >/dev/null; then
        log_skip "Grupo ${group} já existe"
    else
        groupadd "${group}"
        log_info "Grupo ${group} criado"
    fi
done

log_step "3. Criando usuários e associando aos seus respectivos grupos..."
# -m cria o home, -s define o shell e -g define o grupo primário.
for user in $(printf '%s\n' "${!USER_GROUP[@]}" | sort); do
    group="${USER_GROUP[${user}]}"
    if id "${user}" &>/dev/null; then
        # Garante a convergência caso o usuário exista com grupo/shell diferentes.
        usermod -g "${group}" -s "${USER_SHELL}" "${user}"
        log_skip "Usuário ${user} já existe (grupo ${group} e shell garantidos)"
    else
        useradd "${user}" -m -s "${USER_SHELL}" -g "${group}"
        log_info "Usuário ${user} criado no grupo ${group}"
    fi
done

log_step "4. Definindo os donos e grupos dos diretórios (chown)..."
chown root:root "${PUBLIC_DIR}"
log_info "${PUBLIC_DIR} -> root:root"
for dir in $(printf '%s\n' "${!DIR_GROUP[@]}" | sort); do
    chown "root:${DIR_GROUP[${dir}]}" "${dir}"
    log_info "${dir} -> root:${DIR_GROUP[${dir}]}"
done

log_step "5. Ajustando as permissões de acesso (chmod)..."
chmod "${PUBLIC_MODE}" "${PUBLIC_DIR}"
log_info "${PUBLIC_DIR} -> ${PUBLIC_MODE} (rwxrwxrwx)"
for dir in $(printf '%s\n' "${!DIR_GROUP[@]}" | sort); do
    chmod "${RESTRICTED_MODE}" "${dir}"
    log_info "${dir} -> ${RESTRICTED_MODE} (rwxrwx---)"
done

echo "${C_GREEN}${C_BOLD}=== Infraestrutura criada com sucesso! ===${C_RESET}"
echo "Valide com: sudo ./test_iac.sh"
