
#!/bin/bash

# ==========================================
#  CyNeX - AUTOMATED RECONNAISSANCE TOOL
#  Subfinder | HTTPX | GAU | GREP
# ==========================================

# Cores
RESET='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
PURPLE='\033[0;35m'

# Configurações
THREADS=10
OUTPUT_DIR="Resultado"

# ==========================================
# BANNER
# ==========================================

banner() {
    clear

    echo -e "${CYAN}"
    cat << "EOF"

 ██████╗██╗   ██╗███╗   ██╗███████╗██╗  ██╗
██╔════╝╚██╗ ██╔╝████╗  ██║██╔════╝╚██╗██╔╝
██║      ╚████╔╝ ██╔██╗ ██║█████╗   ╚███╔╝ 
██║       ╚██╔╝  ██║╚██╗██║██╔══╝   ██╔██╗ 
╚██████╗   ██║   ██║ ╚████║███████╗██╔╝ ██╗
 ╚═════╝   ╚═╝   ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝

       AUTOMATED RECONNAISSANCE
EOF
    echo -e "${RESET}"

    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${WHITE}  [ CYNEX ]${RESET} ${CYAN}Subdomain & URL Enumeration${RESET}"
    echo -e "${WHITE}  [ AUTHOR ]${RESET} ${GREEN}Gustavo${RESET}"
    echo -e "${WHITE}  [ VERSION]${RESET} ${GREEN}V1.0${RESET}"
    echo -e "${WHITE}  [ TOOLS  ]${RESET} Subfinder | HTTPX | GAU | GREP"
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo ""
}

# ==========================================
# FUNÇÕES VISUAIS
# ==========================================

info() {
    echo -e "${CYAN}[INFO]${RESET} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${RESET} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${RESET} $1"
}

error() {
    echo -e "${RED}[ERROR]${RESET} $1"
}

separator() {
    echo -e "${PURPLE}--------------------------------------------${RESET}"
}

# ==========================================
# VERIFICAR FERRAMENTAS
# ==========================================

check_tools() {

    echo -e "${WHITE}[*] Verificando ferramentas...${RESET}"

    for tool in subfinder httpx gau; do

        if ! command -v "$tool" >/dev/null 2>&1; then
            error "$tool não encontrado."
            exit 1
        fi

        success "$tool encontrado."

    done

    separator
}

# ==========================================
# BUSCAR SUBDOMÍNIOS
# ==========================================

get_subdomains() {

    read -rp "$(echo -e "${CYAN}[?] Domínio autorizado: ${RESET}")" domain

    if [[ -z "$domain" ]]; then
        error "Domínio não informado."
        return 1
    fi

    mkdir -p "$OUTPUT_DIR"

    subs_domain="$OUTPUT_DIR/subs_${domain}.txt"

    info "Executando Subfinder..."

    if ! subfinder -d "$domain" -silent | sort -u > "$subs_domain"; then
        error "Falha na coleta de subdomínios."
        return 1
    fi

    local total
    total=$(wc -l < "$subs_domain")

    success "Subdomínios encontrados: $total"
    success "Arquivo: $subs_domain"
}

# ==========================================
# HTTPX - STATUS CODE 200
# ==========================================

status_code_site() {

    local subs_file="$1"

    read -rp "$(echo -e "${CYAN}[?] Utilizar HTTPX? (s/n): ${RESET}")" resposta

    if [[ "${resposta,,}" != "s" ]]; then
        warning "Verificação HTTPX ignorada."
        return 1
    fi

    read -rp "$(echo -e "${CYAN}[?] Rate Limit (req/s): ${RESET}")" rl

    if ! [[ "$rl" =~ ^[0-9]+$ ]] || (( rl < 1 )); then
        error "Rate Limit inválido."
        return 1
    fi

    alive="$OUTPUT_DIR/${domain}_alive_200.txt"

    info "Executando HTTPX..."

    if ! httpx \
        -l "$subs_file" \
        -H "X-Bug-Bounty: HackerOne-${username}" \
        -silent \
        -mc 200 \
        -rl "$rl" \
        -o "$alive"; then

        error "Falha na execução do HTTPX."
        return 1
    fi

    local total
    total=$(wc -l < "$alive")

    success "Sites HTTP 200: $total"
    success "Arquivo: $alive"

    return 0
}

# ==========================================
# GAU - COLETAR URLS
# ==========================================

get_urls() {

    local input_file="$1"

    urls_output="$OUTPUT_DIR/${domain}_urls_unicas.txt"

    info "Executando GAU..."
    info "Threads: $THREADS"

    if ! gau --threads "$THREADS" < "$input_file" |
        sort -u > "$urls_output"; then

        error "Falha na coleta de URLs."
        return 1
    fi

    local total
    total=$(wc -l < "$urls_output")

    success "URLs coletadas: $total"
    success "Arquivo: $urls_output"
}

# ==========================================
# FILTROS POR VULNERABILIDADE
# ==========================================

filtra_url() {

    local input_file="$1"
    local output_dir="$OUTPUT_DIR/filtros_${domain}"

    if [[ ! -f "$input_file" ]]; then
        error "Arquivo de URLs não encontrado."
        return 1
    fi

    mkdir -p "$output_dir"

    info "Iniciando filtros por vulnerabilidade..."

    # Função auxiliar para os filtros

    filter_file() {

        local pattern="$1"
        local filename="$2"
        local description="$3"

        grep -Ei "$pattern" "$input_file" |
            sort -u > "$output_dir/$filename"

        local total
        total=$(wc -l < "$output_dir/$filename")

        echo -e "${GREEN}[+]${RESET} $description: ${WHITE}$total${RESET}"
    }

    separator

    # JavaScript
    filter_file '\.js([?#]|$)' \
        "javascript.txt" "JavaScript"

    # XSS
    filter_file '[?&](q|query|search|s|keyword|name|message|comment|title|callback|input)='  \
        "xss.txt" "XSS"

    # SQL Injection
    filter_file '[?&](id|user|uid|account|category|product|item|order|filter|sort|search|query)=' \
        "sqli.txt" "SQL Injection"

    # SSRF
    filter_file '[?&](url|uri|host|domain|site|endpoint|webhook|proxy|feed|image|callback|fetch)=' \
        "ssrf.txt" "SSRF"

    # Open Redirect
    filter_file '[?&](redirect|redirect_uri|return|return_url|next|continue|dest|destination|goto|target|callback)=' \
        "open-redirect.txt" "Open Redirect"

    # IDOR / BOLA
    filter_file '[?&](id|uid|user_id|account_id|profile_id|order_id|invoice_id|document_id|file_id|customer_id)=' \
        "idor.txt" "IDOR / BOLA"

    # LFI / Path Traversal
    filter_file '[?&](file|path|folder|directory|template|document|download|include|page|view)=' \
        "lfi-path-traversal.txt" "LFI / Path Traversal"

    # SSTI
    filter_file '[?&](template|name|message|content|title|subject|render|preview)=' \
        "ssti.txt" "SSTI"

    # Information Disclosure
    filter_file '\.(env|log|conf|config|ini|json|xml|sql|bak|old|git|yml|yaml)([?#]|$)' \
        "info-disclosure.txt" "Information Disclosure"

    separator

    success "Todos os filtros foram executados."
    info "Resultados: $output_dir/"
}

# ==========================================
# EXECUÇÃO PRINCIPAL
# ==========================================

main() {

    banner

    # Username
    read -rp "$(echo -e "${CYAN}[?] Username HackerOne: ${RESET}")" username

    if [[ -z "$username" ]]; then
        error "Username não informado."
        exit 1
    fi

    # Verificar ferramentas
    check_tools

    # Subfinder
    get_subdomains || exit 1

    # HTTPX
    if status_code_site "$subs_domain"; then
        input_urls="$alive"
    else
        input_urls="$subs_domain"
    fi

    # GAU
    get_urls "$input_urls" || exit 1

    # GREP
    filtra_url "$urls_output" || exit 1

    # Finalização
    echo ""
    echo -e "${GREEN}"
    cat << "EOF"
 ██████╗██╗   ██╗███╗   ██╗███████╗██╗  ██╗
██╔════╝╚██╗ ██╔╝████╗  ██║██╔════╝╚██╗██╔╝
██║      ╚████╔╝ ██╔██╗ ██║█████╗   ╚███╔╝ 
██║       ╚██╔╝  ██║╚██╗██║██╔══╝   ██╔██╗ 
╚██████╗   ██║   ██║ ╚████║███████╗██╔╝ ██╗
 ╚═════╝   ╚═╝   ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝
EOF
    echo -e "${RESET}"

    success "RECONHECIMENTO FINALIZADO!"

    echo ""
    echo -e "${WHITE}RESUMO DOS RESULTADOS${RESET}"
    separator

    echo -e "${CYAN}Subdomínios:${RESET} $subs_domain"
    echo -e "${CYAN}URLs:${RESET} $urls_output"
    echo -e "${CYAN}Filtros:${RESET} $OUTPUT_DIR/filtros_${domain}/"

    separator

    success "Obrigado por utilizar o CYNESX!"
}

# Iniciar
main
