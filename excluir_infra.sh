#!/bin/bash
#
# excluir_infra.sh - Remove tudo o que foi criado por iac1.sh.
# Idempotente: itens inexistentes são ignorados.

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=config.sh
source "${SCRIPT_DIR}/config.sh"

trap 'log_error "Falha na linha ${LINENO}: \"${BASH_COMMAND}\" (código $?)"' ERR

require_root

FORCE=false
if [[ "${1:-}" == "-y" || "${1:-}" == "--yes" ]]; then
    FORCE=true
fi

if [[ "${FORCE}" == false ]]; then
    if [[ ! -t 0 ]]; then
        log_error "Execução não interativa: use '$0 --yes' para confirmar a exclusão."
        exit 1
    fi
    read -r -p "Isto removerá usuários, grupos e diretórios (incluindo seus dados). Continuar? [s/N] " answer
    if [[ ! "${answer}" =~ ^[sSyY]$ ]]; then
        echo "Operação cancelada."
        exit 0
    fi
fi

echo "${C_BOLD}=== Iniciando a exclusão da infraestrutura ===${C_RESET}"

log_step "1. Removendo usuários e seus respectivos diretórios home..."
for user in $(printf '%s\n' "${!USER_GROUP[@]}" | sort); do
    if id "${user}" &>/dev/null; then
        # userdel retorna 12 quando o home/mail spool não existe; o usuário é removido mesmo assim.
        userdel -r -f "${user}" 2>/dev/null || [[ $? -eq 12 ]]
        log_info "Usuário ${user} removido"
    else
        log_skip "Usuário ${user} não existe"
    fi
done

log_step "2. Removendo grupos de usuários..."
for group in "${GROUPS_LIST[@]}"; do
    if getent group "${group}" >/dev/null; then
        groupdel "${group}"
        log_info "Grupo ${group} removido"
    else
        log_skip "Grupo ${group} não existe"
    fi
done

log_step "3. Removendo diretórios criados..."
for dir in "${PUBLIC_DIR}" $(printf '%s\n' "${!DIR_GROUP[@]}" | sort); do
    if [[ -e "${dir}" ]]; then
        rm -rf -- "${dir}"
        log_info "Diretório ${dir} removido"
    else
        log_skip "Diretório ${dir} não existe"
    fi
done

echo "${C_GREEN}${C_BOLD}=== Limpeza concluída com sucesso! ===${C_RESET}"
