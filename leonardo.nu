#!/usr/bin/env nu

let email = "pilsj00@gmail.com"
let socket = "/home/jay/.ssh/leonardo-agent.sock"

print "Starting clean Leonardo SSH agent..."
if ($socket | path exists) {
    rm -f $socket
}

let agent = (ssh-agent -a $socket | lines | parse "{var}={val}; export {var2};")
load-env {
    SSH_AUTH_SOCK: ($agent | where var == "SSH_AUTH_SOCK" | get val | first),
    SSH_AGENT_PID: ($agent | where var == "SSH_AGENT_PID" | get val | first)
}

ssh-add -D | ignore

print "Logging into CINECA CA..."
step ssh login $email --provisioner cineca-hpc

print $"Leonardo agent ready: ($env.SSH_AUTH_SOCK)"
print "Now run: ssh jpils000@login.leonardo.cineca.it"
