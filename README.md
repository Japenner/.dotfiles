# .dotfiles

A comprehensive setup for managing my development environment across multiple machines. This repository includes configurations, scripts, and tooling setups for productivity, code quality, and workflow efficiency. It leverages tools like [GNU Stow](https://www.gnu.org/software/stow/) for managing symlinks and keeps all my machines consistent in terms of tooling and customization.

## Areas

### .ssh

- **config**:
    - Custom SSH configuration file specifying host aliases, key usage, and SSH options for secure and convenient connections to remote servers and Git repositories.

### bin

- **local scripts**:
    - Contains personal utility scripts designed for various automation and productivity tasks. These scripts are directly executable from the terminal and facilitate quick actions without needing to reference complex commands.

### homebrew

- **Brewfile Backups**:
    - Periodically backed up Brewfiles, in case I need to revert to a previous setup.

### git

- **.gitconfig**:
    - Global Git configuration for managing user information, aliases, and custom settings that streamline Git workflows. Includes useful shortcuts for frequently used commands.
- **.gitconfig-work**:
    - A work-specific Git configuration with settings or credentials exclusive to work repositories. This allows separation of work and personal Git identities.
- **.gitignore_global**:
    - Global ignore rules applied to all repositories, preventing accidental commits of sensitive files like OS caches, logs, and other system-generated files that shouldn’t be tracked.

### i3

- **.config**:
    - Configuration files for the i3 tiling window manager, allowing for a highly productive, keyboard-focused workflow on Linux systems. Contains workspace layouts, keybindings, and customization options for efficient window management.

### nvim

- **init.vim**:
    - Primary configuration file for Neovim. This file sets up plugins, key mappings, and settings for an optimized Neovim experience, including language-specific settings and custom editor behaviors.

### ruby

- **.pryrc**:
    - Configuration for the Pry REPL, enhancing Ruby debugging with custom commands, colorization, and history settings.
- **.rubocop.yml**:
    - Custom RuboCop configuration to enforce Ruby code style, ensuring consistent formatting and best practices in Ruby projects.
- **.solargraph.yml**:
    - Configuration for Solargraph, a Ruby language server that provides code navigation, autocompletion, and documentation features in editors like VS Code.
- **Gemfile.global**:
    - A Gemfile for globally installing essential Ruby gems, making utilities like Pry, RuboCop, and Solargraph accessible in any Ruby environment without requiring per-project installations.

### scripts

- **old**:
    - Archive of older scripts, including `flamegraph.pl`, which might be used for generating flame graphs (useful for performance profiling).
- **cleanup.zsh**:
    - A script to remove all GNU Stow symlinks, allowing for a complete refresh of the symlinked configurations.
- **refresh.zsh**:
    - Re-stows directories to update symlinks, ensuring all configurations point to the latest versions in this repository.
- **setup.zsh**:
    - Prepares environment variables and directories necessary for the initial setup of this dotfiles repository, making it ready for use with GNU Stow.
- **unfinished**:
    - Contains in-progress scripts and notes, including:
        - `TODO.md`: A task list for unfinished scripts and planned improvements.
        - `gh_issue_goal_matching.md`: Notes on GitHub issue management and goal alignment.
        - `marcus_p10k.zsh`: A personalized prompt setup based on Powerlevel10k for visually rich terminal information.
        - `set_slack_status.sh`: A script for automating Slack status updates based on system activity.
        - `slack_thread_retrieval.md`: Documentation on retrieving Slack threads for potential future scripting.
        - `time_keeper.md`: Notes on a potential time-tracking or productivity-tracking script.

### tmux

- **tmux-cht.sh**:
    - Script that integrates `cht.sh` (cheat.sh) with tmux, enabling quick access to coding cheatsheets directly in a new tmux pane.
- **tmux-sessionizer**:
    - A utility for managing tmux sessions, allowing quick switching between sessions based on workspace or project, enhancing multitasking capabilities.
- **tmux-windowizer**:
    - Automates window creation within tmux sessions, allowing for pre-defined window layouts to suit different tasks (e.g., coding, monitoring, and debugging windows).

### vscode

- **extension-list.txt**:
    - A backup list of all installed VS Code extensions to ensure consistency across machines, especially useful for rebuilding or migrating VS Code setups.
- **settings.json**:
    - Customized VS Code settings, defining editor behavior, theme preferences, and extension configurations to provide a uniform development environment.

### zsh

- **configs**:
    - Modular Zsh configuration files that separate different aspects of shell behavior:
        - `autosuggestions.zsh`: Configures autosuggestions for faster command recall.
        - `colors-and-editor.zsh`: Sets color schemes and default editor settings for the shell.
        - `correction-and-navigation.zsh`: Configures typo correction and enhanced directory navigation.
        - `directory-navigation.zsh`: Adds custom directory navigation helpers.
        - `globbing-and-matching.zsh`: Customizes file matching and globbing behavior.
        - `history.zsh`: Manages history settings, ensuring efficient command recall.
        - `keybindings.zsh`: Defines custom keybindings for common shell actions.
        - `prompt-and-git.zsh`: Sets up the prompt, including Git status integration.
        - `ruby.zsh`: Ruby-specific shell settings, like adding paths to Ruby executables.
- **functions**:
    - Contains helper scripts that extend Zsh functionality:
        - `brew.sh`: Functions for managing Homebrew packages.
        - `directories.sh`: Directory navigation shortcuts.
        - `dotfiles.sh`: Functions for managing this dotfiles repository.
        - `environment.sh`: Environment variable setup for specific workflows.
        - `files.sh`: Functions for file manipulation.
        - `git.sh`: Git shortcuts and workflow enhancements.
        - `github.sh`: Helpers for interacting with GitHub repositories.
        - `ruby.sh`: Ruby environment management helpers.
        - `vs-code.sh`: VS Code-related functions, including extension management.
- **local**:
    - Machine-specific configurations:
        - `aliases.zsh`: Custom aliases that may differ based on the machine or environment.
        - `env.zsh`: Local environment variables that shouldn’t be shared across machines.
- **prompts**:
    - Pre-defined prompts for use in specific scenarios:
        - `create_ticket.md`: Template for creating a GitHub ticket with all necessary information.
        - `refine_code.md`: Template prompt for refining code quality or implementing code reviews.
        - `refine_rspec_coverage.md`: Template for improving RSpec coverage in Ruby projects.
        - `review_pr.md`: Checklist for reviewing pull requests, ensuring quality and consistency.
- **templates**:
    - Standardized templates for project and issue tracking:
        - `design-bug-issue-template.md`: Template for creating detailed bug reports, including reproduction steps and expected behavior.
        - `github-issue-template.md`: A template for standard GitHub issues, ensuring consistency in issue creation.
        - `va-gov-pr-template.md`: A pull request template specifically for VA.gov projects, ensuring all necessary details are included.

---

This repository provides a streamlined way to set up, customize, and manage development environments across multiple machines. Each component—from Zsh functions to tmux layouts—enhances productivity and ensures consistency. Configuration is organized and modular, making it easy to update or extend. It’s managed through GNU Stow, allowing for easy symlink management and compatibility across different systems.
