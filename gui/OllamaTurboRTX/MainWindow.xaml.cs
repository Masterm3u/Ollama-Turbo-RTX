using System.Diagnostics;
using System.IO;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;

namespace OllamaTurboRTX;

public partial class MainWindow : Window
{
    private bool _busy;
    private static readonly HashSet<string> ElevateActions = new(StringComparer.OrdinalIgnoreCase)
    {
        "install-context", "install-speed", "restore", "smart",
        "workflow-coding", "workflow-chat", "undo",
        "watchdog", "watchdog-install", "watchdog-remove",
        "bench", "bench-multi", "health"
    };

    public MainWindow()
    {
        InitializeComponent();
        Loaded += async (_, _) =>
        {
            RefreshGpu();
            RefreshStatus();
            var script = TurboEngine.FindScript();
            TxtScript.Text = script is null
                ? "Script: INTROUVABLE — placez Ollama-Turbo-RTX.ps1 a cote de l'exe."
                : $"Script: {script}";
            AppendLog("Pret. Toutes les actions appellent Ollama-Turbo-RTX.ps1 (parite 1:1).");
            await RunQuietStatusAsync().ConfigureAwait(true);
        };
    }

    private string SelectedLang()
    {
        if (CmbLang.SelectedItem is ComboBoxItem item && item.Content is string s)
            return s;
        return "en";
    }

    private int SelectedCtx() => RbCtx16k.IsChecked == true ? 16384 : 4096;

    private void RefreshGpu()
    {
        try
        {
            var smi = FindNvidiaSmi();
            if (smi is null)
            {
                TxtGpu.Text = "GPU: nvidia-smi introuvable";
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
                TxtGpu.Text = "GPU: (vide)";
                return;
            }
            var parts = line.Split(',', StringSplitOptions.TrimEntries | StringSplitOptions.RemoveEmptyEntries);
            var name = parts[0];
            var vram = parts.Length > 1 && double.TryParse(parts[1], out var mb)
                ? $" (~{Math.Round(mb / 1024.0, 1)} GB)" : "";
            TxtGpu.Text = $"GPU: {name}{vram}";
        }
        catch
        {
            TxtGpu.Text = "GPU: (detection echouee)";
        }
    }

    private static string? FindNvidiaSmi()
    {
        foreach (var dir in (Environment.GetEnvironmentVariable("PATH") ?? "")
                     .Split(Path.PathSeparator, StringSplitOptions.RemoveEmptyEntries))
        {
            try
            {
                var c = Path.Combine(dir.Trim(), "nvidia-smi.exe");
                if (File.Exists(c)) return c;
            }
            catch { /* ignore */ }
        }
        var sys = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.System), "nvidia-smi.exe");
        return File.Exists(sys) ? sys : null;
    }

    private void RefreshStatus()
    {
        var (fa, kv, mode) = TurboEngine.ReadMachineStatus();
        switch (mode)
        {
            case "context":
                TxtStatus.Text = "ACTIVE: Turbo Context (FA=1, KV=q8_0)";
                TxtStatus.Foreground = Brush("#38BDF8");
                break;
            case "speed":
                TxtStatus.Text = "ACTIVE: Turbo Pure Speed (FA=1, KV=FP16)";
                TxtStatus.Foreground = Brush("#4ADE80");
                break;
            default:
                TxtStatus.Text = "Stock (FA off, KV FP16)";
                TxtStatus.Foreground = Brush("#A1A1AA");
                break;
        }
    }

    private static SolidColorBrush Brush(string hex) =>
        new((Color)ColorConverter.ConvertFromString(hex));

    private void AppendLog(string text)
    {
        if (string.IsNullOrWhiteSpace(text)) return;
        Dispatcher.Invoke(() =>
        {
            if (TxtLog.Text.Length > 120_000)
                TxtLog.Text = TxtLog.Text[^60_000..];
            TxtLog.AppendText(text.TrimEnd() + Environment.NewLine);
            TxtLog.ScrollToEnd();
        });
    }

    private void SetBusy(bool busy)
    {
        _busy = busy;
        TxtFeedback.Text = busy
            ? "Execution en cours… (accepte l'UAC si demande — la fenetre reste ouverte)"
            : "Pret.";
        Cursor = busy ? System.Windows.Input.Cursors.AppStarting : System.Windows.Input.Cursors.Arrow;
    }

    private async void BtnRefresh_Click(object sender, RoutedEventArgs e)
    {
        RefreshGpu();
        RefreshStatus();
        await RunQuietStatusAsync().ConfigureAwait(true);
    }

    private async Task RunQuietStatusAsync()
    {
        try
        {
            var r = await TurboEngine.RunActionAsync("status", elevate: false, lang: SelectedLang()).ConfigureAwait(true);
            AppendLog(r.Output);
            RefreshStatus();
        }
        catch (Exception ex)
        {
            AppendLog("status: " + ex.Message);
        }
    }

    private async void BtnAction_Click(object sender, RoutedEventArgs e)
    {
        if (_busy) return;
        if (sender is not Button btn || btn.Tag is not string action) return;

        if (action == "support")
        {
            // Pas besoin d'Admin
            await ExecuteAsync(action, elevate: false, visible: false).ConfigureAwait(true);
            return;
        }

        if (action is "vram" or "gpu-check" or "status")
        {
            await ExecuteAsync(action, elevate: false, visible: false).ConfigureAwait(true);
            return;
        }

        await ExecuteAsync(action, elevate: ElevateActions.Contains(action), visible: false).ConfigureAwait(true);
    }

    private async void BtnBench_Click(object sender, RoutedEventArgs e)
    {
        if (_busy) return;
        if (sender is not Button btn || btn.Tag is not string action) return;

        var multi = action == "bench-multi";
        var msg = multi
            ? "Multi-bench 7B/14B/32B — souvent 15–30+ min. Continuer ?"
            : "Full bench Stock/FA/FA+Q8 — souvent 8–15+ min. Continuer ?";
        var confirm = MessageBox.Show(msg, "Benchmark", MessageBoxButton.YesNo, MessageBoxImage.Warning);
        if (confirm != MessageBoxResult.Yes) return;

        await ExecuteAsync(action, elevate: true, visible: true, ctx: SelectedCtx()).ConfigureAwait(true);
    }

    private async Task ExecuteAsync(string action, bool elevate, bool visible, int ctx = 0)
    {
        SetBusy(true);
        AppendLog($"\n===== {action} =====");
        TxtFeedback.Text = elevate
            ? $"UAC / Admin requis pour [{action}]…"
            : $"Execution [{action}]…";

        try
        {
            var progress = new Progress<string>(AppendLog);
            var result = await Task.Run(async () =>
                await TurboEngine.RunActionAsync(
                    action,
                    elevate,
                    lang: SelectedLang(),
                    ctx: ctx > 0 ? ctx : 0,
                    visibleConsole: visible,
                    progress: progress).ConfigureAwait(false)
            ).ConfigureAwait(true);

            AppendLog(result.Output);
            AppendLog($"exit={result.ExitCode}");
            TxtFeedback.Text = result.ExitCode == 0
                ? $"OK — {action}"
                : result.ExitCode == -1
                    ? "UAC refuse."
                    : $"Termine avec code {result.ExitCode}";
            RefreshStatus();
        }
        catch (Exception ex)
        {
            AppendLog("ERREUR: " + ex.Message);
            TxtFeedback.Text = ex.Message;
            MessageBox.Show(ex.Message, "Ollama-Turbo-RTX", MessageBoxButton.OK, MessageBoxImage.Error);
        }
        finally
        {
            SetBusy(false);
        }
    }

    private void BtnQuit_Click(object sender, RoutedEventArgs e) => Close();
}
