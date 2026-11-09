#!/bin/bash
#
# test_iac.sh - Valida a infraestrutura provisionada por iac1.sh.
#
# Uso:
#   sudo ./test_iac.sh            # valida que a infraestrutura EXISTE e está correta
#   sudo ./test_iac.sh --absent   # valida que excluir_infra.sh removeu tudo
#
# Código de saída: 0 se todos os testes passarem, 1 caso contrário.

set -uo pipefail  # sem -e: cada verificação registra a falha e o script continua

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=config.sh
source "${SCRIPT_DIR}/config.sh"

MODE="present"
case "${1:-}" in
    "") ;;
    --absent) MODE="absent" ;;
    -h|--help) sed -n '3,9p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) log_error "Opção inválida: $1 (use --absent ou --help)"; exit 1 ;;
esac

PASS=0
FAIL=0
SKIP=0

pass() { PASS=$((PASS + 1)); echo "    ${C_GREEN}[PASS]${C_RESET} $*"; }
fail() { FAIL=$((FAIL + 1)); echo "    ${C_RED}[FAIL]${C_RESET} $*"; }
skip() { SKIP=$((SKIP + 1)); echo "    ${C_YELLOW}[SKIP]${C_RESET} $*"; }

# assert_eq <descrição> <esperado> <obtido>
assert_eq() {
    if [[ "$2" == "$3" ]]; then
        pass "$1 = $2"
    else
        fail "$1: esperado '$2', obtido '$3'"
    fi
}

# check_dir <diretório> <dono> <grupo> <modo>
check_dir() {
    local dir="$1" owner="$2" group="$3" mode="$4"
    if [[ ! -d "${dir}" ]]; then
        fail "Diretório ${dir} não existe"
        return
    fi
    pass "Diretório ${dir} existe"
    assert_eq "${dir} dono"      "${owner}" "$(stat -c '%U' "${dir}")"
    assert_eq "${dir} grupo"     "${group}" "$(stat -c '%G' "${dir}")"
    assert_eq "${dir} permissão" "${mode}"  "$(stat -c '%a' "${dir}")"
}

# can_access <usuário> <diretório>: tenta criar e remover um arquivo como o usuário.
can_access() {
    local probe="$2/.test_iac_$$_$1"
    su -s /bin/bash "$1" -c "touch '${probe}' && rm -f '${probe}'" &>/dev/null
}

test_present() {
    log_step "Diretórios, donos e permissões (chown/chmod)"
    check_dir "${PUBLIC_DIR}" "root" "root" "${PUBLIC_MODE}"
    for dir in $(printf '%s\n' "${!DIR_GROUP[@]}" | sort); do
        check_dir "${dir}" "root" "${DIR_GROUP[${dir}]}" "${RESTRICTED_MODE}"
    done

    log_step "Grupos de usuários"
    for group in "${GROUPS_LIST[@]}"; do
        if getent group "${group}" >/dev/null; then
            pass "Grupo ${group} existe"
        else
            fail "Grupo ${group} não existe"
        fi
    done

    log_step "Usuários (grupo primário, shell e diretório home)"
    for user in $(printf '%s\n' "${!USER_GROUP[@]}" | sort); do
        if ! id "${user}" &>/dev/null; then
            fail "Usuário ${user} não existe"
            continue
        fi
        assert_eq "${user} grupo primário" "${USER_GROUP[${user}]}" "$(id -gn "${user}")"
        local entry home
        entry="$(getent passwd "${user}")"
        assert_eq "${user} shell" "${USER_SHELL}" "$(cut -d: -f7 <<<"${entry}")"
        home="$(cut -d: -f6 <<<"${entry}")"
        if [[ -d "${home}" ]]; then
            pass "${user} home ${home} existe"
        else
            fail "${user} home ${home} não existe"
        fi
    done

    log_step "Controle de acesso efetivo (escrita como cada usuário)"
    if [[ "${EUID}" -ne 0 ]]; then
        skip "Testes de acesso exigem root (su); execute com sudo para incluí-los"
        return
    fi
    for user in $(printf '%s\n' "${!USER_GROUP[@]}" | sort); do
        id "${user}" &>/dev/null || continue
        if can_access "${user}" "${PUBLIC_DIR}"; then
            pass "${user} pode escrever em ${PUBLIC_DIR}"
        else
            fail "${user} deveria poder escrever em ${PUBLIC_DIR}"
        fi
        for dir in $(printf '%s\n' "${!DIR_GROUP[@]}" | sort); do
            [[ -d "${dir}" ]] || continue
            if [[ "${DIR_GROUP[${dir}]}" == "${USER_GROUP[${user}]}" ]]; then
                if can_access "${user}" "${dir}"; then
                    pass "${user} pode escrever em ${dir}"
                else
                    fail "${user} deveria poder escrever em ${dir}"
                fi
            else
                if can_access "${user}" "${dir}"; then
                    fail "${user} NÃO deveria acessar ${dir}"
                else
                    pass "${user} bloqueado em ${dir}"
                fi
            fi
        done
    done
}

test_absent() {
    log_step "Diretórios removidos"
    for dir in "${PUBLIC_DIR}" $(printf '%s\n' "${!DIR_GROUP[@]}" | sort); do
        if [[ -e "${dir}" ]]; then fail "${dir} ainda existe"; else pass "${dir} removido"; fi
    done

    log_step "Grupos removidos"
    for group in "${GROUPS_LIST[@]}"; do
        if getent group "${group}" >/dev/null; then fail "Grupo ${group} ainda existe"; else pass "Grupo ${group} removido"; fi
    done

    log_step "Usuários removidos"
    for user in $(printf '%s\n' "${!USER_GROUP[@]}" | sort); do
        if id "${user}" &>/dev/null; then fail "Usuário ${user} ainda existe"; else pass "Usuário ${user} removido"; fi
        if [[ -e "/home/${user}" ]]; then fail "/home/${user} ainda existe"; else pass "/home/${user} removido"; fi
    done
}

echo "${C_BOLD}=== Testes da infraestrutura (modo: ${MODE}) ===${C_RESET}"
if [[ "${MODE}" == "present" ]]; then test_present; else test_absent; fi

echo
echo "${C_BOLD}Resumo:${C_RESET} ${C_GREEN}${PASS} passaram${C_RESET}, ${C_RED}${FAIL} falharam${C_RESET}, ${C_YELLOW}${SKIP} ignorados${C_RESET}"
if [[ "${FAIL}" -gt 0 ]]; then
    echo "${C_RED}${C_BOLD}RESULTADO: FALHOU${C_RESET}"
    exit 1
fi
echo "${C_GREEN}${C_BOLD}RESULTADO: SUCESSO${C_RESET}"
