INSTALL_DISPLAY="Laravel Livewire"
INSTALL_NOTES="Fresh Laravel app with Livewire installed and a live <livewire:counter /> demo on the home page. Add components with: podium artisan livewire make:livewire <Name>"

# Source-based app: run the full Laravel setup pipeline (composer install, Vite build,
# .env wiring, migrations) instead of the prebuilt-image path. Use MySQL/MariaDB.
INSTALL_SETUP_FULL=1
INSTALL_SETUP_DB="mysql"

write_files() {
    # Download the same Laravel skeleton that 'podium new laravel' uses (latest stable
    # tag; falls back to the default branch if the GitHub API is rate-limited).
    echo-cyan "Downloading Laravel skeleton ..."; echo-white
    local ver tarball
    ver=$(curl -s https://api.github.com/repos/laravel/laravel/tags | grep '"name"' | head -1 | sed 's/.*"v\([^"]*\)".*/\1/')
    if [ -n "$ver" ]; then
        tarball="https://github.com/laravel/laravel/archive/refs/tags/v${ver}.tar.gz"
    else
        tarball="https://github.com/laravel/laravel/archive/refs/heads/master.tar.gz"
    fi
    curl -L "$tarball" | tar -xz --strip-components=1

    # Resolve the latest stable Livewire release into a clean caret constraint
    # (e.g. 4.1.3 -> ^4.1). Falls back to ^3.0 if Packagist is unreachable.
    local lwver constraint
    lwver=$(curl -s "https://repo.packagist.org/p2/livewire/livewire.json" 2>/dev/null \
        | python3 -c "import sys,json
try:
    d=json.load(sys.stdin)
    for p in d['packages']['livewire/livewire']:
        v=p['version']
        if 'dev' not in v and '-' not in v:
            print(v.lstrip('v')); break
except Exception:
    pass" 2>/dev/null)
    if [[ "$lwver" =~ ^([0-9]+)\.([0-9]+) ]]; then
        constraint="^${BASH_REMATCH[1]}.${BASH_REMATCH[2]}"
    else
        constraint="^3.0"
    fi
    echo-cyan "Adding livewire/livewire ${constraint} to composer.json ..."; echo-white

    # Add Livewire to the project's dependencies and drop the shipped lock so the
    # setup step's `composer install` resolves it (Composer treats a missing lock
    # as an update).
    python3 - "$constraint" << 'PY'
import json, sys
with open('composer.json') as f:
    data = json.load(f)
data.setdefault('require', {})['livewire/livewire'] = sys.argv[1]
with open('composer.json', 'w') as f:
    json.dump(data, f, indent=4)
    f.write('\n')
PY
    rm -f composer.lock

    # A working Livewire component so the home page proves the install end-to-end.
    mkdir -p app/Livewire resources/views/livewire
    cat > app/Livewire/Counter.php << 'PHP'
<?php

namespace App\Livewire;

use Livewire\Component;

class Counter extends Component
{
    public int $count = 0;

    public function increment(): void
    {
        $this->count++;
    }

    public function decrement(): void
    {
        $this->count--;
    }

    public function render()
    {
        return view('livewire.counter');
    }
}
PHP

    cat > resources/views/livewire/counter.blade.php << 'BLADE'
<div style="display:flex;align-items:center;gap:1.5rem;font-family:system-ui,sans-serif;">
    <button wire:click="decrement" style="font-size:1.5rem;width:3rem;height:3rem;border-radius:.5rem;border:1px solid #ccc;background:#fff;cursor:pointer;">&minus;</button>
    <span style="font-size:2.5rem;min-width:3rem;text-align:center;">{{ $count }}</span>
    <button wire:click="increment" style="font-size:1.5rem;width:3rem;height:3rem;border-radius:.5rem;border:1px solid #ccc;background:#fff;cursor:pointer;">+</button>
</div>
BLADE

    # Replace the default welcome page with one that mounts the Livewire component.
    # A full HTML document lets Livewire auto-inject its styles/scripts.
    cat > resources/views/welcome.blade.php << 'BLADE'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Laravel + Livewire</title>
    <style>
        body { font-family: system-ui, -apple-system, sans-serif; margin:0; min-height:100vh; display:flex; flex-direction:column; align-items:center; justify-content:center; gap:.5rem; background:#fafafa; color:#1a1a1a; }
        h1 { font-weight:600; margin:0; }
        p  { color:#666; margin:0 0 1.5rem; }
    </style>
</head>
<body>
    <h1>Laravel + Livewire</h1>
    <p>This counter is a live Livewire component &mdash; no page reloads.</p>
    <livewire:counter />
</body>
</html>
BLADE
}
