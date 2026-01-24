#!/usr/bin/env npx tsx

import * as fs from "fs";
import * as path from "path";
import * as readline from "readline";

const TRIVIA_FILE = path.join(process.env.HOME!, "devmaxxing", "trivia", "questions.json");

interface Question {
  id: string;
  question: string;
  answer: string;
  system: string;
  source_pr: string;
  source_file: string;
  added_date: string;
  times_asked: number;
  times_correct: number;
}

interface CodeReview {
  id: string;
  code_snippet: string;
  answer: string;
  category: "database" | "performance" | "security" | "style" | "logic";
  reviewer: string;
  source_pr: string;
  source_file: string;
  added_date: string;
  times_asked: number;
  times_correct: number;
}

interface Stats {
  current_streak: number;
  best_streak: number;
  last_played: string | null;
}

interface TriviaData {
  questions: Question[];
  code_reviews?: CodeReview[];
  stats?: Stats;
}

const COLORS = {
  reset: "\x1b[0m",
  bold: "\x1b[1m",
  dim: "\x1b[2m",
  green: "\x1b[32m",
  yellow: "\x1b[33m",
  blue: "\x1b[34m",
  magenta: "\x1b[35m",
  cyan: "\x1b[36m",
  red: "\x1b[31m",
  bgBlue: "\x1b[44m",
  bgMagenta: "\x1b[45m",
};

function loadData(): TriviaData {
  if (!fs.existsSync(TRIVIA_FILE)) {
    console.log("No trivia file found. Run /end-day first to generate questions.");
    process.exit(1);
  }
  return JSON.parse(fs.readFileSync(TRIVIA_FILE, "utf-8"));
}

function saveData(data: TriviaData): void {
  fs.writeFileSync(TRIVIA_FILE, JSON.stringify(data, null, 2));
}

function pickWeighted<T extends { times_asked: number; times_correct: number }>(items: T[]): T {
  const weights = items.map((item) => {
    const freshness = 1 / (item.times_asked + 1);
    const difficulty = item.times_asked > 0 ? 1 - item.times_correct / item.times_asked : 0.5;
    return freshness * 2 + difficulty;
  });

  const totalWeight = weights.reduce((a, b) => a + b, 0);
  let random = Math.random() * totalWeight;

  for (let i = 0; i < items.length; i++) {
    random -= weights[i];
    if (random <= 0) return items[i];
  }
  return items[items.length - 1];
}

function clearScreen(): void {
  process.stdout.write("\x1b[2J\x1b[H");
}

function printStats(data: TriviaData): void {
  const questions = data.questions;
  const codeReviews = data.code_reviews || [];
  const stats = data.stats || { current_streak: 0, best_streak: 0 };

  const totalQ = questions.length;
  const answeredQ = questions.filter((q) => q.times_asked > 0).length;
  const correctQ = questions.reduce((sum, q) => sum + q.times_correct, 0);
  const askedQ = questions.reduce((sum, q) => sum + q.times_asked, 0);

  const totalCR = codeReviews.length;
  const answeredCR = codeReviews.filter((q) => q.times_asked > 0).length;
  const correctCR = codeReviews.reduce((sum, q) => sum + q.times_correct, 0);
  const askedCR = codeReviews.reduce((sum, q) => sum + q.times_asked, 0);

  console.log(`\n${COLORS.bold}📊 Trivia Stats${COLORS.reset}\n`);
  console.log(`${COLORS.cyan}Business Logic Questions:${COLORS.reset}`);
  console.log(`  Total: ${totalQ} | Attempted: ${answeredQ} | Accuracy: ${askedQ > 0 ? Math.round((correctQ / askedQ) * 100) : 0}%`);

  if (totalCR > 0) {
    console.log(`\n${COLORS.magenta}Code Review Questions:${COLORS.reset}`);
    console.log(`  Total: ${totalCR} | Attempted: ${answeredCR} | Accuracy: ${askedCR > 0 ? Math.round((correctCR / askedCR) * 100) : 0}%`);
  }

  console.log(`\n${COLORS.yellow}🔥 Streak: ${stats.current_streak} | Best: ${stats.best_streak}${COLORS.reset}\n`);

  const systems = [...new Set(questions.map((q) => q.system))];
  if (systems.length > 0) {
    console.log(`${COLORS.dim}Systems: ${systems.join(", ")}${COLORS.reset}\n`);
  }
}

async function askQuestion(
  rl: readline.Interface,
  prompt: string
): Promise<string> {
  return new Promise((resolve) => {
    rl.question(prompt, (answer) => resolve(answer.trim().toLowerCase()));
  });
}

async function runQuiz(mode: "all" | "questions" | "code_reviews" | "stats", system?: string): Promise<void> {
  const data = loadData();

  if (mode === "stats") {
    printStats(data);
    return;
  }

  let pool: (Question | CodeReview)[] = [];

  if (mode === "all" || mode === "questions") {
    let questions = data.questions;
    if (system) {
      questions = questions.filter((q) => q.system.toLowerCase().includes(system.toLowerCase()));
    }
    pool.push(...questions);
  }

  if (mode === "all" || mode === "code_reviews") {
    const codeReviews = data.code_reviews || [];
    if (system) {
      pool.push(...codeReviews.filter((q) => q.category.toLowerCase().includes(system.toLowerCase())));
    } else {
      pool.push(...codeReviews);
    }
  }

  if (pool.length === 0) {
    console.log("No questions found. Run /end-day to generate some!");
    return;
  }

  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
  });

  let running = true;
  let stats = data.stats || { current_streak: 0, best_streak: 0, last_played: null };

  while (running) {
    clearScreen();
    const item = pickWeighted(pool);
    const isCodeReview = "code_snippet" in item;

    if (isCodeReview) {
      const cr = item as CodeReview;
      console.log(`${COLORS.bgMagenta}${COLORS.bold} CODE REVIEW ${COLORS.reset} ${COLORS.dim}${cr.category}${COLORS.reset}\n`);
      console.log(`${COLORS.dim}From: ${cr.reviewer} on ${cr.source_pr}${COLORS.reset}`);
      console.log(`${COLORS.dim}File: ${cr.source_file}${COLORS.reset}\n`);
      console.log(`${COLORS.yellow}What's wrong with this code?${COLORS.reset}\n`);
      console.log(`${COLORS.cyan}┌─────────────────────────────────────────────────┐${COLORS.reset}`);
      cr.code_snippet.split("\n").forEach((line) => {
        console.log(`${COLORS.cyan}│${COLORS.reset} ${line}`);
      });
      console.log(`${COLORS.cyan}└─────────────────────────────────────────────────┘${COLORS.reset}\n`);
    } else {
      const q = item as Question;
      console.log(`${COLORS.bgBlue}${COLORS.bold} TRIVIA ${COLORS.reset} ${COLORS.dim}${q.system}${COLORS.reset}\n`);
      console.log(`${COLORS.dim}Source: ${q.source_pr} → ${q.source_file}${COLORS.reset}\n`);
      console.log(`${COLORS.yellow}${q.question}${COLORS.reset}\n`);
    }

    await askQuestion(rl, `${COLORS.dim}[Press Enter to reveal]${COLORS.reset}`);

    console.log(`\n${COLORS.green}${COLORS.bold}Answer:${COLORS.reset}`);
    console.log(`${isCodeReview ? (item as CodeReview).answer : (item as Question).answer}\n`);

    const result = await askQuestion(rl, `Did you get it? ${COLORS.green}(y)${COLORS.reset}/${COLORS.red}(n)${COLORS.reset}/${COLORS.dim}(q)uit${COLORS.reset}: `);

    if (result === "q" || result === "quit") {
      running = false;
    } else {
      const correct = result === "y" || result === "yes";
      item.times_asked++;
      if (correct) {
        item.times_correct++;
        stats.current_streak++;
        if (stats.current_streak > stats.best_streak) {
          stats.best_streak = stats.current_streak;
        }
        console.log(`\n${COLORS.green}✓ Nice!${COLORS.reset} Streak: ${stats.current_streak}`);
      } else {
        stats.current_streak = 0;
        console.log(`\n${COLORS.yellow}○ You'll get it next time${COLORS.reset}`);
      }

      stats.last_played = new Date().toISOString().split("T")[0];
      data.stats = stats;
      saveData(data);

      await askQuestion(rl, `${COLORS.dim}[Enter for next, q to quit]${COLORS.reset} `);
    }
  }

  rl.close();
  console.log(`\n${COLORS.bold}Session complete!${COLORS.reset} Streak: ${stats.current_streak} | Best: ${stats.best_streak}\n`);
}

const args = process.argv.slice(2);
const command = args[0]?.toLowerCase();

if (command === "stats" || command === "s") {
  runQuiz("stats");
} else if (command === "code" || command === "c" || command === "cr") {
  runQuiz("code_reviews");
} else if (command === "biz" || command === "b" || command === "q") {
  runQuiz("questions", args[1]);
} else if (command && command !== "help") {
  runQuiz("all", command);
} else if (!command) {
  runQuiz("all");
} else {
  console.log(`
${COLORS.bold}Trivia Quiz${COLORS.reset}

Usage:
  quiz              Random question (all types)
  quiz stats        Show your stats
  quiz code         Code review questions only
  quiz biz          Business logic questions only
  quiz <system>     Filter by system (e.g., quiz payments)

During quiz:
  Enter     Reveal answer
  y         Got it right
  n         Got it wrong
  q         Quit
`);
}
