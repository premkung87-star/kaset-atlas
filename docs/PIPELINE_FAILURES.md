# Pipeline Failures Log

> Logs of any pipeline run that halted before publication.
>
> Format: most recent first.

---

## (No failures yet — pipeline initialized 2026-04-29)

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
