# Load .env file into shell session for environment variables
function envup() {
  if [ -f .env ]; then
    while read -r line; do
      if [[ ! "$line" =~ ^[[:space:]]*# && -n "$line" ]]; then
        export "$line"
      fi
    done < <(sed '/^ *#/d' .env)
    echo "Loaded environment variables from .env"
  else
    echo 'No .env file found' >&2
    return 1
  fi
}
