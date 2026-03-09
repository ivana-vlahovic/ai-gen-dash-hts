# HTS Media — Campaign Risk Radar
### Take-Home Exercise | Hopper Technology Solutions · Strategy & Operations

**Submitted by:** Ivana Vlahovic  
**Role:** Senior Strategy & Operations Manager, HTS Media  
**Date:** March 2026

---

## What This Is

A lightweight campaign operations dashboard built as part of Hopper's take-home exercise for the HTS Media Strategy & Operations role. The prompt asked for a rapid prototype that surfaces at-risk campaigns, explains *why* they're at risk in plain language, and recommends a concrete next action — all without requiring any engineering support.

**Live demo:** [your GitHub Pages URL here]

---

## What It Does

**Executive Overview tab**
- 8 key portfolio metrics (at-risk count, pacing ratio, % budget spent, budget at risk, total budget, CAC, CTR, CVR) with Day-over-Day and Week-over-Week change indicators
- Spend trend chart (daily or weekly, breakable by platform or channel)
- % Budget Spent pacing bars by platform or channel
- Top 3 active performer cards scored by pacing ratio, CAC, and risk status
- Campaign Risk Summary table with sortable columns, plain-language risk reason, and one recommended action per campaign

**Campaign Drill-Down tab**
- Filtered portfolio metrics for any subset of campaigns
- Stacked bar + CAC overlay combo chart (daily or weekly, by platform / channel / campaign)
- Daily Level Campaign Data table
- Weekly Level Campaign Data table with cumulative % budget spent

**Filters available on both tabs:** Platform · Channel · Risk Level · Status · Campaign · Date range

---

## Build Approach

| Layer | Choice | Rationale |
|---|---|---|
| Prototype format | Single self-contained HTML file | No backend required; instantly shareable via URL; recruiter can open it in any browser |
| Data | Synthetic — 15 campaigns × 14 days | Mirrors real-world schema fragmentation across iOS, Android, Web, OTT, Podcast sources |
| Risk logic | Rule-based (pacing ratio vs. elapsed time + ops notes) | Sufficient for prototype; fast to reason about; extensible to ML |
| Charts | Chart.js (CDN) | Lightweight, no build step |
| Hosting | GitHub Pages | Free, persistent URL, version-controlled |

**AI usage:** Used to accelerate rule-to-language translation (risk reasons → plain English recommended actions) and front-end scaffolding. All analytical logic, metric definitions, and risk scoring written by hand.

---

## Key Assumptions

1. **Linear pacing baseline** — campaigns are expected to spend evenly across their flight window. Deviation from this triggers pacing risk flags.
2. **Ops notes carry signal** — status fields like "Waiting on Assets" or "Launch Delayed" are treated as hard risk indicators, not just metadata.
3. **Mid-flight intervention window is the highest-value moment** — the dashboard prioritizes campaigns where action can still affect delivery outcomes.
4. **Revenue proxied by spend-to-date** — without live revenue data, delivered spend is used as the closest available proxy for monetization performance.

---

## Risk Scoring Logic

Each campaign receives a composite score:

```
Risk Score = Pacing Deviation + Ops Status Flag + Days Remaining Pressure
```

| Signal | High Risk Threshold |
|---|---|
| Pacing ratio | < 0.6× (spending significantly below timeline pace) |
| Status | "Launch Delayed", "Waiting on Assets", "Paused" |
| Budget burn | > 90% spent with > 7 days remaining |

---

## If This Were Production

A few things I'd add with more time and real data access:

- **Predictive delivery model** replacing rule-based thresholds — train on historical campaign completion rates by platform, channel, and budget tier
- **Portfolio-level revenue-at-risk aggregate** — tie delivery risk directly to projected revenue shortfall in dollars, not just budget
- **Slack/email alerting** on threshold breach — ops shouldn't have to open a dashboard to catch a risk
- **Feedback loop** — track whether recommended actions were taken and whether they improved delivery outcomes; use this to improve future recommendations
- **BigQuery + Looker implementation** — the SQL schema and UNION ALL view included in the companion Google Sheet is production-ready; this prototype would connect directly to that layer

---

## Files

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

## Does the Dashboard Require Google Sheets or the Excel File?

**No — the dashboard is fully self-contained.** All 15 campaigns and 14 days of synthetic data are embedded directly in `index.html` as JavaScript constants. There is no API call, no database connection, no Google Sheets dependency. You can open it in any browser with no internet connection (except to load Chart.js from CDN and the font from Google Fonts).

The Excel file and SQL are included separately as **supporting artifacts** to show the full data layer design — they demonstrate what the production version of this system would look like with real data sources wired in.

---
---

*Built for Hopper HTS Media take-home exercise. Synthetic data only — no proprietary or confidential information.*
