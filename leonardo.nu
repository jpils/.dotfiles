#!/usr/bin/env nu

let email = "pilsj00@gmail.com"

if ($env.SSH_AUTH_SOCK? | is-empty) {
    print "Starting a temporary SSH agent..."
    let agent = (ssh-agent | lines | parse "{var}={val}; export {var2};")
    load-env {
        SSH_AUTH_SOCK: ($agent | where var == "SSH_AUTH_SOCK" | get val | first),
        SSH_AGENT_PID: ($agent | where var == "SSH_AGENT_PID" | get val | first)
    }
}

print $"Logging into CINECA CA via ..."
step ssh login $email --provisioner cineca-hpc
