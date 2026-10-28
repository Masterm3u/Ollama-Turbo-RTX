using System.Diagnostics;
using System.IO;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;

namespace OllamaTurboRTX;

public partial class MainWindow : Window
{
    private bool _busy;
    private string _lang = "fr";
    private int _ctx = 4096;

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
        HighlightLang();
        HighlightCtx();
        Loaded += async (_, _) =>
        {
            RefreshGpu();
            RefreshStatus();
            AppendLog("Pret — interface tuiles. Chaque action lance le script PowerShell officiel.");
            await RunQuietStatusAsync().ConfigureAwait(true);
        };
    }

    private void BtnLang_Click(object sender, RoutedEventArgs e)
    {
        if (sender is Button { Tag: string code })
        {
            _lang = code;
            HighlightLang();
            TxtFeedback.Text = $"Langue script : {_lang.ToUpperInvariant()}";
        }
    }

    private void BtnCtx_Click(object sender, RoutedEventArgs e)
    {
        if (sender is Button { Tag: string t } && int.TryParse(t, out var n))
        {
            _ctx = n;
            HighlightCtx();
            TxtFeedback.Text = $"Contexte bench : {_ctx:N0} tokens";
        }
    }

    private void HighlightLang()
    {
        SetSmallTile(BtnLangFr, _lang == "fr");
        SetSmallTile(BtnLangEn, _lang == "en");
        SetSmallTile(BtnLangEs, _lang == "es");
        SetSmallTile(BtnLangDe, _lang == "de");
    }

    private void HighlightCtx()
    {
        SetSmallTile(BtnCtx4k, _ctx == 4096);
        SetSmallTile(BtnCtx16k, _ctx == 16384);
    }

    private void SetSmallTile(Button btn, bool on)
    {
        btn.Style = (Style)FindResource(on ? "TileSmallOn" : "TileSmall");
    }

    private void RefreshGpu()
    {
        try
        {
            var smi = FindNvidiaSmi();
            if (smi is null)
            {
                TxtGpu.Text = "GPU : nvidia-smi introuvable (installez les pilotes NVIDIA)";
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
                TxtGpu.Text = "GPU : (aucune donnee)";
                return;
            }
            var parts = line.Split(',', StringSplitOptions.TrimEntries | StringSplitOptions.RemoveEmptyEntries);
            var name = parts[0];
            var vram = parts.Length > 1 && double.TryParse(parts[1], out var mb)
                ? $"  ·  {Math.Round(mb / 1024.0, 1)} Go VRAM" : "";
            TxtGpu.Text = $"GPU : {name}{vram}";
        }
        catch
        {
            TxtGpu.Text = "GPU : detection impossible";
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
        var (_, _, mode) = TurboEngine.ReadMachineStatus();
        switch (mode)
        {
            case "context":
                TxtStatus.Text = "Turbo Contexte actif  (Flash Attention + Q8)";
                TxtStatus.Foreground = Brush("#38BDF8");
                break;
            case "speed":
                TxtStatus.Text = "Turbo Vitesse actif  (Flash Attention seul)";
                TxtStatus.Foreground = Brush("#4ADE80");
                break;
            default:
                TxtStatus.Text = "Mode Stock  (reglages Ollama par defaut)";
                TxtStatus.Foreground = Brush("#A1A1AA");
                break;
        }
    }

    private static SolidColorBrush Brush(string hex) =>
        new((Color)ColorConverter.ConvertFromString(hex));

    private void AppendLog(string text)
    {
        if (string.IsNullOrWhiteSpace(text)) return;
        void Write()
        {
            if (TxtLog.Text.Length > 80_000)
                TxtLog.Text = TxtLog.Text[^40_000..];
            TxtLog.AppendText(text.TrimEnd() + Environment.NewLine);
            TxtLog.CaretIndex = TxtLog.Text.Length;
            TxtLog.ScrollToEnd();
        }
        if (Dispatcher.CheckAccess()) Write();
        else Dispatcher.Invoke(Write);
    }

    private void SetBusy(bool busy)
    {
        _busy = busy;
        void Apply()
        {
            TxtFeedback.Text = busy
                ? "Travail en cours… Acceptez la fenetre Admin (UAC) si elle apparait."
                : "Pret — cliquez une tuile.";
            Cursor = busy ? System.Windows.Input.Cursors.AppStarting : System.Windows.Input.Cursors.Arrow;
        }
        if (Dispatcher.CheckAccess()) Apply();
        else Dispatcher.Invoke(Apply);
    }

    private async void BtnRefresh_Click(object sender, RoutedEventArgs e)
    {
        if (_busy) return;
        RefreshGpu();
        RefreshStatus();
        await RunQuietStatusAsync().ConfigureAwait(true);
    }

    private async Task RunQuietStatusAsync()
    {
        var lang = _lang; // capture UI thread
        try
        {
            var result = await Task.Run(async () =>
                await TurboEngine.RunActionAsync("status", elevate: false, lang: lang).ConfigureAwait(false)
            ).ConfigureAwait(true);
            AppendLog(result.Output);
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

        var elevate = action switch
        {
            "support" or "vram" or "gpu-check" or "status" => false,
            _ => ElevateActions.Contains(action)
        };
        await ExecuteAsync(action, elevate, visible: false).ConfigureAwait(true);
    }

    private async void BtnBench_Click(object sender, RoutedEventArgs e)
    {
        if (_busy) return;
        if (sender is not Button btn || btn.Tag is not string action) return;

        var multi = action == "bench-multi";
        var msg = multi
            ? "Benchmark multi-modeles (7B / 14B / 32B).\nDuree typique : 15 a 30+ minutes.\n\nContinuer ?"
            : "Benchmark complet (Stock vs FA vs FA+Q8).\nDuree typique : 8 a 15 minutes.\n\nContinuer ?";
        if (MessageBox.Show(msg, "Ollama Turbo — Benchmark", MessageBoxButton.YesNo, MessageBoxImage.Question)
            != MessageBoxResult.Yes) return;

        await ExecuteAsync(action, elevate: true, visible: true, ctx: _ctx).ConfigureAwait(true);
    }

    private async Task ExecuteAsync(string action, bool elevate, bool visible, int ctx = 0)
    {
        // Capturer sur le thread UI AVANT Task.Run (evite InvalidOperationException)
        var lang = _lang;
        var ctxUse = ctx > 0 ? ctx : _ctx;

        SetBusy(true);
        AppendLog($"\n===== {action} =====");
        TxtFeedback.Text = elevate
            ? $"Action [{action}] — une invite Admin peut s'ouvrir…"
            : $"Action [{action}]…";

        try
        {
            var progress = new Progress<string>(line => AppendLog(line));
            var result = await Task.Run(async () =>
                await TurboEngine.RunActionAsync(
                    action,
                    elevate,
                    lang: lang,
                    ctx: visible ? ctxUse : 0,
                    visibleConsole: visible,
                    progress: progress).ConfigureAwait(false)
            ).ConfigureAwait(true);

            AppendLog(result.Output);
            AppendLog($"Code sortie : {result.ExitCode}");
            TxtFeedback.Text = result.ExitCode switch
            {
                0 => $"Termine : {LabelOf(action)}",
                -1 => "Admin refuse (UAC annule).",
                _ => $"Termine avec code {result.ExitCode}"
            };
            RefreshStatus();
            RefreshGpu();
        }
        catch (Exception ex)
        {
            AppendLog("ERREUR: " + ex.Message);
            TxtFeedback.Text = "Erreur — voir le journal.";
            MessageBox.Show(ex.Message, "Ollama Turbo", MessageBoxButton.OK, MessageBoxImage.Error);
        }
        finally
        {
            SetBusy(false);
        }
    }

    private static string LabelOf(string action) => action switch
    {
        "install-context" => "Turbo Contexte",
        "install-speed" => "Turbo Vitesse",
        "restore" => "Mode Stock",
        "bench" => "Benchmark",
        "bench-multi" => "Multi-modeles",
        "health" => "Diagnostic",
        "smart" => "Preset intelligent",
        "vram" => "Estimation VRAM",
        "undo" => "Annulation",
        "support" => "Liens ouverts",
        _ => action
    };

    private void BtnQuit_Click(object sender, RoutedEventArgs e) => Close();
}
