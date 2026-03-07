# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability in Quanitya, please report it responsibly. **Do not open a public GitHub issue.**

Instead, please email: **security@quanitya.com**

Include:
- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

## Response Timeline

- **Acknowledgment**: Within 48 hours
- **Initial assessment**: Within 1 week
- **Fix timeline**: Depends on severity, but we aim for:
  - Critical: 72 hours
  - High: 1 week
  - Medium: 2 weeks
  - Low: Next release

## Scope

The following are in scope:
- E2EE implementation (encryption, key management, key derivation)
- Authentication and authorization (AnonAccred, device keys)
- Server-side data handling (sync endpoints, storage)
- Data leakage (plaintext PII reaching the server)
- Dependency vulnerabilities

The following are out of scope:
- Vulnerabilities in third-party services (PowerSync, OpenRouter, etc.)
- Social engineering
- Denial of service

## Supported Versions

We provide security updates for the latest release only.

## Acknowledgments

We appreciate responsible disclosure and will credit reporters (with permission) in release notes.
