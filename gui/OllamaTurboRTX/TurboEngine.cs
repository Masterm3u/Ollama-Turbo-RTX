using System.Diagnostics;
using System.IO;
using System.Text;

namespace OllamaTurboRTX;

/// <summary>
/// Lance Ollama-Turbo-RTX.ps1 (meme logique que le menu PowerShell) et capture la sortie.
/// </summary>
public static class TurboEngine
{
    public static string? FindScript()
    {
        var candidates = new[]
        {
            Path.Combine(AppContext.BaseDirectory, "Ollama-Turbo-RTX.ps1"),
            Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "..", "Ollama-Turbo-RTX.ps1")),
            Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "..", "..", "..", "..", "..", "Ollama-Turbo-RTX.ps1")),
            Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                "Ollama-Turbo-RTX", "Ollama-Turbo-RTX.ps1"),
        };
        return candidates.FirstOrDefault(File.Exists);
    }

    public static string? FindPowerShell()
    {
        var pwsh = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.System),
            @"WindowsPowerShell\v1.0\powershell.exe");
        if (File.Exists(pwsh)) return pwsh;
        return "powershell.exe";
    }

    public sealed record RunResult(int ExitCode, string Output, string LogPath);

    /// <summary>
    /// Execute une action CLI du script. Les actions Machine (install/restore/…) demandent l'elevation UAC.
    /// </summary>
    public static async Task<RunResult> RunActionAsync(
        string action,
        bool elevate,
        string? lang = null,
        int ctx = 0,
        string? model = null,
        string? models = null,
        int historyIndex = 1,
        bool visibleConsole = false,
        IProgress<string>? progress = null,
        CancellationToken ct = default)
    {
        var script = FindScript()
            ?? throw new FileNotFoundException(
                "Ollama-Turbo-RTX.ps1 introuvable. Reinstallez le MSI ou placez le script a cote de l'exe.");

        var logPath = Path.Combine(Path.GetTempPath(), $"ollama-turbo-gui-{Guid.NewGuid():N}.log");
        var ps = FindPowerShell()!;

        var argSb = new StringBuilder();
        argSb.Append("-NoProfile -ExecutionPolicy Bypass -File \"").Append(script).Append('"');
        argSb.Append(" -Action ").Append(action);
        if (!string.IsNullOrWhiteSpace(lang)) argSb.Append(" -Lang ").Append(lang);
        if (ctx > 0) argSb.Append(" -Ctx ").Append(ctx);
        if (!string.IsNullOrWhiteSpace(model)) argSb.Append(" -Model \"").Append(model).Append('"');
        if (!string.IsNullOrWhiteSpace(models)) argSb.Append(" -Models \"").Append(models).Append('"');
        if (action == "undo") argSb.Append(" -HistoryIndex ").Append(historyIndex);
        if (!visibleConsole) argSb.Append(" -Quiet -Theme Minimal");
        argSb.Append(" -LogFile \"").Append(logPath).Append('"');

        progress?.Report($"→ {action} …");

        if (visibleConsole)
        {
            // Fenetre console interactive (bench long) — meme UX que le script
            var psiVis = new ProcessStartInfo
            {
                FileName = ps,
                Arguments = argSb.ToString().Replace(" -Quiet -Theme Minimal", ""),
                UseShellExecute = true,
                Verb = elevate ? "runas" : "open"
            };
            try
            {
                using var p = Process.Start(psiVis)
                    ?? throw new InvalidOperationException("Impossible de demarrer PowerShell.");
                await p.WaitForExitAsync(ct).ConfigureAwait(false);
                var outVis = File.Exists(logPath) ? await File.ReadAllTextAsync(logPath, ct) : "(voir fenetre console)";
                return new RunResult(p.ExitCode, outVis, logPath);
            }
            catch (System.ComponentModel.Win32Exception ex) when (ex.NativeErrorCode == 1223)
            {
                return new RunResult(-1, "UAC refuse — action annulee.", logPath);
            }
        }

        if (elevate)
        {
            var psi = new ProcessStartInfo
            {
                FileName = ps,
                Arguments = argSb.ToString(),
                UseShellExecute = true,
                Verb = "runas",
                WindowStyle = ProcessWindowStyle.Hidden
            };
            try
            {
                using var p = Process.Start(psi)
                    ?? throw new InvalidOperationException("Impossible de demarrer PowerShell (UAC).");
                await p.WaitForExitAsync(ct).ConfigureAwait(false);
                // Attendre flush transcript
                await Task.Delay(400, ct).ConfigureAwait(false);
                var text = await ReadLogAsync(logPath, ct).ConfigureAwait(false);
                return new RunResult(p.ExitCode, text, logPath);
            }
            catch (System.ComponentModel.Win32Exception ex) when (ex.NativeErrorCode == 1223)
            {
                return new RunResult(-1, "UAC refuse — action annulee.", logPath);
            }
        }

        // Sans elevation : redirection stdout possible
        var psiDirect = new ProcessStartInfo
        {
            FileName = ps,
            Arguments = argSb.ToString(),
            UseShellExecute = false,
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            CreateNoWindow = true,
            StandardOutputEncoding = Encoding.UTF8,
            StandardErrorEncoding = Encoding.UTF8
        };

        using var proc = new Process { StartInfo = psiDirect, EnableRaisingEvents = true };
        var sb = new StringBuilder();
        proc.OutputDataReceived += (_, e) =>
        {
            if (e.Data is null) return;
            lock (sb) sb.AppendLine(e.Data);
            progress?.Report(e.Data);
        };
        proc.ErrorDataReceived += (_, e) =>
        {
            if (e.Data is null) return;
            lock (sb) sb.AppendLine(e.Data);
            progress?.Report(e.Data);
        };

        if (!proc.Start()) throw new InvalidOperationException("PowerShell start failed.");
        proc.BeginOutputReadLine();
        proc.BeginErrorReadLine();
        await proc.WaitForExitAsync(ct).ConfigureAwait(false);
        await Task.Delay(200, ct).ConfigureAwait(false);

        var logged = await ReadLogAsync(logPath, ct).ConfigureAwait(false);
        var combined = string.IsNullOrWhiteSpace(logged) ? sb.ToString() : logged;
        if (string.IsNullOrWhiteSpace(combined)) combined = sb.ToString();
        return new RunResult(proc.ExitCode, combined.Trim(), logPath);
    }

    private static async Task<string> ReadLogAsync(string path, CancellationToken ct)
    {
        if (!File.Exists(path)) return "";
        try
        {
            // Transcript peut encore etre verrouille brièvement
            for (var i = 0; i < 10; i++)
            {
                try
                {
                    return await File.ReadAllTextAsync(path, Encoding.UTF8, ct).ConfigureAwait(false);
                }
                catch (IOException)
                {
                    await Task.Delay(150, ct).ConfigureAwait(false);
                }
            }
        }
        catch { /* ignore */ }
        return "";
    }

    public static (string? Fa, string? Kv, string Mode) ReadMachineStatus()
    {
        var fa = Environment.GetEnvironmentVariable("OLLAMA_FLASH_ATTENTION", EnvironmentVariableTarget.Machine);
        var kv = Environment.GetEnvironmentVariable("OLLAMA_KV_CACHE_TYPE", EnvironmentVariableTarget.Machine);
        // Fallback User (GUI precedente)
        if (string.IsNullOrEmpty(fa))
            fa = Environment.GetEnvironmentVariable("OLLAMA_FLASH_ATTENTION", EnvironmentVariableTarget.User);
        if (string.IsNullOrEmpty(kv))
            kv = Environment.GetEnvironmentVariable("OLLAMA_KV_CACHE_TYPE", EnvironmentVariableTarget.User);

        string mode;
        if (fa == "1" && kv == "q8_0") mode = "context";
        else if (fa == "1") mode = "speed";
        else mode = "stock";
        return (fa, kv, mode);
    }
}
