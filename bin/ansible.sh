#!/bin/bash
# Single entry point for the Pipenv-wrapped Ansible commands.
#
#   bin/ansible.sh setup                     # install collections (galaxy)
#   bin/ansible.sh play playbooks/site.yml   # run a playbook (any flags pass through)
#
set -e -u -f -o pipefail

cmd="${1:-}"
case "${cmd}" in
  setup)
    pipenv run ansible-galaxy install -r requirements.yml
    ;;
  play)
    shift
    pipenv run ansible-playbook -i inventory.ini "$@"
    ;;
  *)
    echo "usage: bin/ansible.sh {setup | play [ansible-playbook args...]}" >&2
    exit 2
    ;;
esac
