#!/usr/bin/env bash
set -euo pipefail

REMOTE="devops.local"
REMOTE_DIR="/var/www/devops-site"
SITE_URL="https://devops.local"
CA_CERT="${HOME}/devops.crt"
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
LOCAL_DIR="${REPO_ROOT}/site/"

DRY_RUN=""
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN="--dry-run"
fi

if [[ ! -f "${LOCAL_DIR}index.html" ]]; then
    echo "Ошибка: Файл ${LOCAL_DIR}index.html не найден!" >&2
    exit 1
fi

rsync -avz --delete \
    -e "ssh -i ${HOME}/.ssh/devops_vm -p 2222 -o BatchMode=yes -o ConnectTimeout=5" \
    $DRY_RUN "${LOCAL_DIR}" "devops@${REMOTE}:${REMOTE_DIR}/"

if [[ -n "$DRY_RUN" ]]; then
    echo "План синхронизации успешно сформирован (--dry-run)."
    exit 0
fi

if ! curl -fsS --cacert "$CA_CERT" -o /dev/null "$SITE_URL"; then
    echo "Ошибка: Сайт недоступен или ошибка TLS!" >&2
    exit 1
fi

COMMIT_HASH="$(git rev-parse --short HEAD 2>/dev/null || echo 'manual-run')"
echo "Деплой успешно завершен. Версия коммита: $COMMIT_HASH"
exit 0
