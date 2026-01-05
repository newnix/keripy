#!/bin/bash

## XXX: This should at least trap nonzero exits to verify each step completed as expected

## XXX: Set defaults for variables used in this script
SCRIPT_LOCATION="$(readlink -f "${0}")" # This resolves to the path of the script file itself
SCRIPT_DIR="${SCRIPT_LOCATION%/*.sh}" # Remove the basename, leaving only the containing directory
SCRIPT_DIR="${SCRIPT_DIR%/*}" # Remove the last directory portion, leaving the parent directory, expected to be "scripts/demo" inside the repo checkout

KERI_DEMO_SCRIPT_DIR="${KERI_DEMO_SCRIPT_DIR:="${SCRIPT_DIR}"}" # NOTE: Should evaluate to "scripts/demo" in the repo, if not provided prior to execution
KERI_SCRIPT_DIR="${KERI_SCRIPT_DIR:="${KERI_DEMO_SCRIPT_DIR%/*}"}" # NOTE: This should evaluate to the "scripts" dir in the repo, if not provided prior to execution

kli init --name issuer --salt 0ACDEyMzQ1Njc4OWxtbm9aBc --nopasscode --config-dir ${KERI_SCRIPT_DIR} --config-file demo-witness-oobis
kli incept --name issuer --alias issuer --file ${KERI_DEMO_SCRIPT_DIR}/data/gleif-sample.json

## XXX: Creating a second database for "holder"?
kli init --name holder --salt 0ACDEyMzQ1Njc4OWxtbm9qWc --nopasscode --config-dir ${KERI_SCRIPT_DIR} --config-file demo-witness-oobis
kli incept --name holder --alias holder --file ${KERI_DEMO_SCRIPT_DIR}/data/gleif-sample.json

## XXX: Unclear why we need to resolve OOBIs here
## FIXME: Ideally, these should be constructed using variables to hold the identifier strings
kli oobi resolve --name issuer --oobi-alias holder --oobi http://127.0.0.1:5642/oobi/ELjSFdrTdCebJlmvbFNX9-TLhR2PO0_60al1kQp5_e6k/witness/BBilc4-L3tFUnfM_wJr4S4OJanAv_VmF_dJNN6vkf2Ha
kli oobi resolve --name holder --oobi-alias issuer --oobi http://127.0.0.1:5642/oobi/EKxICWTx5Ph4EKq5xie2znZf7amggUn4Sd-2-46MIQTg/witness/BBilc4-L3tFUnfM_wJr4S4OJanAv_VmF_dJNN6vkf2Ha
kli oobi resolve --name issuer --oobi-alias issuer --oobi http://127.0.0.1:7723/oobi/EBfdlu8R27Fbx-ehrqwImnK-8Cm79sqbAQ4MmvEAYqao
kli oobi resolve --name holder --oobi-alias holder --oobi http://127.0.0.1:7723/oobi/EBfdlu8R27Fbx-ehrqwImnK-8Cm79sqbAQ4MmvEAYqao

kli vc registry incept --name issuer --alias issuer --registry-name vLEI

kli vc create --name issuer --alias issuer --registry-name vLEI --schema EBfdlu8R27Fbx-ehrqwImnK-8Cm79sqbAQ4MmvEAYqao --recipient ELjSFdrTdCebJlmvbFNX9-TLhR2PO0_60al1kQp5_e6k --data @${KERI_DEMO_SCRIPT_DIR}/data/credential-data.json
SAID=$(kli vc list --name issuer --alias issuer --issued --said --schema EBfdlu8R27Fbx-ehrqwImnK-8Cm79sqbAQ4MmvEAYqao)

kli ipex grant --name issuer --alias issuer --said "${SAID}" --recipient ELjSFdrTdCebJlmvbFNX9-TLhR2PO0_60al1kQp5_e6k

echo "Checking holder for grant messages..."
GRANT=$(kli ipex list --name holder --alias holder --poll --said)

echo "Admitting credential from grant ${GRANT}"
kli ipex admit --name holder --alias holder --said "${GRANT}"

kli vc list --name holder --alias holder

## FIXME: Forced success exit code masks any failures in unsupervised tests
exit 0

## FIXME: None of the following code actually runs, unclear if it's still necessary
kli vc revoke --name issuer --alias issuer --registry-name vLEI --said "${SAID}"
sleep 2
kli vc list --name holder --alias holder --poll
