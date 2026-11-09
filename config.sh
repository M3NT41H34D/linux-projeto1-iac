#!/bin/bash
# Configuração compartilhada da infraestrutura.
# Este arquivo é carregado (source) por iac1.sh, excluir_infra.sh e test_iac.sh,
# garantindo que criação, limpeza e testes usem exatamente a mesma definição.

# shellcheck disable=SC2034  # variáveis usadas pelos scripts que fazem source

# Diretório público: acesso total para todos.
readonly PUBLIC_DIR="/publico"
readonly PUBLIC_MODE="777"

# Diretórios restritos: diretório -> grupo dono (modo 770, dono root).
readonly RESTRICTED_MODE="770"
declare -A DIR_GROUP=(
    [/adm]="GRP_ADM"
    [/ven]="GRP_VEN"
    [/sec]="GRP_SEC"
)

# Usuários: usuário -> grupo primário.
declare -A USER_GROUP=(
    [carlos]="GRP_ADM"
    [maria]="GRP_ADM"
    [joao]="GRP_ADM"
    [debora]="GRP_VEN"
    [sebastiana]="GRP_VEN"
    [roberto]="GRP_VEN"
    [josefina]="GRP_SEC"
    [amanda]="GRP_SEC"
    [rogerio]="GRP_SEC"
)

readonly GROUPS_LIST=("GRP_ADM" "GRP_VEN" "GRP_SEC")
readonly USER_SHELL="/bin/bash"

# ---------------------------------------------------------------------------
# Saída colorida (desativada quando a saída não é um terminal ou NO_COLOR=1)
# ---------------------------------------------------------------------------
if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
    C_RED=$'\e[31m'; C_GREEN=$'\e[32m'; C_YELLOW=$'\e[33m'
    C_BLUE=$'\e[34m'; C_BOLD=$'\e[1m'; C_RESET=$'\e[0m'
else
    C_RED=""; C_GREEN=""; C_YELLOW=""; C_BLUE=""; C_BOLD=""; C_RESET=""
fi

log_step()  { echo "${C_BOLD}${C_BLUE}==>${C_RESET} ${C_BOLD}$*${C_RESET}"; }
log_info()  { echo "    ${C_GREEN}[OK]${C_RESET} $*"; }
log_skip()  { echo "    ${C_YELLOW}[SKIP]${C_RESET} $*"; }
log_warn()  { echo "    ${C_YELLOW}[AVISO]${C_RESET} $*" >&2; }
log_error() { echo "${C_RED}[ERRO]${C_RESET} $*" >&2; }

require_root() {
    if [[ "${EUID}" -ne 0 ]]; then
        log_error "Este script precisa ser executado como root. Use: sudo $0"
        exit 1
    fi
}
