set -euo pipefail

MYIP="${MYIP:-192.168.0.110}"
ISSUER_PORT="${ISSUER_PORT:-5002}"
AUTH_PORT="${AUTH_PORT:-5001}"

ISSUER_BASE="https://${MYIP}:${ISSUER_PORT}"
AUTH_BASE="https://${MYIP}:${AUTH_PORT}"

mkdir -p /tmp/oidc_log_dev

python3 - <<PY
import json
from pathlib import Path

p = Path("config.json")
cfg = json.loads(p.read_text())

cfg["port"] = ${AUTH_PORT}
cfg["domain"] = "${MYIP}:${AUTH_PORT}"
cfg["base_url"] = "${AUTH_BASE}"
cfg["authorization_redirect_url"] = "${ISSUER_BASE}/auth_choice"

cfg["op"]["server_info"]["add_ons"]["dpop"]["kwargs"]["allowed_htu"] = [
    f"https://${MYIP}:${AUTH_PORT}/token",
    f"https://${MYIP}:${AUTH_PORT}/oidc/token"
]

cfg["op"]["server_info"]["issuer"] = "https://{domain}"
cfg["webserver"]["port"] = ${AUTH_PORT}
cfg["webserver"]["domain"] = "{domain}"

p.write_text(json.dumps(cfg, indent=2))
print("updated", p)
PY

python3 - <<PY
import json
import re
from pathlib import Path

cfg_path = Path("openid-configuration.json")
cfg = json.loads(cfg_path.read_text())
for key in (
    "issuer",
    "registration_endpoint",
    "introspection_endpoint",
    "authorization_endpoint",
    "token_endpoint",
    "userinfo_endpoint",
    "end_session_endpoint",
    "pushed_authorization_request_endpoint",
    "jwks_uri",
):
    cfg[key] = re.sub(r"^https?://[^/]+", "${AUTH_BASE}", cfg[key])
cfg["token_endpoint_auth_methods_supported"] = [
    "public",
    "attest_jwt_client_auth",
]
cfg["client_attestation_signing_alg_values_supported"] = [
    "ES256",
    "ES384",
    "ES512",
    "RS256",
    "RS384",
    "RS512",
]
cfg["client_attestation_pop_signing_alg_values_supported"] = [
    "ES256",
    "ES384",
    "ES512",
    "RS256",
    "RS384",
    "RS512",
]
cfg_path.write_text(json.dumps(cfg, indent=4))
print("updated", cfg_path)

files = [Path("views.py")]

for f in files:
    text = f.read_text()
    text = text.replace("https://dev.issuer.eudiw.dev/oidc", "${AUTH_BASE}/oidc")
    text = text.replace("https://issuer.eudiw.dev/oidc", "${AUTH_BASE}/oidc")
    text = text.replace("http://192.168.0.110:5000/auth_choice", "${ISSUER_BASE}/auth_choice")
    text = text.replace("http://192.168.0.110:5000/auth_choice", "${ISSUER_BASE}/auth_choice")
    text = text.replace("https://dev.issuer.eudiw.dev/oidc/verify/user", "${AUTH_BASE}/verify/user")
    text = text.replace("http://192.168.0.110:5001/verify/user", "${AUTH_BASE}/verify/user")
    f.write_text(text)
    print("updated", f)
PY

echo
echo "Authorization server patched."
echo "Expected runtime:"
echo "  Auth server: ${AUTH_BASE}"
echo "  Redirect to : ${ISSUER_BASE}/auth_choice"
echo
echo "Start auth server with:"
echo "  ./run.sh"
