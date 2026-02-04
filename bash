.github/workflows/sign.yml
name: Sign Apple Wallet Pass

on:
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Install tools
        run: sudo apt-get update && sudo apt-get install -y zip openssl

      - name: Create manifest.json
        run: |
          find . -type f ! -name manifest.json ! -path "./.git/*" ! -path "./.github/*" -exec openssl sha1 {} \; \
          | sed 's#SHA1(./##;s#)= #": "#;s#$#"#' \
          | sed '1s/^/{\n/;$s/$/\n}/' > manifest.json

      - name: Create signing certificate
        run: |
          openssl req -x509 -newkey rsa:2048 -keyout key.pem -out cert.pem -days 365 -nodes -subj "/CN=Wallet Pass"

      - name: Sign manifest
        run: |
          openssl smime -binary -sign -certfile cert.pem -signer cert.pem -inkey key.pem -in manifest.json -out signature -outform DER

      - name: Build pkpass
        run: |
          zip -r RPASPass.pkpass pass.json background.png icon.png logo.png manifest.json signature
