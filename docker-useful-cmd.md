## Lists volumes and sizes based on provided predicate.
docker system df -v | awk '/lemonade/,/^$/'