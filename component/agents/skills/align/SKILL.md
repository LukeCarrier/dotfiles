---
name: align
description: Interview the user relentlessly until you share their understanding of a plan or design. Load before committing to a design, when a request is ambiguous, or when the user asks to stress-test their thinking.
---

Reach a shared understanding before acting. Map the work as a **design tree**: every decision branches into the decisions that hang off it.

Work the tree in **rounds**. A question is **in the light** when every decision it depends on is already settled — you can ask it now without guessing at answers you haven't heard. A question is **in shadow** while a decision it depends on is still open; it waits. Each answer is **casting light**: it settles a decision and lights up the questions that hung off it, ready for a later round.

Each round, ask everything **in the light** at once. Number each question and give your recommended answer:

```
❓ **Q1 — <title>**: <body; may span paragraphs and offer choices>

➡️ <your recommended answer>
```

Then wait for answers. Do not ask a question that depends on another still open in this round — it's in shadow until that one is answered, so it belongs to a later round.

After each round, recompute what's now in the light and ask the next round.

Facts are your job, never the user's. When a question needs a fact from the environment (files, tools, config), dispatch **Edmund** to find it rather than asking. Don't block on him: a running lookup is an open dependency, so only the questions in its shadow wait — ask the rest of the light now, and fold his answer in when it lands.

## Completion criterion

Done when nothing remains in shadow: every branch of the design tree visited, nothing silently assumed. State that you've reached a shared understanding and **wait for the user to confirm** before acting on it.
