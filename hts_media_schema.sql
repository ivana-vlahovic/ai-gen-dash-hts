-- ═══════════════════════════════════════════════════════════════════════════
-- HTS Media · Campaign Risk Radar — Data Layer SQL
-- Author: Ivana Vlahovic | Take-Home Exercise | Hopper Technology Solutions
-- Purpose: Production-ready BigQuery schema for multi-platform campaign data
--          with UNION ALL consolidation view and weekly rollup aggregation
-- ═══════════════════════════════════════════════════════════════════════════


-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION 1: RAW SOURCE TABLES
-- Each platform exports differently — column names are intentionally preserved
-- as-is to reflect real-world schema fragmentation across media sources.
-- ─────────────────────────────────────────────────────────────────────────────

-- iOS (TikTok, Meta, Pinterest)
CREATE OR REPLACE TABLE `hts_media.raw_ios` (
  date                DATE        NOT NULL,
  campaign_id         STRING      NOT NULL,
  campaign_name       STRING,
  ad_source           STRING,                  -- platform/vendor name
  flight_start        DATE,
  flight_end          DATE,
  total_budget_usd    FLOAT64,
  ad_spend            FLOAT64,                 -- daily spend
  impressions_count   INT64,
  tap_count           INT64,                   -- iOS-specific: "taps" not clicks
  conversions         INT64,
  ops_notes           STRING                   -- campaign manager freeform notes
);

-- Android (Meta, LinkedIn, TikTok)
CREATE OR REPLACE TABLE `hts_media.raw_android` (
  date                    DATE        NOT NULL,
  campaign_id             STRING      NOT NULL,
  campaign_name           STRING,
  ad_platform             STRING,
  campaign_start_date     DATE,
  campaign_end_date       DATE,
  total_campaign_budget   FLOAT64,
  daily_budget_consumed   FLOAT64,
  reach                   INT64,               -- Android: "reach" not impressions
  link_clicks             INT64,
  installs                INT64,               -- Android tracks installs separately
  conversions             INT64,
  status_flag             STRING
);

-- Web (Google Display, Search, Programmatic)
CREATE OR REPLACE TABLE `hts_media.raw_web` (
  date                DATE        NOT NULL,
  campaign_id         STRING      NOT NULL,
  campaign_name       STRING,
  source              STRING,
  start_date          DATE,
  end_date            DATE,
  budget_total        FLOAT64,
  cost                FLOAT64,                 -- Web: "cost" not spend
  pageviews           INT64,
  sessions            INT64,
  goal_completions    INT64,                   -- Web: conversions via GA goals
  -- NOTE: no status column in this source — inferred from ops_notes or external
  ops_notes           STRING
);

-- OTT / Connected TV (Hulu, YouTube, Programmatic Video)
CREATE OR REPLACE TABLE `hts_media.raw_ott_tv` (
  date                DATE        NOT NULL,
  campaign_id         STRING      NOT NULL,
  campaign_name       STRING,
  network             STRING,
  flight_start        DATE,
  flight_end          DATE,
  total_budget        FLOAT64,
  media_cost          FLOAT64,
  airings             INT64,                   -- OTT: ad "airings" not impressions
  completed_views     INT64,
  vcr_pct             FLOAT64,                 -- video completion rate (0–1)
  conversions         INT64,
  campaign_status     STRING
);

-- Podcast (Spotify, iHeartRadio, Host-Read Deals)
CREATE OR REPLACE TABLE `hts_media.raw_podcast` (
  date                    DATE        NOT NULL,
  campaign_id             STRING      NOT NULL,
  campaign_name           STRING,
  network                 STRING,
  episode_start_date      DATE,
  episode_end_date        DATE,
  contract_value          FLOAT64,             -- Podcast: "contract value" not budget
  episode_spend           FLOAT64,
  downloads               INT64,               -- Podcast: "downloads" not impressions
  host_reads              INT64,               -- number of host read ad slots
  promo_code_redemptions  INT64,               -- Podcast: attribution via promo codes
  campaign_status         STRING
);


-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION 2: CONSOLIDATED DAILY VIEW
-- Normalizes all five sources into a single canonical schema.
-- Field mapping comments explain each translation decision.
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE VIEW `hts_media.consolidated_daily` AS

SELECT
  date,
  'ios'                       AS platform,
  campaign_id,
  campaign_name,
  'social'                    AS channel,          -- iOS sources are social-first
  ad_source                   AS source,
  flight_start                AS camp_start,
  flight_end                  AS camp_end,
  total_budget_usd            AS total_budget,
  ad_spend                    AS daily_spend,
  impressions_count           AS impressions,
  tap_count                   AS clicks,           -- taps mapped to clicks
  conversions,
  ops_notes                   AS notes
FROM `hts_media.raw_ios`

UNION ALL

SELECT
  date,
  'android'                   AS platform,
  campaign_id,
  campaign_name,
  'social'                    AS channel,
  ad_platform                 AS source,
  campaign_start_date         AS camp_start,
  campaign_end_date           AS camp_end,
  total_campaign_budget       AS total_budget,
  daily_budget_consumed       AS daily_spend,
  reach                       AS impressions,      -- reach as impressions proxy
  link_clicks                 AS clicks,
  conversions,
  status_flag                 AS notes
FROM `hts_media.raw_android`

UNION ALL

SELECT
  date,
  'web'                       AS platform,
  campaign_id,
  campaign_name,
  -- Channel inference: Google search vs display based on source name
  CASE
    WHEN LOWER(source) LIKE '%search%' OR LOWER(source) LIKE '%sem%' THEN 'search'
    ELSE 'display'
  END                         AS channel,
  source,
  start_date                  AS camp_start,
  end_date                    AS camp_end,
  budget_total                AS total_budget,
  cost                        AS daily_spend,
  pageviews                   AS impressions,      -- pageviews as impressions proxy
  sessions                    AS clicks,           -- sessions as click proxy
  goal_completions            AS conversions,
  ops_notes                   AS notes
FROM `hts_media.raw_web`

UNION ALL

SELECT
  date,
  'ott_tv'                    AS platform,
  campaign_id,
  campaign_name,
  'video'                     AS channel,
  network                     AS source,
  flight_start                AS camp_start,
  flight_end                  AS camp_end,
  total_budget,
  media_cost                  AS daily_spend,
  airings                     AS impressions,      -- airings as impressions proxy
  completed_views             AS clicks,           -- completed views as engagement proxy
  conversions,
  campaign_status             AS notes
FROM `hts_media.raw_ott_tv`

UNION ALL

SELECT
  date,
  'podcast'                   AS platform,
  campaign_id,
  campaign_name,
  'audio'                     AS channel,
  network                     AS source,
  episode_start_date          AS camp_start,
  episode_end_date            AS camp_end,
  contract_value              AS total_budget,
  episode_spend               AS daily_spend,
  downloads                   AS impressions,      -- downloads as impressions proxy
  host_reads                  AS clicks,           -- host reads as engagement proxy
  promo_code_redemptions      AS conversions,      -- promo redemptions as conversion proxy
  campaign_status             AS notes
FROM `hts_media.raw_podcast`
;


-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION 3: WEEKLY ROLLUP AGGREGATION
-- Aggregates consolidated_daily to ISO week level.
-- Includes pacing ratio, CAC, CTR, CVR as derived metrics.
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE TABLE `hts_media.weekly_rollup`
PARTITION BY DATE_TRUNC(week_start, MONTH)
CLUSTER BY platform, channel
AS
WITH base AS (
  SELECT
    DATE_TRUNC(date, WEEK(MONDAY))             AS week_start,
    platform,
    channel,
    source,
    campaign_id,
    campaign_name,
    MAX(camp_start)                            AS camp_start,
    MAX(camp_end)                              AS camp_end,
    MAX(total_budget)                          AS total_budget,
    SUM(daily_spend)                           AS weekly_spend,
    SUM(impressions)                           AS weekly_impressions,
    SUM(clicks)                                AS weekly_clicks,
    SUM(conversions)                           AS weekly_conversions,
    MAX(notes)                                 AS latest_notes
  FROM `hts_media.consolidated_daily`
  GROUP BY 1,2,3,4,5,6
),
with_cumulative AS (
  SELECT
    *,
    SUM(weekly_spend) OVER (
      PARTITION BY campaign_id
      ORDER BY week_start
      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )                                          AS cumulative_spend,

    -- Pacing ratio: actual % spent vs expected % of flight elapsed
    SAFE_DIVIDE(
      SUM(weekly_spend) OVER (
        PARTITION BY campaign_id
        ORDER BY week_start
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
      ),
      NULLIF(total_budget, 0)
    ) /
    NULLIF(
      DATE_DIFF(week_start, camp_start, DAY) /
      NULLIF(DATE_DIFF(camp_end, camp_start, DAY), 0),
      0
    )                                          AS pacing_ratio

  FROM base
)
SELECT
  week_start,
  DATE_ADD(week_start, INTERVAL 6 DAY)        AS week_end,
  platform,
  channel,
  source,
  campaign_id,
  campaign_name,
  camp_start,
  camp_end,
  total_budget,
  weekly_spend,
  cumulative_spend,
  SAFE_DIVIDE(cumulative_spend, total_budget)  AS pct_budget_spent,
  pacing_ratio,
  weekly_impressions,
  weekly_clicks,
  weekly_conversions,
  SAFE_DIVIDE(weekly_clicks, weekly_impressions)       AS ctr,
  SAFE_DIVIDE(weekly_conversions, weekly_clicks)       AS cvr,
  SAFE_DIVIDE(weekly_spend, weekly_conversions)        AS cac,
  latest_notes
FROM with_cumulative
ORDER BY week_start, campaign_id
;


-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION 4: RISK CLASSIFICATION VIEW
-- Applies rule-based risk scoring on top of weekly_rollup.
-- Mirrors the logic used in the prototype dashboard.
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE VIEW `hts_media.campaign_risk_flags` AS

WITH latest_week AS (
  -- Get the most recent week per campaign
  SELECT *
  FROM `hts_media.weekly_rollup`
  QUALIFY ROW_NUMBER() OVER (PARTITION BY campaign_id ORDER BY week_start DESC) = 1
),
risk_scored AS (
  SELECT
    *,
    DATE_DIFF(camp_end, CURRENT_DATE(), DAY)   AS days_remaining,
    DATE_DIFF(camp_end, camp_start, DAY)        AS total_flight_days,

    -- Rule 1: Over-paced with days remaining (burn risk)
    CASE WHEN pct_budget_spent > 0.9
          AND DATE_DIFF(camp_end, CURRENT_DATE(), DAY) > 7
    THEN TRUE ELSE FALSE END                   AS flag_over_paced,

    -- Rule 2: Under-paced (delivery risk)
    CASE WHEN pacing_ratio < 0.6
          AND DATE_DIFF(camp_end, CURRENT_DATE(), DAY) > 0
    THEN TRUE ELSE FALSE END                   AS flag_under_paced,

    -- Rule 3: Stalled (ops blocker in notes)
    CASE WHEN REGEXP_CONTAINS(
      LOWER(COALESCE(latest_notes,'')),
      r'(delay|asset|pause|pending|hold|approval|wait)'
    ) THEN TRUE ELSE FALSE END                 AS flag_ops_blocker,

    -- Rule 4: End-date pressure (< 7 days left, < 80% spent)
    CASE WHEN DATE_DIFF(camp_end, CURRENT_DATE(), DAY) < 7
          AND pct_budget_spent < 0.8
    THEN TRUE ELSE FALSE END                   AS flag_deadline_pressure

  FROM latest_week
)
SELECT
  campaign_id,
  campaign_name,
  platform,
  channel,
  camp_start,
  camp_end,
  days_remaining,
  total_budget,
  cumulative_spend,
  ROUND(pct_budget_spent * 100, 1)             AS pct_budget_spent,
  ROUND(pacing_ratio, 2)                       AS pacing_ratio,
  ROUND(ctr * 100, 3)                          AS ctr_pct,
  ROUND(cvr * 100, 2)                          AS cvr_pct,
  ROUND(cac, 2)                                AS cac,
  latest_notes,

  -- Composite risk level
  CASE
    WHEN flag_over_paced OR (flag_under_paced AND flag_ops_blocker) THEN 'high'
    WHEN flag_under_paced OR flag_ops_blocker OR flag_deadline_pressure THEN 'medium'
    WHEN days_remaining <= 0 OR pct_budget_spent >= 0.99 THEN 'done'
    ELSE 'low'
  END                                          AS risk_level,

  -- Plain-language risk reason
  CASE
    WHEN flag_over_paced
      THEN 'Budget exhaustion risk — spending ahead of pace with days remaining'
    WHEN flag_under_paced AND flag_ops_blocker
      THEN 'Critical: ops blocker compressing delivery window'
    WHEN flag_ops_blocker
      THEN 'Ops blocker detected in campaign notes — delivery stalled'
    WHEN flag_under_paced
      THEN 'Under-pacing — spend significantly below expected trajectory'
    WHEN flag_deadline_pressure
      THEN 'End-date pressure — less than 7 days to deliver remaining budget'
    WHEN days_remaining <= 0 OR pct_budget_spent >= 0.99
      THEN 'Campaign completed'
    ELSE 'On track — pacing within expected range'
  END                                          AS risk_reason

FROM risk_scored
ORDER BY
  CASE risk_level WHEN 'high' THEN 0 WHEN 'medium' THEN 1 WHEN 'low' THEN 2 ELSE 3 END,
  campaign_id
;
