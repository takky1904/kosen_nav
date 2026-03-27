# Implementation Blueprint: Dynamic Syllabus Integration & Calculation Logic

## Context
- **Problem**: Current UI shows "Participation (平常点)" as 100% even when JSON defines other ratios.
- **Goal**: Correctly parse `evaluations` from `nagano.json`, distribute ratios between "Periodic Tests" (fixed 4 inputs) and "Variable Components" (slider + text), and implement weighted-average calculation logic.

## Design Rules
1. **Periodic Tests (id: "exam")**: 
   - Extract `ratio` from the item where `id == "exam"`.
   - UI: Maintain the 4-field input.
   - Score: Average of non-null inputs.
2. **Variable Components (id != "exam")**: 
   - All other items in `evaluations` list.
   - UI: Dynamic list of cards with both a `TextField` and a `Slider`.
   - Score: Individual `userScore` for each item.

## Target Files
- **App (Logic & Model)**:
  - `lib/domain/models/course.dart` (Model to hold evaluations)
  - `lib/data/local/local_database.dart` (Schema to store JSON strings of evaluations)
- **App (UI)**:
  - `lib/presentation/subjects/subject_detail_screen.dart` (Dynamic UI generation)

## Step-by-Step Instructions

### Step 1: Data Fetching & Model Update
1. Update the `Course` model to properly map the `evaluations` array from the JSON.
2. In the local database, ensure that when a course is "added" or "synced", the `evaluations` data is stored as a JSON string in the SQLite table.

### Step 2: UI Logic - Grouping Evaluations
In `subject_detail_screen.dart`, implement logic to split `course.evaluations` into:
- `examComponent`: The one with `id: "exam"`.
- `otherComponents`: Everything else (Participation, Report, etc.).

### Step 3: Dynamic UI Rendering
1. **Periodic Test Block**: 
   - Display "定期試験" with the ratio from `examComponent.ratio`.
   - Ensure the 4 text fields are visible.
2. **Simulation Block**:
   - Loop through `otherComponents`.
   - For each, render a card containing the name, ratio, a text input, and a synchronized slider.
3. **Ratio Bar (Bottom)**:
   - Use `syncfusion_flutter_charts` or a custom `Row` of `Container`s to create a horizontal bar chart showing the ratio breakdown (e.g., Test 70% vs Normal 30%).

### Step 4: Weighted Calculation Logic
Update the `predictedScore` calculation:
- `testWeight = (avgOfTests) * (examComponent.ratio / 100)`
- `othersWeight = Σ (componentScore * (componentRatio / 100))`
- `finalScore = testWeight + othersWeight`
- Ensure the UI updates immediately when any slider or text field changes.

## Verification
- [ ] Select "基礎数学A": Confirm Periodic Test ratio is 70% and Normal is 30%.
- [ ] Select "プログラミング演習": Confirm 3 simulation items (Test 70%, Quiz 20%, Report 10%) appear.
- [ ] Drag a slider: Confirm the text field updates and the "Predicted Final Score" changes according to the weight.