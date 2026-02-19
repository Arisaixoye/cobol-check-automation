#!/bin/bash
set -euo pipefail

# Convert username to lowercase
LOWERCASE_USERNAME=$(echo "${ZOWE_USERNAME}" | tr '[:upper:]' '[:lower:]')

ZOSMF_HOST="${ZOSMF_HOST}"
ZOSMF_PORT="${ZOSMF_PORT}"

TARGET_DIR="/z/${LOWERCASE_USERNAME}/cobolcheck"

echo "Target USS dir: ${TARGET_DIR}"

# Create directory if it doesn't exist
if ! zowe zos-files list uss-files "${TARGET_DIR}" \
  --host "${ZOSMF_HOST}" --port "${ZOSMF_PORT}" \
  --user "${ZOWE_USERNAME}" --password "${ZOWE_PASSWORD}" \
  --reject-unauthorized false >/dev/null 2>&1; then

  echo "Directory does not exist. Creating it..."
  zowe zos-files create uss-directory "${TARGET_DIR}" \
    --host "${ZOSMF_HOST}" --port "${ZOSMF_PORT}" \
    --user "${ZOWE_USERNAME}" --password "${ZOWE_PASSWORD}" \
    --reject-unauthorized false
else
  echo "Directory already exists."
fi

# Upload files (ajusta el nombre de carpeta local si aplica)
echo "Uploading ./cobol-check -> ${TARGET_DIR}"
zowe zos-files upload dir-to-uss "./cobol-check" "${TARGET_DIR}" \
  --recursive \
  --host "${ZOSMF_HOST}" --port "${ZOSMF_PORT}" \
  --user "${ZOWE_USERNAME}" --password "${ZOWE_PASSWORD}" \
  --reject-unauthorized false

# Verify upload
echo "Verifying upload:"
zowe zos-files list uss-files "${TARGET_DIR}" \
  --host "${ZOSMF_HOST}" --port "${ZOSMF_PORT}" \
  --user "${ZOWE_USERNAME}" --password "${ZOWE_PASSWORD}" \
  --reject-unauthorized false
