#!/bin/bash

# Run server with HTTPS using self-signed certificate
python3 server.py config.json --cert server.crt --key server.key