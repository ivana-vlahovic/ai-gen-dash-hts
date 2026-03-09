# HTS Media — Campaign Risk Radar
### Take-Home Exercise | Hopper Technology Solutions · Strategy & Operations

**Submitted by:** Ivana Vlahovic  
**Role:** [Senior Strategy & Operations Manager, HTS Media](https://jobs.ashbyhq.com/hopper/8747aaef-aacc-4a31-9990-2d698557b1ab)  
**Date:** March 2026

---

## What This Is

A lightweight campaign operations dashboard built as part of Hopper's interview process. The prompt asked for a rapid prototype that surfaces at-risk campaigns, explains *why* they're at risk in plain language, and recommends a concrete next action — all within a 60-90 minute time frame and encouraged use of AI. I chose to use Claude as my main tool of creating the web app, with prompts to help refine logic and design choices. 

**Live demo:** [Dashboard link](https://ivana-vlahovic.github.io/ai-gen-dash-hts/) | **GitHub Link:** [Visit Repository](https://github.com/ivana-vlahovic/ai-gen-dash-hts)

---

## What It Does

**Executive Overview tab**
- Purpose: At a glance pulse check of media performance
- Key Features:
  - 8 key portfolio metrics (at-risk count, pacing ratio, % budget spent, budget at risk, total budget, CAC, CTR, CVR) with Day-over-Day and Week-over-Week change indicators
  - Spend trend chart (daily or weekly, breakable by platform or channel)
  - % Budget Spent pacing bars by platform or channel
  - Top 3 active performer cards scored by pacing ratio, CAC, and risk status
  - Campaign Risk Summary table with sortable columns, plain-language risk reason, and one recommended action per campaign

**Campaign Drill-Down tab**
- Purpose: Deep dive campaign analysis
- Key Features:
  - Filtered portfolio metrics for any subset of campaigns
  - Stacked bar + CAC overlay combo chart (daily or weekly, by platform / channel / campaign)
  - Daily Level Campaign Data table
  - Weekly Level Campaign Data table with cumulative % budget spent

**Filters available on both tabs:** Platform · Channel · Risk Level · Status · Campaign · Date range

---

## Who It's For

**Executive Overview tab**
- Decision Makers & Executives looking to understand the health of HTS media and where are quick opportunities to pivot or redirect based off risk factors
**Campaign Drill-Down tab**
- Campaign Managers looking to actively manage campaign at a more granular level

---

## Key Assumptions

1. **Linear pacing baseline** — campaigns are expected to spend evenly across their flight window. Deviation from this triggers pacing risk flags.
2. **Ops notes carry signal** — status fields like "Waiting on Assets" or "Launch Delayed" are treated as hard risk indicators, not just metadata.
3. **Mid-flight intervention window is the highest-value moment** — the dashboard prioritizes campaigns where action can still affect delivery outcomes.
4. **Revenue proxied by spend-to-date** — did not use revenue as an input, conversions are used as the closest available proxy for monetization performance.

---

## How It Was Built

### Build Approach

The dashboard is fully self-contained. All 15 campaigns and 14 days of synthetic data are embedded directly in `index.html` as JavaScript constants. There is no API call, no database connection, no Google Sheets dependency. You can open it in any browser with no internet connection (except to load Chart.js from CDN and the font from Google Fonts). The Excel file and SQL are included separately as **supporting artifacts** to show the full data layer design — they demonstrate what the production version of this system would look like with real data sources wired in.

**AI usage:** Used Claude as my coding output machine and accelerate rule-to-language translation (risk reasons → plain English recommended actions). Metric definitions, risk scoring, and UI design guided in iterative process via chat prompts.

Please see the summary table for a tech stack overview:

| Layer | Choice | Rationale |
|---|---|---|
| Underlying Data | AI Genereated — 15 campaigns × 14 days (see sample Excel file) | Mirrors real-world schema fragmentation across iOS, Android, Web, OTT, Podcast sources |
| Reporting Logic | Rule-based (pacing ratio vs. elapsed time + ops notes) | SQL based logic rules sufficient for prototype and basic analysis; extensible to more advanced predictive models |
| User Interface | Single self-contained HTML file | No backend required; instantly shareable via URL |
| Charts | Chart.js (CDN) | Lightweight, no build step |
| Hosting | GitHub Pages | Free, persistent URL, version-controlled |


### Risk Scoring Logic

Each campaign receives a composite score:

```
Risk Score = Pacing Deviation + Ops Status Flag + Days Remaining Pressure
```

| Signal | High Risk Threshold |
|---|---|
| Pacing ratio | < 0.6× (spending significantly below timeline pace) |
| Status | "Launch Delayed", "Waiting on Assets", "Paused" |
| Budget burn | > 90% spent with > 7 days remaining |


### Files

```
/
├── index.html               ← Full dashboard (rename from hts_campaign_radar_v6.html)
├── hts_media_schema.sql     ← BigQuery DDL: 5 raw source tables + consolidated view
│                               + weekly rollup + risk classification view
├── hts_campaign_data.xlsx   ← Synthetic campaign dataset (15 campaigns × 14 days)
│                               Tabs: consolidated_daily, raw_ios, raw_android,
│                               raw_web, raw_ott_tv, raw_podcast, weekly_rollup
└── README.md                ← This file
```
---

## If I Had More Time

A few things I'd add with more time and real data access:

- **Portfolio-level revenue-at-risk aggregate** — tie delivery risk directly to projected revenue shortfall in dollars, not just budget; better yet, a tie to a revenue OKR 
- **Slack/email alerting** on threshold breach — ops shouldn't have to open a dashboard to catch a risk
- **Feedback loop** — track whether recommended actions were taken and whether they improved delivery outcomes; use this to improve future recommendations
- **BigQuery + Looker implementation** — the SQL schema and UNION ALL view included in the companion Google Sheet is production-ready; this prototype would connect directly to that layer
- **Predictive delivery model** replacing rule-based thresholds — train on historical campaign completion rates by platform, channel, and budget tier

---

*Built for Hopper HTS Media take-home exercise. Synthetic data only — no proprietary or confidential information.*
