# Function to go up multiple directories based on the number of dots used
up() {
  local count=${#1} # Get the number of dots in the argument
  local path=""
  for ((i = 1; i <= count; i++)); do
    path+="../"
  done
  cd "$path" || return 1 # Navigate up, or return if the path is invalid
}
