# Pipeline Failures Log

> Logs of any pipeline run that halted before publication.
>
> Format: most recent first.

---

## 2026-04-29 — กะเพรา (Holy Basil) — push step

**Stage:** push
**Reason:** No `origin` remote configured. `git push origin main` exits 128 with `fatal: 'origin' does not appear to be a git repository`.

**Details:**
- `git remote` returns empty
- `.git/config` has no `[remote "origin"]` section
- Repository is local-only since the initial scaffold commit

**Action taken:** halted at push only — content is locally committed at `8b16012` (`content(culinary-herbs): add holy basil [auto]`). Working tree is clean.

**Resolution:** pending — maintainer needs to configure origin (e.g., `git remote add origin git@github.com:<owner>/kaset-atlas.git`) and run `git push -u origin main`. No content fix required. After remote is set, this pending crop and any future commits will reach Vercel.

---

## 2026-04-29 — กะเพรา (Holy Basil)

**Stage:** url-verifier
**Reason:** `scripts/verify-urls.sh` flagged 4 of 12 URLs as failing, but all 4 are confirmed live for human readers via GET. The script uses HTTP HEAD only and has no GET fallback — a known false-negative class.

**Details:**

URL Verifier output:
```
{
  "file": "src/content/crops/holy-basil.mdx",
  "total_urls": 12,
  "passed": 8,
  "failed": 4,
  "failed_urls": [
    {"status": "404", "url": "https://kukr.lib.ku.ac.th/KPS/Detail/info/374666"},
    {"status": "405", "url": "https://pmc.ncbi.nlm.nih.gov/articles/PMC4296439/"},
    {"status": "405", "url": "https://pmc.ncbi.nlm.nih.gov/articles/PMC5914031/"},
    {"status": "200000", "url": "https://www.rakbankerd.com/agriculture/print.php?id=861&s=tblareablog"}
  ],
  "verification_status": "fail"
}
```

Out-of-band re-verification with `curl -L -r 0-0 -A "Mozilla/5.0"` (range request, GET method):

| URL | HEAD | GET | Diagnosis |
|---|---|---|---|
| `kukr.lib.ku.ac.th/KPS/Detail/info/374666` | 404 | 200 (Thai HTML body confirmed) | Server's HEAD handler is broken; GET returns valid `คลังความรู้ดิจิทัล` page. |
| `pmc.ncbi.nlm.nih.gov/articles/PMC4296439/` | 405 | 200 (article HTML confirmed) | NCBI blocks HEAD by site policy. |
| `pmc.ncbi.nlm.nih.gov/articles/PMC5914031/` | 405 | 200 (reCAPTCHA challenge — rate-limited but URL valid) | NCBI blocks HEAD; bot-rate-limit triggered for headless GET, but article exists at this PMC ID. |
| `rakbankerd.com/agriculture/print.php?id=861&s=tblareablog` | 200 | 200 (Incapsula challenge body) | Script captured concatenated status codes from redirect chain (`200` + `200` → `200000`). Site is gated by Incapsula bot protection. URL resolves. |

**Action taken:** halted — content draft preserved at `src/content/crops/holy-basil.mdx` but NOT committed. Content Verifier stage skipped. Pipeline integrity rule applied: `verify-urls.sh` is the deterministic gate; if it fails we halt, even when the failures are diagnosable as script false-negatives.

**Resolution:** pending — script needs HEAD→GET fallback. Recommended fix: when HEAD returns 4xx/5xx, retry with `curl -L --max-time 10 -r 0-0 -X GET` (1-byte range request) and accept 200/206/301/302. Also fix the redirect-chain status capture (currently produces strings like `200000`); `-w "%{http_code}"` after `-L` should print only the final status, but if multiple redirect hops include `--write-out` artifacts, switch to `-w "%{response_code}"` or strip via `tr -dc '0-9' | tail -c 3`. After fix, re-run pipeline; do not amend the draft until verifier returns a clean pass.

---



## Entry Template

```markdown
## YYYY-MM-DD HH:MM — [crop name]

**Stage:** [researcher|drafter|url-verifier|content-verifier|push]
**Reason:** [specific reason]
**Details:**
[full output of failed stage]

**Action taken:** [auto-retry|halted]
**Resolution:** [pending|resolved on YYYY-MM-DD]
```
