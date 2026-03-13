#!/bin/bash
# PowerSync JWK Key Generation Script
# Simplified from cloud's .deployment/scripts/setup_jwk.sh
# Generates RSA JWK keys and writes them to .jwk (same format as cloud production)
# Requires: openssl, python3 (with cryptography library)
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SERVER_DIR="$(dirname "$SCRIPT_DIR")"
cd "$SERVER_DIR"

JWK_FILE=".jwk"
TEMP_DIR="$(mktemp -d)"
trap "rm -rf $TEMP_DIR" EXIT

echo "Generating RSA key pair..."
openssl genrsa -out "$TEMP_DIR/private.pem" 2048 2>/dev/null

PS_JWK_KID="quanitya-$(date +%s)"

# Ensure cryptography library is available
if ! python3 -c "import cryptography" >/dev/null 2>&1; then
    echo "Installing cryptography library in venv..."
    python3 -m venv "$TEMP_DIR/venv"
    source "$TEMP_DIR/venv/bin/activate"
    pip install cryptography --quiet 2>/dev/null || {
        echo "ERROR: pip install cryptography failed."
        echo "Install manually: python3 -m pip install cryptography"
        exit 1
    }
fi

echo "Converting RSA keys to JWK format..."

# Extract JWK components — same approach as cloud's setup_jwk.sh
export TEMP_DIR PS_JWK_KID
JWK_OUTPUT=$(python3 << 'PYEOF'
import json, base64, os
from cryptography.hazmat.primitives import serialization

def int_to_base64url(value):
    byte_length = (value.bit_length() + 7) // 8
    if byte_length == 0:
        byte_length = 1
    return base64.urlsafe_b64encode(value.to_bytes(byte_length, 'big')).decode('ascii').rstrip('=')

with open(f'{os.environ["TEMP_DIR"]}/private.pem', 'rb') as f:
    key = serialization.load_pem_private_key(f.read(), password=None)

pn = key.private_numbers()
kid = os.environ['PS_JWK_KID']

private_jwk = {
    'kty': 'RSA',
    'n': int_to_base64url(pn.public_numbers.n),
    'e': int_to_base64url(pn.public_numbers.e),
    'd': int_to_base64url(pn.d),
    'p': int_to_base64url(pn.p),
    'q': int_to_base64url(pn.q),
    'dp': int_to_base64url(pn.dmp1),
    'dq': int_to_base64url(pn.dmq1),
    'qi': int_to_base64url(pn.iqmp),
    'kid': kid,
    'alg': 'RS256',
    'use': 'sig',
    'key_ops': ['sign'],
}

print(json.dumps({
    'private_jwk_b64': base64.b64encode(json.dumps(private_jwk).encode()).decode(),
    'n': private_jwk['n'],
    'e': private_jwk['e'],
    'kid': kid,
}))
PYEOF
)

PRIVATE_KEY_JWK=$(echo "$JWK_OUTPUT" | python3 -c "import sys,json; print(json.load(sys.stdin)['private_jwk_b64'])")
PS_JWK_N=$(echo "$JWK_OUTPUT" | python3 -c "import sys,json; print(json.load(sys.stdin)['n'])")
PS_JWK_E=$(echo "$JWK_OUTPUT" | python3 -c "import sys,json; print(json.load(sys.stdin)['e'])")

# Validate
if [ -z "$PRIVATE_KEY_JWK" ] || [ -z "$PS_JWK_N" ] || [ -z "$PS_JWK_E" ] || [ -z "$PS_JWK_KID" ]; then
    echo "ERROR: Failed to generate JWK values"
    exit 1
fi

# Write .jwk file (same format as cloud production)
cat > "$JWK_FILE" << EOF
# PowerSync JWK Configuration (auto-generated on $(date))
POWERSYNC_JWT_PRIVATE_KEY_JWK=$PRIVATE_KEY_JWK
PS_JWK_N=$PS_JWK_N
PS_JWK_E=$PS_JWK_E
PS_JWK_KID=$PS_JWK_KID
EOF

echo "JWK keys written to $JWK_FILE"
