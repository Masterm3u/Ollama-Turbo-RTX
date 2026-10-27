# Demo assets

Drop your viral demo GIF here as **`demo.gif`** (ScreenToGif / Terminalizer / Windows Game Bar).

Suggested recording (20–40 seconds):

1. Open PowerShell **as Administrator**
2. Run: `irm https://masterm3u.github.io/turbo | iex`
3. Show the colored menu (mention **[1]/[4]/[6]/[7]/[M]/[S]**)
4. Optional short path:
   - **[7]** smart VRAM preset (table + apply), or
   - **[6]** health check (Ollama + driver lines), or
   - **[4]** start bench → show the **duration warning** + chrono in the title (cut before the full 15 min run)
5. Export as GIF (~800–1200px wide, under ~8 MB for GitHub)

CLI one-liner for a silent status shot:

```powershell
.\Ollama-Turbo-RTX.ps1 -Action status -Quiet
```

Once `assets/demo.gif` exists, uncomment the demo image block in the main [`README.md`](../README.md).
