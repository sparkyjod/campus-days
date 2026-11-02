#!/bin/bash
# Deploy the Campus Days web export to the existing Vercel project "campus-days"
# (team: sparkyjods-projects). Requires the official Vercel CLI (npm i -g vercel)
# logged into the same account. The Godot build uses NO threads
# (variant/thread_support=false), so no COOP/COEP headers are required.
set -e
cd "$(dirname "$0")/build/web"
vercel link --yes --project campus-days --scope sparkyjods-projects
vercel deploy --prod
