INSTALL_DISPLAY="Laravel Livewire"
INSTALL_CREDENTIALS="register at http://$PROJECT_NAME/register (or seeded user test@example.com / password)"
INSTALL_NOTES="Official laravel/livewire-starter-kit: Livewire 4 + Flux UI + Fortify auth (login, register, 2FA, passkeys), settings, and a dashboard. Add components with: podium artisan livewire make:livewire <Name>"

# Source-based app: run the full Laravel setup pipeline (composer install, Vite build,
# .env wiring, migrations) instead of the prebuilt-image path. Use MySQL/MariaDB.
INSTALL_SETUP_FULL=1
INSTALL_SETUP_DB="mysql"

write_files() {
    # Download the official Laravel Livewire starter kit (no version tags upstream —
    # the default branch is the released line).
    echo-cyan "Downloading official Laravel Livewire starter kit ..."; echo-white
    curl -L "https://github.com/laravel/livewire-starter-kit/archive/refs/heads/main.tar.gz" | tar -xz --strip-components=1

    # Replicate the kit's post-create step (rename_livewire_files.php) in Python so we
    # don't depend on host PHP: Livewire 4 single-file components are blade files that
    # contain `use Livewire\Component;`, and the kit ships them un-prefixed; on project
    # creation they get the ⚡ emoji prefix that marks them as SFCs. Then drop the
    # one-shot rename script and its composer hook, exactly as upstream does.
    if [ -f "rename_livewire_files.php" ]; then
        echo-cyan "Marking Livewire single-file components ..."; echo-white
        python3 - << 'PY'
import os, json

base = os.path.join("resources", "views")
for root, _dirs, files in os.walk(base):
    for name in files:
        if not name.endswith(".blade.php") or name.startswith("⚡"):
            continue
        path = os.path.join(root, name)
        try:
            with open(path, "r", encoding="utf-8") as f:
                if "use Livewire\\Component;" not in f.read():
                    continue
        except (OSError, UnicodeDecodeError):
            continue
        new_path = os.path.join(root, "⚡" + name)
        if not os.path.exists(new_path):
            os.rename(path, new_path)
            print("  marked:", os.path.relpath(new_path))

# Drop the rename hook from composer.json so a stale reference to a deleted file
# never runs, mirroring rename_livewire_files.php's own cleanup.
try:
    with open("composer.json", encoding="utf-8") as f:
        data = json.load(f)
    cmds = data.get("scripts", {}).get("post-create-project-cmd")
    if isinstance(cmds, list):
        data["scripts"]["post-create-project-cmd"] = [
            c for c in cmds if "rename_livewire_files.php" not in str(c)
        ]
        with open("composer.json", "w", encoding="utf-8") as f:
            json.dump(data, f, indent=4)
            f.write("\n")
except (OSError, ValueError):
    pass
PY
        rm -f rename_livewire_files.php
    fi
}
