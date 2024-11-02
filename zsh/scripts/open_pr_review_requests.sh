#!/bin/bash

# Originally written for MacOS
gh search prs --review-requested=@me --state=open --archived=false --json url,isDraft --limit=100 |
  jq -r '.[] | select(.isDraft == false) | .url' | {
  read -r first_url
  open -na "Google Chrome" --args --new-window "$first_url"
  while read -r url; do
    open -na "Google Chrome" --args "$url"
  done
}

# #!/bin/bash

# gh search prs --review-requested=@me --state=open --archived=false --json url --limit=100 | jq -r '.[].url' | {
#     read -r first_url
#     open -na "Google Chrome" --args --new-window "$first_url"
#     while read -r url; do
#         open -na "Google Chrome" --args "$url"
#     done
# }
