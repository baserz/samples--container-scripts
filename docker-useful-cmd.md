# Docker cmds

## Lists volumes and sizes based on provided predicate

docker system df -v | awk '/lemonade/,/^$/'

## Execute docker commands

docker exec -it -w /workspace/abc opencode-agent opencode .  // Open folder then start opencode.

### Create alias for it

alias start-opencode='docker exec -it -w /workspace/abc opencode-agent opencode .'

## Manage permissions

docker exec -it opencode-agent id
