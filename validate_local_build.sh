#!/bin/sh

set -eu

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
cd "$repo_dir"

venv_dir=${VENV_DIR:-$repo_dir/.venv-validate}
python_bin=${PYTHON_BIN:-python3}

"$python_bin" -m venv "$venv_dir"
. "$venv_dir/bin/activate"

python -m pip install --upgrade pip
python -m pip install -r requirements.txt
python -m compileall application.py request_manager.py server.py views.py yaml_to_json.py
bash -n run.sh patch_auth_server_local.sh

printf 'Validated auth server dependencies in %s\n' "$venv_dir"