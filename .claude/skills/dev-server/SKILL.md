---
name: dev-server
description: Run the project's dev server in the background and display the local URL where it can be viewed.
---

Start the project's dev server in the background and tell the user where to view it.

## Steps

1. **Detect the dev command** — check `package.json` (or `bun.lockb`, etc.) for a `dev` script. Common commands:
   - `bun run dev` (Bun projects)
   - `npm run dev` / `yarn dev` / `pnpm dev` (Node projects)
   - Fall back to whatever start command the project uses

2. **Start the server in the background** using the Bash tool with `run_in_background: true`.

3. **Detect the port** — check in this order:
   - The command's output (read the background task output after a short moment)
   - `CLAUDE.md` or project docs mentioning a port
   - Common defaults: 3000, 5173 (Vite), 4321 (Astro), 8080

4. **Display the URL** — output the local URL plainly, e.g.:

   ```
   http://localhost:3000
   ```

   If a network URL is also available (e.g. on a LAN IP), show that too.

## Notes

- Do not wait for the server to be fully ready before displaying the URL — just show it.
- If the server is already running on the expected port, say so instead of starting a second instance.
- Keep output minimal: just the URL (and the port source if it was non-obvious).
