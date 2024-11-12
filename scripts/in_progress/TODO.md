# Script Ideas

## Github Issue Ticket Builder Script

- Build a Github Issue ticket based off of:
  - The current branch's diff
  - All commits made to the current branch
  - Any other notes pertinent

## System Spec Gathering Script

- Determine system specs
- Pass into openai API for higher quality prompt responses
- Assess the following:
  - package.json
  - Gemfile
- What specs and configurations do I need about the ecosystem I work in to enhance the prompts I give chatgpt?

## Error Remediation Database

- Save issues and their solutions in a personal database that I can reference whenever I run into the same issue again.

## Error Remediation Helper

- Take output from the last command including the command itself
- Feed it to openAI's chatGPT if it is an error
- Paste back or save output as remediation steps to fix error
- Consider making this a manual process

## Branch Refresher Script

- Automatically rebase and merge in all branches which don't have merge conflicts

## Script Builder Prompt

- Prompt to build scripts with certain considerations and design patterns taken into consideration
- Based on modular patterns taken from other scripts generated. For instance, assigning options based upon Ruby OptionsSet (?) class.

## Branch Commit Refactorer

- Takes all changes in current Branch
- Resets to master
- Rebuilds commits in most logical iterations with accurate and concise commit messages

## Github Heatmap

- Show places you've worked in github, where you spend the majority of your time in the codebases
