# Implementation Blueprint: Dynamic Max Score Normalization

## Context
- **Problem**: Some subjects have a total score of 200 or 150 instead of 100.
- **Goal**: Allow data contributors to input syllabus values as-is (e.g., 200 total), let users input scores based on those values, but normalize the final result to a 100-point scale for the "Final Predicted Score".

## 1. JSON Data Structure Update
Add `maxScore` to each evaluation item. The sum of these `maxScore` values becomes the `totalMaxScore` for that subject.

[Example: Basic Science Lab (Total 200)]
{
  "name": "ベーシックサイエンス・ラボ",
  "evaluations": [
    { "id": "exam", "name": "物理：試験", "maxScore": 30 },
    { "id": "phys_rep", "name": "物理：レポ", "maxScore": 70 },
    { "id": "chem_rep", "name": "化学：レポ", "maxScore": 100 }
  ]
}

## 2. Calculation Logic (The "Kosenar" Engine)

The system must perform a two-step calculation:

### Step A: Calculate Total Max Score
`totalMaxScore = Σ(all evaluation.maxScore)`
*(e.g., 30 + 70 + 100 = 200)*

### Step B: Normalize to 100-point Scale
For each item, calculate its contribution to the final 100 points:
`contribution = (UserScore / Item.maxScore) * (Item.maxScore / totalMaxScore) * 100`

Simplified formula for the code:
`FinalScore = (Σ UserScores / totalMaxScore) * 100`

## 3. UI Display Rules
- **Input Fields**: Show " / [maxScore]" so users know the limit (e.g., " / 30").
- **Sliders**: The slider's range should be `0` to `maxScore`.
- **Ratios in UI**: 
  - Show the "Real Weight" in percentage: `(maxScore / totalMaxScore) * 100`.
  - For the lab example, it displays: "物理試験 (15%)", "物理レポ (35%)", "化学レポ (50%)".

## 4. Implementation Steps for Copilot

### Step 1: Model Update
Update `Subject` and `Evaluation` models to include `maxScore`. Default to `100` if not specified.

### Step 2: Logic Update
In `grade_calculator.dart`, implement the dynamic `totalMaxScore` summing logic before calculating the final prediction.

### Step 3: UI Update
In `subject_detail_screen.dart`:
- Update `TextFormField` validation to use `maxScore`.
- Update `Slider`'s `max` property to `maxScore`.
- Display the calculated percentage next to the item name.