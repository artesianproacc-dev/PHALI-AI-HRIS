#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
for name in SUPABASE_PROJECT_REF SUPABASE_ACCESS_TOKEN SUPABASE_DB_PASSWORD SUPABASE_URL SUPABASE_ANON_KEY SUPABASE_SERVICE_ROLE_KEY GROQ_API_KEY; do
  if [[ -z "${!name:-}" ]]; then echo "Variabel belum tersedia: $name. Lihat DEPLOY.md"; exit 1; fi
done
command -v gh >/dev/null || { echo 'Pasang GitHub CLI; lihat DEPLOY.md'; exit 1; }
gh auth status
npm ci
npm run lint
npm test
npm run test:sql
VITE_SUPABASE_URL="$SUPABASE_URL" VITE_SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" npm run build
npx supabase link --project-ref "$SUPABASE_PROJECT_REF"
# Seed explicitly opt-in because seed.sql replaces synthetic records.
if [[ "${HR_INSIGHT_SEED:-}" == "yes" ]]; then npx supabase db push --include-seed; else npx supabase db push; fi
npx supabase functions deploy ai-narasi --use-api
npx supabase functions deploy ai-chat --use-api
# Secrets through temporary protected file; never command line or git.
secret_file=$(mktemp)
chmod 600 "$secret_file"
trap 'rm -f "$secret_file"' EXIT
printf 'GROQ_API_KEY=%s\nGROQ_MODEL=%s\n' "$GROQ_API_KEY" "${GROQ_MODEL:-openai/gpt-oss-120b}" > "$secret_file"
npx supabase secrets set --env-file "$secret_file"
node scripts/create-demo-users.mjs
if [[ ! -d .git ]]; then git init -b main; fi
git add .
git diff --cached --quiet || git commit -m "Bangun PHALI AI-HRIS PWA"
if ! git remote get-url origin >/dev/null 2>&1; then gh repo create hr-insight --public --source=. --remote=origin; fi
printf '%s' "$SUPABASE_URL" | gh secret set VITE_SUPABASE_URL
printf '%s' "$SUPABASE_ANON_KEY" | gh secret set VITE_SUPABASE_ANON_KEY
repo=$(gh repo view --json nameWithOwner --jq .nameWithOwner)
if gh api "repos/$repo/pages" >/dev/null 2>&1; then gh api --method PUT "repos/$repo/pages" -f build_type=workflow; else gh api --method POST "repos/$repo/pages" -f build_type=workflow; fi
git push -u origin main
echo "Pantau: gh run list; gh run watch. Setelah berhasil, URL ada di Settings > Pages."
