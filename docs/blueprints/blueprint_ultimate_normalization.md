# Implementation Blueprint: Ultimate Dynamic Normalization Engine

## Context
- **Requirement**: Support subjects where the sum of `ratio` is not 100 (e.g., 200% total) and individual `maxScore` is not 100.
- **Goal**: Allow as-is syllabus data entry while ensuring the Final Score is normalized to 100.

## 1. Logic Specifications
Implement the calculation in `lib/domain/logic/grade_calculator.dart`:

1.  **Sum of Ratios**: Calculate `TotalRatioSum` by summing all `ratio` values in `evaluations`.
2.  **Normalization**: Calculate the weight of each item as `ratio / TotalRatioSum`.
3.  **Final Score Formula**: 
    `finalScore = Σ ( (userScore / maxScore) * (ratio / TotalRatioSum) * 100 )`

## 2. UI Behavior
In `lib/presentation/subjects/subject_detail_screen.dart`:

- **Labels**: Show the calculated percentage to the user.
  - Formula: `(ratio / TotalRatioSum) * 100`
  - Example: For a 30% item in a 200% total subject, display "物理試験 (15.0%)".
- **Validation**: Ensure `userScore` cannot exceed `maxScore`.
- **Sliders**: Set `Slider.max` to the item's `maxScore`.

## 3. Data Integrity
Update `README.md` to state:
"Kosenar supports dynamic totals. You can set ratios to sum up to 150, 200, or any value. The system automatically normalizes them to a 100-point scale for GPA calculation."