#!/bin/zsh

function create_files() {
  local num_files=$1
  for ((i=1; i<=num_files; i++)); do
    echo "Creating file $i"
    curl -X POST app.linuxtips.demo/arquivos -d 'vaaai!!!'
    echo ""
  done
}

function get_files() {
  curl -s app.linuxtips.demo/arquivos | jq
}

function delete_files() {
  curl -s app.linuxtips.demo/arquivos | jq -r '.files[]' | while read -r file; do
    echo "Deleting file $file"
    curl -X DELETE "app.linuxtips.demo/delete/$file"
    echo ""
  done
}

case $1 in
  --create|-c)
    create_files $2
    exit 0
    ;;
  --get|-g)
    get_files
    exit 0
    ;;
  --delete|-d)
    delete_files
    exit 0
    ;;
  *)
    echo "Invalid option"
    exit 1
    ;;
esac