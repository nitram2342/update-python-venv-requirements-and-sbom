#!/bin/sh

# This script can be used to update python virtualenvs, the requirements.txt and SBOMS in a single run.
# It should not be used in a hostile environment, where you operate on files and directories that
# can be controlled by other (unprivileged) users. Otherwise an attack may remove files, redirect
# you with symlinks to cause unwanted effects.

set -e

BASE_DIR=$1
CYCLONEDX_BOM_TOOL=~/.local/bin/cyclonedx-py

if [ -z "${BASE_DIR}" ] ; then
    echo "No base directory directory supplied. That is the directory that contains the VENV/virtualenv/venv dir. Stopping here."
    exit 1
fi

if [ ! -d "${BASE_DIR}" ] ; then
    echo "Base directory does not exists. Stopping here."
    exit 1
fi

if [ ! -f "${CYCLONEDX_BOM_TOOL}" ] ; then
    echo "Tool ${CYCLONEDX_BOM_TOOL} not found. Please install https://github.com/CycloneDX/cyclonedx-python. Stopping here."
    exit 1
fi

for TEST_VENV_DIR in "${BASE_DIR}/VENV" "${BASE_DIR}/venv" "${BASE_DIR}/ENV" "${BASE_DIR}/virtualenv"; do
    if [ -d "${TEST_VENV_DIR}" ]; then
        VENV_DIR=${TEST_VENV_DIR}
        break
    fi
done

if [ ! -d "${VENV_DIR}" ] ; then
    echo "VENV directory does not exists or was not found. Stopping here."
    exit 1
fi

echo "Found VENV directory ${VENV_DIR}."
. ${VENV_DIR}/bin/activate

echo "------------------------------------"
echo "Updating VENV directory."
pip freeze | cut -d'=' -f1 | xargs -n1 pip install -U
echo "------------------------------------"
echo "Updating requirements.txt."
pip freeze > ${BASE_DIR}/requirements.txt.new
echo "------------------------------------"
echo "Generating new SBOM file"
${CYCLONEDX_BOM_TOOL} requirements ${BASE_DIR}/requirements.txt.new -o ${BASE_DIR}/cyclonedx-sbom.xml.new

echo "------------------------------------"
echo Done. Now, please run:
echo mv ${BASE_DIR}/requirements.txt.new ${BASE_DIR}/requirements.txt
echo mv ${BASE_DIR}/cyclonedx-sbom.xml.new ${BASE_DIR}/cyclonedx-sbom.xml
