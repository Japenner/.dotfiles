# .dotfiles

A comprehensive, modern development environment setup for managing configurations, scripts, and tooling across multiple machines. This repository emphasizes productivity, automation, and workflow efficiency through modular configurations and robust tooling infrastructure.

## Quick Start

```bash
    # Clone and setup
    git clone https://github.com/japenner/.dotfiles.git ~/.dotfiles
    cd ~/.dotfiles
    .local/bin/dotfiles/setup.zsh

    # Check and install modern CLI tools
    tools:check
    tools:install
```

## Repository Structure

### **Core Configuration Areas**

#### `.local/bin/`

**Organized development tooling and automation scripts:**

- **`dev/`**: Development workflow tools
    - `code-search-preview` - Interactive code search with ripgrep + fzf + bat
    - `auto-type` - Controlled text input automation for demos/training
    - `snap` - Local backup and sync tool with retention policies
    - `bootstrap-project` - Flexible project environment setup
- **`dotfiles/`**: Dotfiles management utilities
    - `setup.zsh` - Initial dotfiles setup and stowing
    - `refresh.zsh` - Re-stow configurations for updates
    - `cleanup.zsh` - Remove all stow symlinks
- **`git/`**: Git workflow enhancements
- **`tmux/`**: Tmux session and window management tools

#### `__resources__/`

**Documentation, templates, and reference materials:**

- **`docs/`**: Strategic documentation
    - `highest_roi_scripts.md` - High-impact automation script ideas
    - `top_tier_tools_examples.md` - Premium tool configurations
- **`prompts/`**: AI-assisted workflow templates
    - `create_ticket.md` - GitHub issue creation
    - `generate_commit_message.md` - Commit message generation
    - `review_pr.md` - Pull request review checklist
- **`templates/`**:
    - `example-script.sh` - Robust bash script template with logging, error handling, and best practices
    - Various issue and PR templates
- **`reference/`**: Configuration examples and references

#### `zsh/`

**Modular, performance-optimized Zsh configuration:**

- **`configs/`**: Feature-specific configurations
    - `modern-tools.zsh` - **17 modern CLI tool replacements** with smart aliases
    - `autosuggestions.zsh` - Enhanced command suggestions
    - `history.zsh` - Advanced history management
    - `keybindings.zsh` - Custom key mappings
    - `performance.zsh` - Shell optimization settings
    - `python.zsh`, `ruby.zsh`, `tmux.zsh` - Language/tool specific configs
- **`functions/`**: Reusable shell functions organized by domain
    - `git.sh` - Git workflow helpers
    - `brew.sh` - Homebrew management
    - `vs-code.sh` - VS Code integration
    - `dotfiles.sh` - Dotfiles management functions
- **`local/`**: Machine-specific configurations (not tracked/optional)
    - `aliases.zsh.example` - Template for local aliases
    - `env.zsh.example` - Template for local environment variables

---

### **Application Configurations**

#### `git/`

**Git workflow optimization:**

- `.gitconfig` - Global Git configuration with productivity aliases
- `.gitconfig-work` - Work-specific Git settings for identity separation
- `.gitignore_global` - Universal ignore rules for all repositories
- `example.code-workspace` - VS Code workspace template

#### `vscode/`

**VS Code customization and extension management:**

- `settings.json` - Comprehensive editor settings and preferences
- `extension-list.txt` - Backup of installed extensions for consistency

#### `starship/`

**Cross-shell prompt configuration:**

- `.config/starship.toml` - Modern, customizable prompt setup
- Replaces heavier prompt frameworks with fast, feature-rich alternative

#### `homebrew/`

**Package management and backup:**

- Multiple timestamped `Brewfile` backups for environment restoration
- `Brewfile_backup_combined_*` - Consolidated package lists
- Automated backup generation via `brew:dump` alias

#### `tmux/`

**Terminal multiplexer enhancements:**

- Session management and window automation
- `IMPROVEMENTS.md` - Documented enhancements and customizations

#### `ruby/`

**Ruby development environment:**

- `Gemfile.global` - Essential gems available system-wide
- `.pryrc` - Enhanced REPL configuration
- `.rubocop.yml` - Code style enforcement
- `.solargraph.yml` - Language server configuration

#### `nvim/`

Neovim configuration for efficient text editing

#### `i3/`

Tiling window manager setup for Linux environments

---

## **Modern CLI Tools (17 Tools)**

This dotfiles setup includes automatic installation and aliasing for modern CLI tool replacements:

### **File Operations & Search**

- **`eza`** → replaces `ls` with icons and git integration
- **`bat`** → replaces `cat` with syntax highlighting
- **`ripgrep (rg)`** → replaces `grep` with blazing speed
- **`fd`** → replaces `find` with intuitive syntax
- **`dust`** → replaces `du` with visual disk usage
- **`ncdu`** → interactive disk usage browser

### **System Monitoring**

- **`btop`** → replaces `top`/`htop` with modern UI
- **`procs`** → replaces `ps` with colored output

### **Development & HTTP**

- **`httpie`** → replaces `curl` with human-friendly syntax
- **`hyperfine`** → command benchmarking tool
- **`watchexec`** → auto-run commands on file changes
- **`just`** → modern command runner

### **Shell Enhancement**

- **`zoxide`** → smart `cd` replacement with learning
- **`starship`** → fast, customizable prompt
- **`direnv`** → auto-load environment variables
- **`atuin`** → enhanced shell history with sync
- **`delta`** → beautiful `git diff` viewer

### **Quick Tool Management**

```bash
    tools:check          # Check installation status
    tools:install        # Install missing tools (Homebrew)
    tools:install:cargo  # Install via Cargo/Rust
```

---

## **Key Features & Productivity Enhancements**

### **Smart Aliases & Functions**

- **150+ productivity aliases** organized by category (Git, Rails, Docker, etc.)
- **Contextual functions** for common workflows
- **Machine-specific overrides** via local configurations

### **Enhanced Development Workflow**

- **Interactive code search** with live preview (`code-search-preview`)
- **Project bootstrapping** with automatic environment detection
- **Git workflow optimization** with AI-assisted commit messages
- **Automated backup systems** for configurations and data

### **Performance Optimizations**

- **Lazy-loading** for expensive operations
- **Modular configurations** prevent unnecessary loading
- **PATH deduplication** and optimization
- **Asynchronous plugin loading** where possible

### **Maintenance & Updates**

- **Automated Brewfile backups** with timestamps
- **Stow-based symlink management** for easy updates
- **Version-controlled configurations** with rollback capability
- **Health checks** for tool installations and configurations

---

## **Advanced Usage Examples**

### **Project Bootstrap**

```bash
    # Automatically detect and setup project environment
    bootstrap-project
    # Configures: Git hooks, Docker, direnv, tmux sessions
```

### **Smart Code Search**

```bash
    # Interactive search with live preview
    code-search-preview "function.*User"
    # Uses: ripgrep + fzf + bat + editor integration
```

### **Backup Management**

```bash
    # Create timestamped backups with retention
    snap backup --target workspace
    snap restore 2025-01-15_14-30-45
```

### **Development Automation**

```bash
    # AI-assisted commit with staging
    g:ac

    # Bootstrap Rails environment
    r:db:reset && r:server

    # Multi-tool setup
    tools:check && tools:install
```

---

## **Migration & Setup**

### **Fresh System Setup**

1. **Clone repository**: `git clone https://github.com/japenner/.dotfiles.git ~/.dotfiles`
2. **Run setup**: `cd ~/.dotfiles && .local/bin/dotfiles/setup.zsh`
3. **Install tools**: `tools:install`
4. **Configure locals**: Copy `.example` files in `zsh/local/`

### **Updating Existing Setup**

```bash
    df:pull      # Pull latest changes
    df:refresh   # Re-stow configurations
    tools:check  # Verify tool installations
```

### **Backup Current Setup**

```bash
    brew:dump    # Backup Homebrew packages
    snap backup  # Backup workspace
```

---

This repository represents a **battle-tested, production-ready** development environment that scales from personal projects to professional workflows. Each component is designed for **modularity, performance, and maintainability** while providing powerful automation and productivity enhancements.

## **Links & Resources**

- **Repository**: [github.com/japenner/.dotfiles](https://github.com/japenner/.dotfiles)
- **GNU Stow Documentation**: [gnu.org/software/stow](https://www.gnu.org/software/stow/)
- **Starship Prompt**: [starship.rs](https://starship.rs/)
- **Modern Unix Tools**: See `modern-tools.zsh` for complete list and links

### .ssh

- **config**:
    - Custom SSH configuration file specifying host aliases, key usage, and SSH options for secure and convenient connections to remote servers and Git repositories.

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

- **tmux-cht**:
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
        - `git.sh`: Git shortcuts/workflow enhancements & Helpers for interacting with GitHub repositories.
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
