# Jupyter Notebook (Python)

Jupyter Notebook 7 on the official Jupyter Docker Stacks SciPy image (numpy, pandas, matplotlib, scikit-learn, seaborn).

**Image**: `quay.io/jupyter/scipy-notebook:2026-08-03`
**Port**: 8888 (via nginx proxy, WebSocket upgrade required)
**Database**: none
**Credentials**: none — token auth disabled

## Key Notes
- The Jupyter images use **date tags**, not semver. `2026-08-03` is a real, immutable tag; `x86_64-*` tags are arch-specific and should not be used.
- Auth is disabled with `--IdentityProvider.token=` (empty value) passed in **exec form**, so the empty string survives compose's shlex parsing. `--NotebookApp.token` is the old Notebook 6 name and is ignored.
- `DOCKER_STACKS_JUPYTER_CMD=notebook` selects the Notebook 7 UI instead of the default JupyterLab.
- The kernel connection is a WebSocket — nginx **must** send `Upgrade`/`Connection` headers and use a long `proxy_read_timeout`, or cells will hang in "connecting".
- Only `/home/jovyan/work` is on a volume; anything written elsewhere in the container is lost on rebuild. `--ServerApp.root_dir` points the file browser there.
- The installer exists: run `podium install jupyter-notebook-python`.
