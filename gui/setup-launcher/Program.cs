using System.Diagnostics;
using System.Reflection;
using System.Windows.Forms;

namespace OllamaTurboRTX.Setup;

internal static class Program
{
    [STAThread]
    private static int Main()
    {
        Application.SetHighDpiMode(HighDpiMode.SystemAware);
        Application.EnableVisualStyles();
        Application.SetCompatibleTextRenderingDefault(false);

        try
        {
            var msiPath = ResolveMsiPath();
            var psi = new ProcessStartInfo
            {
                FileName = "msiexec.exe",
                Arguments = $"/i \"{msiPath}\"",
                UseShellExecute = true
            };
            using var p = Process.Start(psi);
            return p is null ? 1 : 0;
        }
        catch (Exception ex)
        {
            MessageBox.Show(
                "Unable to start the Ollama-Turbo-RTX installer.\n\n" + ex.Message,
                "Ollama-Turbo-RTX Setup",
                MessageBoxButtons.OK,
                MessageBoxIcon.Error);
            return 1;
        }
    }

    private static string ResolveMsiPath()
    {
        // 1) MSI next to this EXE (dev / dual-file release)
        var beside = Path.Combine(AppContext.BaseDirectory, "OllamaTurboRTX-Setup.msi");
        if (File.Exists(beside))
            return beside;

        // 2) Embedded payload extracted to temp
        var asm = Assembly.GetExecutingAssembly();
        var name = asm.GetManifestResourceNames()
            .FirstOrDefault(n => n.EndsWith("OllamaTurboRTX-Setup.msi", StringComparison.OrdinalIgnoreCase))
            ?? throw new FileNotFoundException("Embedded MSI payload missing.");

        var dir = Path.Combine(Path.GetTempPath(), "OllamaTurboRTX-Setup");
        Directory.CreateDirectory(dir);
        var dest = Path.Combine(dir, "OllamaTurboRTX-Setup.msi");
        using (var src = asm.GetManifestResourceStream(name)!)
        using (var dst = File.Create(dest))
            src.CopyTo(dst);
        return dest;
    }
}
