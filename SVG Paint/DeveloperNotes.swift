//
//  DeveloperNotes.swift
//  SVG Paint
//
//  Human‑readable developer notes for SVG Paint project.
//  Keep this file in source control.
//  When you (or Claude) say: "add to developer notes", append the note under the
//  "Developer Notes Log" section below.
//
//  This file is intentionally mostly comments so it does not affect the build.
//

/*

SVG Paint — Developer Notes

Purpose

- Single place to capture decisions, TODOs, and workflow policies.
- Append new entries in the "Developer Notes Log" section with timestamp.
- Serves as PERSISTENT MEMORY across Claude chat sessions.

How to use this file

- When you want to record a decision, add entry under "Developer Notes Log":
  [YYYY MMM DD HHMM] (author) Short description of the decision, idea, or TODO.
- Keep entries concise. Use sub‑bullets if longer.
- Example: "[2025 OCT 29 1400] (MLF) Added zoom controls to preview image with magnifying glass icons."

Rules & Guidance for Claude (Persistent Memory)

- When user says "check the developer notes" or "add to developer notes", they mean THIS file.
- Use the `view` tool to read this file from /mnt/project/ when instructed.
- Do NOT write logs to any runtime-accessible file. Only append comments inside this file.
- Do NOT wire this file into the app at runtime (do not import/read/parse it from app code).
- Append new entries under "Developer Notes Log" using format:
  [YYYY MMM DD HHMM] (AUTHOR) Message.
  Assistant uses (MLF) when writing on behalf of user; user may sign as (MLF).
  Use (Claude) for Claude entries.
- Newest entries go at TOP of Developer Notes Log for quick scanning.
- For multi-line notes, use simple "-" bullets. Avoid images and tables.
- If a note implies code changes, treat that as separate, explicit task; do not change code unless requested.

CRITICAL CLAUDE iPAD WORKFLOW RULES:

NEW CHAT THREAD AUTO-START BEHAVIOR:
When user starts a new chat thread (usually because previous thread hit length limit):

1. IMMEDIATELY use user_time_v0 tool to get current date and time
2. Use recent_chats to load the most recent chat thread (the one that just maxed out)
3. Use recent_chats with date filters to load ALL chats from today's date
4. Review context from those threads before responding to user
5. Acknowledge you've reviewed the context: "I've reviewed today's cha
