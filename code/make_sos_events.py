#!/usr/bin/env python3
"""
Build BIDS events.tsv files for the SOS fMRI task from PsychoPy output.

Reads each participant's .log (preferred, frame-accurate) and .csv (fallback /
cross-check) from the PsychoPy data folder, anchors all onsets to the first
scanner-trigger keypress, maps trial conditions via trialorder.csv, and writes
one BIDS-style events.tsv per participant plus a shared events.json and a
cross-participant QC summary.

Does not touch the raw PsychoPy files or any existing BIDS images -- only
writes new events files under OUT_DIR.
"""

import csv
import json
import re
import statistics
from pathlib import Path

PSYCHOPY_DIR = Path(
    "/Volumes/psych-cog/dsnlab/SOS/SOS-study-monash/psychopy/laptop_psychopy_all/psychopysosdata"
)
PROJECT_DIR = Path("/Volumes/psych-cog/dsnlab/TAG/projects/sos-bioreactivity")
TRIALORDER_CSV = PROJECT_DIR / "trialorder.csv"
OUT_DIR = PROJECT_DIR / "data" / "bids_events"

# Non-participant / unusable sessions, confirmed with the PI:
# - TAGxxx*, TAG999: test subjects (unfilled or sentinel participant-ID field
#   in the PsychoPy launch dialog), not real data.
# - TAG003: real participant, but logged 0 data rows (declined MRI, did not
#   complete the session -- consistent with this participant's established
#   exclusion from the biomarker analytic sample elsewhere in this project).
EXCLUDED_IDS = {"TAG999", "TAG003"}


def is_test_subject(participant_id):
    return participant_id.upper().startswith("TAGXXX")

EXPECTED_N_VOLUMES = 242
EXPECTED_TR = 2.0
EXPECTED_RUN_DURATION = EXPECTED_N_VOLUMES * EXPECTED_TR  # 484.0 s
FINAL_REST_DURATION = 10.98693  # hard-coded in sos_task.py (routineTimer.add)

CONDITION_TO_TRIAL_TYPE = {
    "1": "other",
    "2": "self_disconnected",
    "3": "self_connected",
}

LOG_LINE_RE = re.compile(r"^\s*([\d.]+)\s+(EXP|DATA|WARNING)\s+(.*)$")
NEW_TRIAL_RE = re.compile(r"^New trial \(rep=\d+, index=(\d+)\):")
AUTODRAW_RE = re.compile(r"^(\w+): autoDraw = (True|False)$")


def load_trialorder(path):
    """Fixed, sequential trial order -- identical for every participant."""
    with open(path, newline="") as f:
        rows = list(csv.DictReader(f, delimiter="\t"))
    for i, row in enumerate(rows):
        row["trial_index"] = i
        row["trial_type"] = CONDITION_TO_TRIAL_TYPE[row["Condition"]]
    return rows


def parse_log(path):
    """Return (trigger_time, list of (timestamp, level, message)) tuples."""
    lines = []
    trigger_time = None
    with open(path, encoding="utf-8", errors="replace") as f:
        for raw_line in f:
            m = LOG_LINE_RE.match(raw_line)
            if not m:
                continue
            t, level, msg = float(m.group(1)), m.group(2), m.group(3)
            lines.append((t, level, msg))
            if trigger_time is None and level == "DATA" and msg == "Keypress: apostrophe":
                trigger_time = t
    if trigger_time is None:
        raise ValueError(f"No scanner trigger keypress found in {path}")
    return trigger_time, lines


def first_after(lines, start_idx, component, state):
    """First (idx, time) where `component: autoDraw = state` occurs at/after start_idx."""
    for i in range(start_idx, len(lines)):
        t, level, msg = lines[i]
        if level != "EXP":
            continue
        m = AUTODRAW_RE.match(msg)
        if m and m.group(1) == component and m.group(2) == state:
            return i, t
    return None, None


def extract_precise_events(lines, trigger_time, n_trials):
    """Walk the log once, pulling precise onset/offset for each rest + block."""
    # index each "New trial" line by its trial index
    new_trial_idx = {}
    for i, (t, level, msg) in enumerate(lines):
        if level != "EXP":
            continue
        m = NEW_TRIAL_RE.match(msg)
        if m:
            new_trial_idx[int(m.group(1))] = i

    events = []
    for trial_i in range(n_trials):
        start = new_trial_idx.get(trial_i)
        if start is None:
            raise ValueError(f"Could not find 'New trial' log entry for trial index {trial_i}")

        rest_on_i, rest_on_t = first_after(lines, start, "cross", "True")
        rest_off_i, rest_off_t = first_after(lines, rest_on_i, "cross", "False")
        block_on_i, block_on_t = first_after(lines, rest_off_i, "clip", "True")
        block_off_i, block_off_t = first_after(lines, block_on_i, "clip", "False")

        if None in (rest_on_t, rest_off_t, block_on_t, block_off_t):
            raise ValueError(f"Missing autoDraw transition for trial index {trial_i}")

        events.append({
            "trial_index": trial_i,
            "rest_onset": round(rest_on_t - trigger_time, 3),
            "rest_duration": round(rest_off_t - rest_on_t, 3),
            "block_onset": round(block_on_t - trigger_time, 3),
            "block_duration": round(block_off_t - block_on_t, 3),
        })

    # final rest_end (outside the trial loop -- uses cross_end, not cross)
    last_block_off_i = block_off_i
    rest_end_on_i, rest_end_on_t = first_after(lines, last_block_off_i, "cross_end", "True")
    rest_end_off_i, rest_end_off_t = first_after(lines, rest_end_on_i, "cross_end", "False")
    if None in (rest_end_on_t, rest_end_off_t):
        raise ValueError("Missing final cross_end autoDraw transitions")

    final_rest = {
        "onset": round(rest_end_on_t - trigger_time, 3),
        "duration": round(rest_end_off_t - rest_end_on_t, 3),
    }
    return events, final_rest


def parse_csv_for_comparison(path):
    """Pull the CSV's own block_onset/block_duration (logged pre-movie-load) per trial."""
    with open(path, newline="") as f:
        rows = list(csv.DictReader(f))
    trial_rows = [r for r in rows if r.get("trials_loop.thisTrialN") not in (None, "")]
    out = []
    for r in trial_rows:
        out.append({
            "trial_index": int(float(r["trials_loop.thisTrialN"])),
            "block_onset": float(r["block_onset"]),
            "block_duration": float(r["block_duration"]),
        })
    return out


def build_events_rows(trialorder, precise_events, final_rest):
    rows = []
    for trial, ev in zip(trialorder, precise_events):
        rows.append({
            "onset": ev["rest_onset"],
            "duration": ev["rest_duration"],
            "trial_type": "fixation",
            "block_number": trial["trial_index"] + 1,
            "stim_file": "n/a",
            "onset_source": "log",
        })
        rows.append({
            "onset": ev["block_onset"],
            "duration": ev["block_duration"],
            "trial_type": trial["trial_type"],
            "block_number": trial["trial_index"] + 1,
            "stim_file": Path(trial["Path"].replace("\\", "/")).name,
            "onset_source": "log",
        })
    rows.append({
        "onset": final_rest["onset"],
        "duration": final_rest["duration"],
        "trial_type": "fixation",
        "block_number": len(trialorder) + 1,
        "stim_file": "n/a",
        "onset_source": "log",
    })
    rows.sort(key=lambda r: r["onset"])
    return rows


def validate_events(rows, participant):
    flags = []
    for i in range(1, len(rows)):
        prev, cur = rows[i - 1], rows[i]
        prev_end = prev["onset"] + prev["duration"]
        gap = cur["onset"] - prev_end
        if gap < -0.01:
            flags.append(f"overlap between block {prev['block_number']} and {cur['block_number']} ({gap:.3f}s)")
        elif gap > 0.5:
            flags.append(f"gap > 0.5s between block {prev['block_number']} and {cur['block_number']} ({gap:.3f}s)")

    last_end = rows[-1]["onset"] + rows[-1]["duration"]
    if last_end > EXPECTED_RUN_DURATION:
        flags.append(f"last event ends at {last_end:.3f}s, after expected run duration {EXPECTED_RUN_DURATION:.1f}s")
    if last_end < EXPECTED_RUN_DURATION - 10:
        flags.append(f"last event ends at {last_end:.3f}s, more than 10s before expected run duration {EXPECTED_RUN_DURATION:.1f}s")

    onsets = [r["onset"] for r in rows]
    if onsets != sorted(onsets):
        flags.append("onsets not monotonic")

    from collections import Counter
    counts = Counter(r["trial_type"] for r in rows if r["trial_type"] != "fixation")
    for tt in ("self_connected", "self_disconnected", "other"):
        if counts.get(tt, 0) != 6:
            flags.append(f"expected 6 '{tt}' blocks, found {counts.get(tt, 0)}")
    n_fixation = sum(1 for r in rows if r["trial_type"] == "fixation")
    if n_fixation != 19:
        flags.append(f"expected 19 fixation periods (18 + final), found {n_fixation}")

    return flags, last_end


def write_tsv(rows, path):
    path.parent.mkdir(parents=True, exist_ok=True)
    cols = ["onset", "duration", "trial_type", "block_number", "stim_file", "onset_source"]
    with open(path, "w", newline="") as f:
        w = csv.writer(f, delimiter="\t")
        w.writerow(cols)
        for r in rows:
            w.writerow([r[c] if r[c] != "" else "n/a" for c in cols])


def write_events_json(path):
    schema = {
        "onset": {"Description": "Onset of the event, in seconds from the first scanner trigger (volume 1 acquisition)."},
        "duration": {"Description": "Duration of the event in seconds."},
        "trial_type": {
            "Description": "SOS task condition.",
            "Levels": {
                "self_connected": "Participant and peer both watch the participant's own video (cue ON, green background).",
                "self_disconnected": "Each watches their own video separately (cue OFF, black background).",
                "other": "Both watch the peer's (confederate's) video (cue ON, green background).",
                "fixation": "Fixation-cross rest period preceding each block (and a final rest period after the last block).",
            },
        },
        "block_number": {"Description": "1-indexed block number within the run (1-18 for task blocks; fixation periods share the block_number of the block they precede, and the final fixation is block_number 19)."},
        "stim_file": {"Description": "Video stimulus filename for this block (relative to the task stimulus folder); n/a for fixation."},
        "onset_source": {"Description": "Whether onset/duration came from the PsychoPy .log (frame-accurate, preferred) or the .csv (fallback when .log is unavailable/incomplete)."},
        "TaskName": "sos",
        "TimingReference": "Seconds from the first scanner trigger keypress, which corresponds to the first acquired volume.",
    }
    path.write_text(json.dumps(schema, indent=2))


def count_data_rows(csv_path):
    with open(csv_path, newline="", encoding="utf-8", errors="replace") as f:
        return sum(1 for _ in f) - 1  # minus header


def select_csv_files(psychopy_dir, n_trials):
    """One file per real participant: skip test subjects/excluded IDs, and
    for participants with multiple sessions (crash + restart), keep only the
    complete one (>= n_trials data rows), flagging the skipped attempt."""
    by_participant = {}
    for csv_path in sorted(psychopy_dir.glob("*.csv")):
        participant = csv_path.stem.split("_")[0]
        by_participant.setdefault(participant, []).append(csv_path)

    selected = {}
    skipped_notes = {}
    for participant, paths in by_participant.items():
        if is_test_subject(participant) or participant in EXCLUDED_IDS:
            continue
        if len(paths) == 1:
            selected[participant] = paths[0]
            continue
        # multiple sessions: keep the complete one, flag the rest
        complete = [p for p in paths if count_data_rows(p) >= n_trials + 1]
        incomplete = [p for p in paths if p not in complete]
        if len(complete) != 1:
            raise ValueError(
                f"{participant}: expected exactly 1 complete session among {len(paths)}, "
                f"found {len(complete)} -- resolve manually before re-running."
            )
        selected[participant] = complete[0]
        skipped_notes[participant] = (
            f"{len(incomplete)} incomplete session(s) skipped "
            f"({', '.join(p.name + f' [{count_data_rows(p)} rows]' for p in incomplete)}); "
            f"used {complete[0].name}"
        )
    return selected, skipped_notes


def main():
    trialorder = load_trialorder(TRIALORDER_CSV)
    n_trials = len(trialorder)

    qc_rows = []
    all_lags = []

    selected_files, skipped_notes = select_csv_files(PSYCHOPY_DIR, n_trials)
    for participant, csv_path in sorted(selected_files.items()):
        log_path = csv_path.with_suffix(".log")

        trigger_time, log_lines = parse_log(log_path)
        precise_events, final_rest = extract_precise_events(log_lines, trigger_time, n_trials)
        rows = build_events_rows(trialorder, precise_events, final_rest)
        flags, last_end = validate_events(rows, participant)

        out_path = (
            OUT_DIR / f"sub-{participant}" / "ses-wavesos" / "func"
            / f"sub-{participant}_ses-wavesos_task-sos_events.tsv"
        )
        write_tsv(rows, out_path)

        # movie-load lag vs CSV's own (pre-load) block_onset
        csv_blocks = {b["trial_index"]: b for b in parse_csv_for_comparison(csv_path)}
        lags = []
        for ev in precise_events:
            csv_b = csv_blocks.get(ev["trial_index"])
            if csv_b is not None:
                lag = ev["block_onset"] - csv_b["block_onset"]
                lags.append(lag)
                all_lags.append(lag)

        per_condition_counts = {}
        for r in rows:
            if r["trial_type"] != "fixation":
                per_condition_counts[r["trial_type"]] = per_condition_counts.get(r["trial_type"], 0) + 1

        all_flags = list(flags)
        if participant in skipped_notes:
            all_flags.append(skipped_notes[participant])

        qc_rows.append({
            "participant": participant,
            "n_events": len(rows),
            "n_self_connected": per_condition_counts.get("self_connected", 0),
            "n_self_disconnected": per_condition_counts.get("self_disconnected", 0),
            "n_other": per_condition_counts.get("other", 0),
            "total_duration": round(last_end, 3),
            "mean_movie_load_lag": round(statistics.mean(lags), 4) if lags else "n/a",
            "max_movie_load_lag": round(max(lags), 4) if lags else "n/a",
            "onset_source": "log",
            "flags": "; ".join(all_flags),
        })

        status = "OK" if not all_flags else "FLAGGED"
        print(f"{participant}: {status} (n_events={len(rows)}, total_duration={last_end:.2f}s)"
              + (f" -- {'; '.join(all_flags)}" if all_flags else ""))

    write_events_json(OUT_DIR / "task-sos_events.json")

    qc_path = OUT_DIR / "events_qc.csv"
    with open(qc_path, "w", newline="") as f:
        cols = list(qc_rows[0].keys())
        w = csv.DictWriter(f, fieldnames=cols)
        w.writeheader()
        w.writerows(qc_rows)

    print(f"\nWrote events files for {len(selected_files)} participants to {OUT_DIR}")
    print(f"Wrote {qc_path}")
    if all_lags:
        print(f"\nMovie-load lag across all blocks (log block_onset - csv block_onset): "
              f"mean={statistics.mean(all_lags):.4f}s, SD={statistics.pstdev(all_lags):.4f}s, "
              f"max={max(all_lags):.4f}s, n={len(all_lags)}")


if __name__ == "__main__":
    main()
