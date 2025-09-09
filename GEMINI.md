# GEMINI Project Context: Podium CLI

## Project Overview

This project is for "Podium CLI", a command-line interface for managing Docker-based PHP development environments. It simplifies the local development workflow for PHP applications by providing a standardized set of commands to create, manage, and interact with containerized services.

**Key Technologies:**

*   **Shell Scripting (Bash):** The core logic is written in Bash.
*   **Docker & Docker Compose:** Used for containerization of services and projects.
*   **PHP:** The target development language. The CLI supports Laravel, WordPress, and plain PHP projects.
*   **Git:** Used for version control of the projects created with the CLI.
*   **GitHub CLI (`gh`):** Integrated for optional GitHub repository creation.

**Architecture:**

*   **Global Configuration:** A central configuration is stored in `/etc/podium-cli/`. This includes an `.env` file for environment variables (like the Docker network subnet) and a `docker-compose.services.yaml` for managing shared services.
*   **Project-Specific Configuration:** Each project created with Podium gets its own `docker-compose.yaml` file within its directory, typically located in `~/podium-projects/`.
*   **Core Scripts:** The main logic is in the `src/scripts/` directory.
    *   `functions.sh`: Contains common helper functions for colors, Docker commands, and file manipulation.
    *   `configure.sh`: Handles the initial setup of the Podium CLI environment.
    *   `new_project.sh`: Manages the creation of new PHP projects.
    *   Other scripts correspond to the commands listed in the `README.md`.

## Building and Running

This is a shell script-based tool, so there is no traditional "build" process. The primary way to use it is by running the `podium` command, which is a symlink to the main script.

**Key Commands:**

*   **`podium configure`**: Initializes the Podium CLI environment, setting up Git, the projects directory, and Docker network settings.
*   **`podium new <project-name>`**: Creates a new PHP project (Laravel, WordPress, or plain PHP).
*   **`podium up`**: Starts all project containers and shared services.
*   **`podium down`**: Stops all project containers and shared services.
*   **`podium status`**: Shows the status of all running containers.
*   **`podium composer <args>`**: Runs Composer commands within a project's container.
*   **`podium art <args>`**: Runs Laravel Artisan commands.
*   **`podium wp <args>`**: Runs WordPress CLI commands.

## Development Conventions

*   **Shell Style:** The scripts use a consistent style with functions for common tasks and color-coded output for user feedback.
*   **JSON Output:** Many commands support a `--json-output` flag for programmatic use, which suppresses interactive prompts and outputs results in JSON format.
*   **Error Handling:** The `error()` function in `functions.sh` is used for consistent error reporting in both interactive and JSON modes.
*   **Debugging:** A `--debug` flag is available on most commands to enable detailed logging to `/tmp/podium-cli-debug.log`.
*   **Testing:** A test suite is available via `podium test-json-output` to validate the JSON output of various commands.
