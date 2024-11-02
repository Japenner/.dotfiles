# Change file extensions recursively in current directory
#
# Usage: change-extension erb haml
function change-extension() {
  for f in **/*.$1; do
    mv "$f" "${f%.$1}.$2"
  done
}
