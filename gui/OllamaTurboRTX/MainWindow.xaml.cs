using System.Diagnostics;
using System.IO;
using System.Net.Http;
using System.Text;
using System.Text.Json;
using System.Windows;
using System.Windows.Media;

namespace OllamaTurboRTX;

public partial class MainWindow : Window
{
    private static readonly HttpClient Http = new() { Timeout = TimeSpan.FromMinutes(5) };
    private bool _busy;

    public MainWindow()
    {
        InitializeComponent();
        RefreshGpu();
        RefreshStatus();
    }

    private void RefreshGpu()
    {
        try
        {
            var smi = FindNvidiaSmi();
            if (smi is null)
            {
                TxtGpu.Text = "GPU: nvidia-smi not found — NVIDIA driver tools recommended.";
                return;
            }

            var psi = new ProcessStartInfo(smi)
            {
                Arguments = "--query-gpu=name,memory.total --format=csv,noheader,nounits",
                RedirectStandardOutput = true,
                UseShellExecute = false,
                CreateNoWindow = true
            };
            using var p = Process.Start(psi);
            var line = p?.StandardOutput.ReadLine()?.Trim();
            p?.WaitForExit(3000);
            if (string.IsNullOrWhiteSpace(line))
            {
                TxtGpu.Text = "GPU: (no nvidia-smi output)";
                return;
            }

            var parts = line.Split(',', StringSplitOptions.TrimEntries | StringSplitOptions.RemoveEmptyEntries);
            var name = parts.Length > 0 ? parts[0] : line;
            var vram = "";
            if (parts.Length > 1 && double.TryParse(parts[1], out var mb) && mb > 0)
                vram = $" (~{Math.Round(mb / 1024.0, 1)} GB)";

            var warn = "";
            if (name.Contains("GTX", StringComparison.OrdinalIgnoreCase) &&
                !name.Contains("RTX", StringComparison.OrdinalIgnoreCase))
                warn = "  ·  Warning: below RTX 2000 — Flash Attention gains may be limited.";
            else if (System.Text.RegularExpressions.Regex.IsMatch(name, @"RTX\s*1\d{3}",
                         System.Text.RegularExpressions.RegexOptions.IgnoreCase))
                warn = "  ·  Warning: below RTX 2000 — Flash Attention gains may be limited.";

            TxtGpu.Text = $"GPU: {name}{vram}{warn}";
        }
        catch
        {
            TxtGpu.Text = "GPU: (detection failed)";
        }
    }

    private static string? FindNvidiaSmi()
    {
        var pathEnv = Environment.GetEnvironmentVariable("PATH") ?? "";
        foreach (var dir in pathEnv.Split(Path.PathSeparator, StringSplitOptions.RemoveEmptyEntries))
        {
            try
            {
                var candidate = Path.Combine(dir.Trim(), "nvidia-smi.exe");
                if (File.Exists(candidate)) return candidate;
            }
            catch { /* ignore bad PATH entries */ }
        }

        var candidates = new[]
        {
            Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.System), "nvidia-smi.exe"),
            Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles),
                @"NVIDIA Corporation\NVSMI\nvidia-smi.exe")
        };
        return candidates.FirstOrDefault(File.Exists);
    }

    private void RefreshStatus()
    {
        string? fa = Environment.GetEnvironmentVariable("OLLAMA_FLASH_ATTENTION", EnvironmentVariableTarget.User);
        string? kv = Environment.GetEnvironmentVariable("OLLAMA_KV_CACHE_TYPE", EnvironmentVariableTarget.User);

        if (fa == "1" && kv == "q8_0")
        {
            TxtStatus.Text = "ACTIVE: Turbo Context (FA=1, KV=q8_0)";
            TxtStatus.Foreground = Brush("#38BDF8");
        }
        else if (fa == "1")
        {
            TxtStatus.Text = "ACTIVE: Turbo Pure Speed (FA=1, KV=FP16)";
            TxtStatus.Foreground = Brush("#4ADE80");
        }
        else
        {
            TxtStatus.Text = "Stock (Ollama default — FA off, KV FP16)";
            TxtStatus.Foreground = Brush("#A1A1AA");
        }
    }

    private static SolidColorBrush Brush(string hex) =>
        new((Color)ColorConverter.ConvertFromString(hex));

    private void BtnTurboContext_Click(object sender, RoutedEventArgs e)
    {
        if (_busy) return;
        SetOllamaConfig("1", "q8_0");
        TxtFeedback.Text = "Turbo Context applied (User registry) — Ollama restarted with FA+Q8.";
    }

    private void BtnTurboSpeed_Click(object sender, RoutedEventArgs e)
    {
        if (_busy) return;
        SetOllamaConfig("1", null);
        TxtFeedback.Text = "Turbo Pure Speed applied — Ollama restarted with FA only (KV FP16).";
    }

    private void BtnReset_Click(object sender, RoutedEventArgs e)
    {
        if (_busy) return;
        SetOllamaConfig(null, null);
        TxtFeedback.Text = "Stock restored — FA/KV User variables cleared, Ollama restarted.";
    }

    private async void BtnBench_Click(object sender, RoutedEventArgs e)
    {
        if (_busy) return;
        _busy = true;
        SetButtonsEnabled(false);
        var ctx = RbCtx16k.IsChecked == true ? 16384 : 4096;
        TxtFeedback.Text = $"Quick bench running (num_ctx={ctx})…";

        try
        {
            var model = await ResolveLocalModelAsync();
            if (model is null)
            {
                TxtFeedback.Text = "No local Ollama model found. Pull one first (e.g. ollama pull llama3.1:8b).";
                return;
            }

            TxtFeedback.Text = $"Warm-up {model}…";
            await GenerateOnceAsync(model, ctx, numPredict: 16);

            TxtFeedback.Text = $"Timing {model} (ctx={ctx})…";
            var stats = await GenerateOnceAsync(model, ctx, numPredict: 64);
            if (stats is null)
            {
                TxtFeedback.Text = "Bench failed — is Ollama running on 127.0.0.1:11434?";
                return;
            }

            TxtFeedback.Text =
                $"Bench OK — {model} | ctx={ctx} | eval {stats.Value.EvalTps:F1} t/s | prompt {stats.Value.PromptTps:F1} t/s";
        }
        catch (Exception ex)
        {
            TxtFeedback.Text = $"Bench error: {ex.Message}";
        }
        finally
        {
            _busy = false;
            SetButtonsEnabled(true);
        }
    }

    private void SetButtonsEnabled(bool enabled)
    {
        BtnBench.IsEnabled = enabled;
    }

    private void SetOllamaConfig(string? flashAttention, string? kvCache)
    {
        // Persistent User registry (no admin / UAC)
        Environment.SetEnvironmentVariable("OLLAMA_FLASH_ATTENTION", flashAttention, EnvironmentVariableTarget.User);
        Environment.SetEnvironmentVariable("OLLAMA_KV_CACHE_TYPE", kvCache, EnvironmentVariableTarget.User);

        // Mirror into this process so child inherit is consistent
        if (flashAttention is null) Environment.SetEnvironmentVariable("OLLAMA_FLASH_ATTENTION", null);
        else Environment.SetEnvironmentVariable("OLLAMA_FLASH_ATTENTION", flashAttention);
        if (kvCache is null) Environment.SetEnvironmentVariable("OLLAMA_KV_CACHE_TYPE", null);
        else Environment.SetEnvironmentVariable("OLLAMA_KV_CACHE_TYPE", kvCache);

        RestartOllamaProcess(flashAttention, kvCache);
        RefreshStatus();
    }

    private void RestartOllamaProcess(string? fa, string? kv)
    {
        try
        {
            foreach (var name in new[] { "ollama app", "ollama", "llama-server" })
            {
                foreach (var proc in Process.GetProcessesByName(name))
                {
                    try { proc.Kill(entireProcessTree: true); } catch { /* ignore */ }
                    try { proc.Dispose(); } catch { /* ignore */ }
                }
            }

            Thread.Sleep(600);

            string appPath = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                @"Programs\Ollama\ollama app.exe");
            string cliPath = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                @"Programs\Ollama\ollama.exe");

            if (File.Exists(appPath))
            {
                var startInfo = new ProcessStartInfo(appPath)
                {
                    Arguments = "hidden --fast-startup",
                    UseShellExecute = false,
                    CreateNoWindow = true,
                    WorkingDirectory = Path.GetDirectoryName(appPath)!
                };
                ApplyEnv(startInfo, fa, kv);
                Process.Start(startInfo);
                return;
            }

            if (File.Exists(cliPath))
            {
                var startInfo = new ProcessStartInfo(cliPath)
                {
                    Arguments = "serve",
                    UseShellExecute = false,
                    CreateNoWindow = true,
                    WorkingDirectory = Path.GetDirectoryName(cliPath)!
                };
                ApplyEnv(startInfo, fa, kv);
                Process.Start(startInfo);
            }
            else
            {
                MessageBox.Show(
                    "Ollama not found under %LOCALAPPDATA%\\Programs\\Ollama.\nInstall from https://ollama.com/download",
                    "Ollama missing", MessageBoxButton.OK, MessageBoxImage.Warning);
            }
        }
        catch (Exception ex)
        {
            MessageBox.Show($"Error restarting Ollama: {ex.Message}", "Warning",
                MessageBoxButton.OK, MessageBoxImage.Warning);
        }
    }

    private static void ApplyEnv(ProcessStartInfo startInfo, string? fa, string? kv)
    {
        if (fa is not null) startInfo.Environment["OLLAMA_FLASH_ATTENTION"] = fa;
        else startInfo.Environment.Remove("OLLAMA_FLASH_ATTENTION");

        if (kv is not null) startInfo.Environment["OLLAMA_KV_CACHE_TYPE"] = kv;
        else startInfo.Environment.Remove("OLLAMA_KV_CACHE_TYPE");

        startInfo.Environment["OLLAMA_HOST"] = "127.0.0.1:11434";
    }

    private static async Task<string?> ResolveLocalModelAsync()
    {
        using var resp = await Http.GetAsync("http://127.0.0.1:11434/api/tags");
        resp.EnsureSuccessStatusCode();
        await using var stream = await resp.Content.ReadAsStreamAsync();
        using var doc = await JsonDocument.ParseAsync(stream);
        if (!doc.RootElement.TryGetProperty("models", out var models) || models.GetArrayLength() == 0)
            return null;

        string? best = null;
        long bestSize = long.MaxValue;
        foreach (var m in models.EnumerateArray())
        {
            var name = m.GetProperty("name").GetString();
            if (string.IsNullOrWhiteSpace(name)) continue;
            if (name.Contains("cloud", StringComparison.OrdinalIgnoreCase)) continue;
            var size = m.TryGetProperty("size", out var s) ? s.GetInt64() : long.MaxValue;
            // Prefer ~7B/8B class when present
            if (name.Contains("8b", StringComparison.OrdinalIgnoreCase) ||
                name.Contains("7b", StringComparison.OrdinalIgnoreCase))
                return name;
            if (size < bestSize)
            {
                bestSize = size;
                best = name;
            }
        }
        return best ?? models[0].GetProperty("name").GetString();
    }

    private static async Task<(double EvalTps, double PromptTps)?> GenerateOnceAsync(string model, int numCtx, int numPredict)
    {
        var payload = new Dictionary<string, object?>
        {
            ["model"] = model,
            ["prompt"] = $"Quick bench nonce={Guid.NewGuid():N}. Reply with one short sentence about GPUs.",
            ["stream"] = false,
            ["keep_alive"] = 0,
            ["options"] = new Dictionary<string, object?>
            {
                ["num_ctx"] = numCtx,
                ["num_predict"] = numPredict,
                ["temperature"] = 0
            }
        };

        var json = JsonSerializer.Serialize(payload);
        using var content = new StringContent(json, Encoding.UTF8, "application/json");
        using var resp = await Http.PostAsync("http://127.0.0.1:11434/api/generate", content);
        if (!resp.IsSuccessStatusCode) return null;

        await using var stream = await resp.Content.ReadAsStreamAsync();
        using var doc = await JsonDocument.ParseAsync(stream);
        var root = doc.RootElement;

        double evalTps = 0, promptTps = 0;
        if (root.TryGetProperty("eval_count", out var ec) &&
            root.TryGetProperty("eval_duration", out var ed) &&
            ed.GetInt64() > 0)
            evalTps = ec.GetInt64() / (ed.GetInt64() / 1e9);

        if (root.TryGetProperty("prompt_eval_count", out var pc) &&
            root.TryGetProperty("prompt_eval_duration", out var pd) &&
            pd.GetInt64() > 0)
            promptTps = pc.GetInt64() / (pd.GetInt64() / 1e9);

        return (evalTps, promptTps);
    }
}
