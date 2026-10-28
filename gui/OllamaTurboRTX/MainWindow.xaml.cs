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
    private IReadOnlyDictionary<string, string> _t = UiStrings.Get("fr");

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
        ApplyLanguage("fr");
        HighlightCtx();
        Loaded += async (_, _) =>
        {
            RefreshGpu();
            RefreshStatus();
            AppendLog(_t["ready"]);
            await RunQuietStatusAsync().ConfigureAwait(true);
        };
    }

    private string S(string key) => _t.TryGetValue(key, out var v) ? v : key;

    private void ApplyLanguage(string lang)
    {
        _lang = lang;
        _t = UiStrings.Get(lang);
        HighlightLang();

        TxtTitle.Text = S("title");
        TxtSubtitle.Text = S("subtitle");
        LblState.Text = S("state");
        LblLang.Text = S("lang");
        LblCtx.Text = S("ctx");
        LblOpt.Text = S("opt");
        LblBench.Text = S("bench");
        LblTools.Text = S("tools");
        LblJournal.Text = S("journal");
        BtnRefresh.Content = S("refresh");
        TxtFeedback.Text = S("hint");

        T1.Text = S("t1"); T1b.Text = S("t1b"); T1c.Text = S("t1c");
        T2.Text = S("t2"); T2b.Text = S("t2b"); T2c.Text = S("t2c");
        T3.Text = S("t3"); T3b.Text = S("t3b"); T3c.Text = S("t3c");
        T4.Text = S("t4"); T4b.Text = S("t4b");
        TM.Text = S("tm"); TMb.Text = S("tmb");
        T6.Text = S("t6"); T6b.Text = S("t6b");
        T7.Text = S("t7"); T7b.Text = S("t7b");
        TA.Text = S("ta"); TAb.Text = S("tab");
        T8c.Text = S("t8c"); T8cb.Text = S("t8cb");
        T8h.Text = S("t8h"); T8hb.Text = S("t8hb");
        T9.Text = S("t9"); T9b.Text = S("t9b");
        TG.Text = S("tg"); TGb.Text = S("tgb");
        TW1.Text = S("tw1"); TW1b.Text = S("tw1b");
        TW2.Text = S("tw2"); TW2b.Text = S("tw2b");
        TW3.Text = S("tw3"); TW3b.Text = S("tw3b");
        TS.Text = S("ts"); TSb.Text = S("tsb");
        TQ.Text = S("tq"); TQb.Text = S("tqb");

        RefreshStatus();
    }

    private void BtnLang_Click(object sender, RoutedEventArgs e)
    {
        if (sender is not Button { Tag: string code }) return;
        ApplyLanguage(code);
        TxtFeedback.Text = string.Format(S("lang_set"), code.ToUpperInvariant());
        AppendLog(string.Format(S("lang_set"), code.ToUpperInvariant()));
    }

    private void BtnCtx_Click(object sender, RoutedEventArgs e)
    {
        if (sender is Button { Tag: string t } && int.TryParse(t, out var n))
        {
            _ctx = n;
            HighlightCtx();
            TxtFeedback.Text = string.Format(S("ctx_set"), _ctx);
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

    private void SetSmallTile(Button btn, bool on) =>
        btn.Style = (Style)FindResource(on ? "TileSmallOn" : "TileSmall");

    private void RefreshGpu()
    {
        try
        {
            var smi = FindNvidiaSmi();
            if (smi is null)
            {
                TxtGpu.Text = "GPU : nvidia-smi — N/A";
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
                TxtGpu.Text = "GPU : —";
                return;
            }
            var parts = line.Split(',', StringSplitOptions.TrimEntries | StringSplitOptions.RemoveEmptyEntries);
            var name = parts[0];
            var vram = parts.Length > 1 && double.TryParse(parts[1], out var mb)
                ? $"  ·  {Math.Round(mb / 1024.0, 1)} GB" : "";
            TxtGpu.Text = $"GPU : {name}{vram}";
        }
        catch
        {
            TxtGpu.Text = "GPU : ?";
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
                TxtStatus.Text = S("status_context");
                TxtStatus.Foreground = Brush("#38BDF8");
                break;
            case "speed":
                TxtStatus.Text = S("status_speed");
                TxtStatus.Foreground = Brush("#4ADE80");
                break;
            default:
                TxtStatus.Text = S("status_stock");
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
            TxtFeedback.Text = busy ? S("busy") : S("ready");
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
        var lang = _lang;
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
        var elevate = action is not ("support" or "vram" or "gpu-check" or "status")
                      && ElevateActions.Contains(action);
        await ExecuteAsync(action, elevate, visible: false).ConfigureAwait(true);
    }

    private async void BtnBench_Click(object sender, RoutedEventArgs e)
    {
        if (_busy) return;
        if (sender is not Button btn || btn.Tag is not string action) return;
        var multi = action == "bench-multi";
        var msg = multi ? S("bench_multi_confirm") : S("bench_confirm");
        if (MessageBox.Show(msg, "Ollama Turbo", MessageBoxButton.YesNo, MessageBoxImage.Question)
            != MessageBoxResult.Yes) return;
        await ExecuteAsync(action, elevate: true, visible: true, ctx: _ctx).ConfigureAwait(true);
    }

    private async Task ExecuteAsync(string action, bool elevate, bool visible, int ctx = 0)
    {
        var lang = _lang;
        var ctxUse = ctx > 0 ? ctx : _ctx;

        SetBusy(true);
        AppendLog($"\n===== {action} =====");

        try
        {
            var progress = new Progress<string>(AppendLog);
            var result = await Task.Run(async () =>
                await TurboEngine.RunActionAsync(
                    action, elevate, lang: lang, ctx: visible ? ctxUse : 0,
                    visibleConsole: visible, progress: progress).ConfigureAwait(false)
            ).ConfigureAwait(true);

            AppendLog(result.Output);
            AppendLog($"exit={result.ExitCode}");
            TxtFeedback.Text = result.ExitCode switch
            {
                0 => string.Format(S("done"), action),
                -1 => S("uac_refused"),
                _ => $"exit {result.ExitCode}"
            };
            RefreshStatus();
            RefreshGpu();
        }
        catch (Exception ex)
        {
            AppendLog("ERROR: " + ex.Message);
            TxtFeedback.Text = S("err");
            MessageBox.Show(ex.Message, "Ollama Turbo", MessageBoxButton.OK, MessageBoxImage.Error);
        }
        finally
        {
            SetBusy(false);
        }
    }

    private void BtnQuit_Click(object sender, RoutedEventArgs e) => Close();
}
