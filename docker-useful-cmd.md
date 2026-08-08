# Docker cmds

## Lists volumes and sizes based on provided predicate.
docker system df -v | awk '/lemonade/,/^$/'

## Manage permissions

docker exec -it opencode-agent id
