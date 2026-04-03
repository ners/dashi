const { execSync } = require('child_process');
const { readFileSync, writeFileSync, rmSync } = require('node:fs');
const { join } = require('node:path');

function isVersionGreaterThan(a: string, b: string): boolean {
  const partsA = a.split(".").map(Number);
  const partsB = b.split(".").map(Number);
  const len = Math.max(partsA.length, partsB.length);

  for (let i = 0; i < len; i++) {
    const numA = partsA[i] ?? 0;
    const numB = partsB[i] ?? 0;
    if (numB !== numA) return numB > numA;
  }

  return false;
}

function getCabalVersion(filePath: string): string {
  const content = readFileSync(filePath, "utf-8");
  const match = content.match(/^\s*version\s*:\s*(.+?)\s*$/im);
  return match[1];
}

function setCabalField(filePath: string, field: string, value: string): void {
  const content = readFileSync(filePath, "utf-8");
  const updated = content.replace(
    new RegExp(`^(\\s*${field}\\s*:\\s*)(.+?)\\s*$`, "im"),
    `$1${value}`
  );
  writeFileSync(filePath, updated, "utf-8");
}

function setFlakeInputTag(filePath: string, inputName: string, tag: string): void {
  const content = readFileSync(filePath, "utf-8");
  const updated = content.replace(
    new RegExp(`(${inputName}\\s*=\\s*\\{[^}]*url\\s*=\\s*"[^"]+/)([^/"]+)(")`),
    `$1${tag}$3`
  );
  writeFileSync(filePath, updated, "utf-8");
}

async function getLatestRelease(owner: string, repo: string): Promise<string> {
  const res = await fetch(`https://api.github.com/repos/${owner}/${repo}/releases/latest`);
  if (!res.ok) throw new Error(`GitHub API error: ${res.status}`);
  return await res.json();
}

const owner = "phosphor-icons";
const repo = "web";
const cabalFile = join(__dirname, 'phosphor-icons.cabal');
const flakeFile = join(__dirname, '../flake.nix');

const main = async () => {
    const githubRelease = await getLatestRelease(owner, repo);
    const githubVersion = githubRelease.tag_name.slice(1);
    const cabalVersion = getCabalVersion(cabalFile);

    if (!isVersionGreaterThan(cabalVersion, githubVersion)) {
        console.log(`Latest released version (${githubVersion}) is not greater than Cabal version (${cabalVersion})!`);
        process.exit(1);
    }

    const dir = execSync('mktemp -d').toString().trim();
    execSync(`git clone --recurse-submodules --depth 1 --branch v${githubVersion} https://github.com/${owner}/${repo} ${dir}`);
    const { icons } = require(`${dir}/core/src/icons.ts`);
    const package = JSON.parse(readFileSync(`${dir}/package.json`, "utf-8"));
    rmSync(dir, { recursive: true, force: true });

    setCabalField(cabalFile, "version", package.version);
    setCabalField(cabalFile, "description", package.description);
    setFlakeInputTag(flakeFile, "phosphor-icons-web", githubRelease.tag_name);

    const lines: string[] = [];

    lines.push("module Web.Font.Phosphor where");
    lines.push("");

    const [first, ...rest] = icons;
    lines.push("data Phosphor");
    lines.push(`    = ${first.pascal_name}`);
    for (const icon of rest) {
      lines.push(`    | ${icon.pascal_name}`);
    }
    lines.push("    deriving (Eq, Bounded, Enum)");
    lines.push("");

    lines.push("char :: Phosphor -> Char");
    for (const icon of icons) {
      lines.push(`char ${icon.pascal_name} = '\\${icon.codepoint}'`);
    }
    lines.push("");

    let content = lines.join("\n");
    writeFileSync(join(__dirname, "src", "Web", "Font", "Phosphor.hs"), content, "utf-8");
}

main()
