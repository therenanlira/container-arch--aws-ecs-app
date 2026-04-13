#!/bin/bash

burn_cpu() {
  while true; do
    curl "http://linuxtips-ecscluster--alb-1260780213.us-east-1.elb.amazonaws.com/burn/cpu" -H "chip.linuxtips.demo" -1;
    echo
  done
}

case $1 in
  "--burn")
    burn_cpu
  ;;
esac
