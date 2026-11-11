# RECONX 🔎

**RECONX** is an automated reconnaissance tool developed in Bash, designed to assist security researchers and bug bounty hunters during the information-gathering phase.

The tool integrates popular reconnaissance utilities to automate subdomain enumeration, HTTP status verification, URL collection and endpoint categorization.

### ⚙️ Features

- **Subfinder:** Subdomain enumeration.
- **HTTPX:** HTTP probing and filtering of HTTP 200 responses.
- **GAU:** URL collection from known sources.
- **GREP:** URL filtering based on potentially interesting parameters and file extensions.
- **Sorting:** Removes duplicate entries.
- **Organized Output:** Automatically saves results into categorized files.

### 🛠️ Requirements

- Bash
- Subfinder
- HTTPX (ProjectDiscovery)
- GAU
- GREP

### 📁 Output Structure

```text
Resultado/
├── subs_domain.txt
├── domain_alive_200.txt
├── domain_urls_unicas.txt
└── filtros_domain/
    ├── javascript.txt
    ├── xss.txt
    ├── sqli.txt
    ├── ssrf.txt
    ├── open-redirect.txt
    ├── idor.txt
    ├── lfi-path-traversal.txt
    ├── ssti.txt
    └── info-disclosure.txt
```

### 🎯 Purpose

RECONX was created as a personal project to improve Bash scripting skills and automate reconnaissance workflows for authorized security testing.

### ⚠️ Disclaimer

This tool is intended for educational purposes and authorized security testing only. Always obtain permission and follow the scope and rules of the target program.

**Developed by Gustavo.**
