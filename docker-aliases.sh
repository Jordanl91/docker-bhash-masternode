#!/bin/bash

function docker_alias() {
    docker exec $1 gosu $2 $3
}
# bhash
alias bhashdrestart="docker_alias greerso/bhashd bhash systemctl restart bhashd"
alias bhash-cli="docker_alias greerso/bhashd bhash /usr/local/bin/bhash-cli"