// Runs the real GitHub CLI as the work account inside WORK_ROOT and the personal account elsewhere,
// by passing that account's stored token in GH_TOKEN, so the globally active account never changes.
use std::env;
use std::process::{Command, exit};

const REAL_GH: &str = r"C:\Program Files\GitHub CLI\gh.exe";
const WORK_ROOT: &str = r"d:\files\dev\aistudio";

fn main() {
    let args: Vec<_> = env::args_os().skip(1).collect();
    let mut gh = Command::new(REAL_GH);
    gh.args(&args);

    let passthrough = args.first().is_some_and(|a| a == "auth")
        || env::var_os("GH_TOKEN").is_some()
        || env::var_os("GITHUB_TOKEN").is_some();
    if !passthrough {
        let cwd = env::current_dir()
            .map(|p| p.to_string_lossy().to_lowercase().replace('/', "\\"))
            .unwrap_or_default();
        let cwd = cwd.trim_end_matches('\\');
        let is_work = cwd == WORK_ROOT || cwd.starts_with(&format!("{WORK_ROOT}\\"));
        let account = if is_work { "sudharsan-aistudio" } else { "Bug-Finderr" };

        let token = Command::new(REAL_GH)
            .args(["auth", "token", "--hostname", "github.com", "--user", account])
            .output()
            .unwrap_or_else(|e| fail(&e.to_string()));
        if !token.status.success() {
            fail(&format!("no stored token for {account}; run: gh auth login"));
        }
        gh.env("GH_TOKEN", String::from_utf8_lossy(&token.stdout).trim());
    }

    let status = gh.status().unwrap_or_else(|e| fail(&e.to_string()));
    exit(status.code().unwrap_or(1));
}

fn fail(message: &str) -> ! {
    eprintln!("gh-route: {message}");
    exit(1);
}
