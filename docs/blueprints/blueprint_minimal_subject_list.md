# Implementation Blueprint: Modern Minimalist Subject List UI

## Context
- **Current State**: Subject cards are cluttered with credits, teachers, and multiple small chips.
- **Goal**: Refactor the subject list to be clean and minimalist, focusing only on the "Subject Name" and the "Final Predicted Score".

## Design Specifications
1. **Remove Elements**:
   - Delete Credit number (e.g., "2", "1") from the leading icon.
   - Delete Teacher name.
   - Delete all status chips (評価平均, 段階評価, etc.).
2. **New Card Layout**:
   - **Leading**: A vertical color-coded status bar (e.g., 80+ is Green, 60+ is Yellow, <60 is Red).
   - **Title**: Large, bold subject name.
   - **Trailing**: The final predicted score with a large font size and a "/ 100" label.
3. **Card Styling**:
   - Rounded corners (16px+).
   - Subtle outer glow or flat design with deep background colors.
   - Increased vertical padding between cards for better scannability.

## Target Files
- `lib/presentation/subjects/subject_list_screen.dart` (Main list implementation)
- `lib/presentation/subjects/widgets/subject_card.dart` (Individual card widget)

## Step-by-Step Instructions

### Step 1: Simplify Subject Card Widget
Rewrite the `SubjectCard` to follow a minimalist structure.

(Conceptual Structure)
- **Container** (Margin, Padding, Decoration)
  - **Row**
    - **Vertical Divider/Bar** (Color based on score)
    - **Expanded** (Column: Subject Name)
    - **Score Block** (Column: "82.0", subtitle: "/ 100")

### Step 2: Implementation Details
1. In `SubjectCard`, remove the `Text` widgets bound to `course.teacher` and `course.credits`.
2. Remove the `Wrap` or `Row` containing the various `Chip` widgets.
3. Increase the font size of `course.name` to `18sp` or `20sp` with `FontWeight.bold`.
4. Style the trailing score:
   - Make the score number (e.g., 82.0) prominent.
   - Use a smaller, dim color for the "/ 100" text.
5. Apply a conditional color logic to the card's accent:
   - score >= 90: Emerald/Gold
   - score >= 80: Blue/Green
   - score >= 60: Amber/Orange
   - score < 60: Rose/Red

## Verification
- [ ] Open the "履修科目" screen.
- [ ] Confirm only the Subject Name and Score are visible.
- [ ] Ensure the UI feels spacious and "Modern" with high contrast on important numbers.
- [ ] Verify that tapping the card still navigates to the detailed view.