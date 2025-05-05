# Copilot Instructions for Rice Sales Calculator App (Updated)

## 1. Project Overview

The primary goal of this project is to develop a Flutter application **with a Vietnamese user interface** that simplifies and speeds up the process of calculating payments for rice sales based on harvests. The app should allow users to manage harvest seasons ("Vụ"), record batches ("Mã") of rice bags within each season, calculate totals, apply deductions, and store the data locally. The app needs full CRUD (Create, Read, Update, Delete) capabilities for its data entities.

## 2. Technology Stack

* **Language:** Dart
* **Framework:** Flutter
* **State Management:** (Specify if you have a preference, e.g., Provider, Riverpod, Bloc, GetX. If unsure, Copilot can suggest options based on context, but specifying helps.) *Example: Use Provider for state management.*
* **Data Storage:** Local storage (e.g., `shared_preferences` for simple data or `sqflite` / `hive` for more structured data). Recommended: `sqflite` or `hive` due to relationships.

## 3. Key Concepts & Terminology

* **Vụ (Harvest Season):** Represents a single harvest period. Contains overall information like price per unit weight (e.g., price per kg), standard deductions (e.g., bag weight), and a collection of "Mã". Requires full CRUD operations.
* **Mã (Batch):**
  * A logical grouping of rice bags within a "Vụ".
  * **Does not require a specific name.** Its identity is primarily visual within the "Vụ" context (e.g., displayed in a grid).
  * **Contains a maximum of 5 units (bags).** Input should be restricted to 5 units per "Mã".
  * The display for each "Mã" should show its relevant calculated information (e.g., total weight of its units).
  * Requires full CRUD operations (create batch, add/edit/delete units within the 5-unit limit, delete batch).
* **Unit (Bag):** Represents a single bag of rice with a specific weight. Belongs to a "Mã".

## 4. Core Functionality Requirements

* **Harvest Management (Vụ):**
  * Implement full **CRUD** operations: Create, Read (List all, view details), Update, and Delete harvest seasons ("Vụ").
  * Store details per "Vụ": unit price, deduction rules.
* **Batch Management (Mã):**
  * Within a "Vụ", implement full **CRUD** operations for batches ("Mã"):
    * **Create:** Add a new, empty "Mã" (ready to receive up to 5 units).
    * **Read:** Display all "Mã" belonging to a "Vụ" (e.g., in the grid view).
    * **Update:** Add/edit/delete individual units (bags) within a "Mã", ensuring the **maximum of 5 units** is enforced.
    * **Delete:** Remove a "Mã" and its associated units.
* **Unit Input & Calculation:**
  * Provide an interface to input/edit the weight for individual units (bags) within a selected "Mã".
  * **Enforce the 5-unit maximum per "Mã".**
  * Automatically calculate and display the total weight for each "Mã" based on its contained units (1 to 5 units).
* **Overall Calculation:**
  * Calculate the total weight for the entire "Vụ" by summing the totals of all its "Mã".
  * Apply deductions based on the rules defined in the "Vụ".
  * Calculate the final payment amount for the "Vụ".
* **Data Persistence:** All "Vụ", "Mã", and unit data must be saved locally and persist across app sessions. Ensure data integrity during CRUD operations.

## 5. UI/UX Guidelines

* **Target Language:** The User Interface text (labels, buttons, messages) **must be in Vietnamese.**
* **Layout:**
  * **Units within a Mã:** Display units (individual bag weights, up to 5) in a vertical column layout when viewing/editing a specific "Mã".
  * **Mã within a Vụ:** Display multiple "Mã" cards or sections using a `GridView`. Each card should clearly display the total weight for that "Mã" and potentially its individual unit weights.
* **User Experience:**
  * Prioritize fast data entry for unit weights, respecting the 5-unit limit per "Mã".
  * Clear visual distinction between "Vụ" and "Mã".
  * Real-time updates of calculations as data is entered/modified.
  * Optimized for mobile usability, intuitive navigation, and clean interfaces.
  * Provide clear user feedback for CRUD operations (e.g., success messages, confirmation dialogs for deletion) **in Vietnamese**.
* **Navigation:** Logical flow: List of "Vụ" -> View "Vụ" details (with "Mã" grid) -> View/Edit "Mã" details (with unit column).

## 6. Data Storage

* Use a local storage solution like `sqflite` or `hive` to handle the relationships (Vụ -> Mã -> Units) and CRUD operations effectively.
* Implement robust data loading, saving, updating, and deletion logic.

## 7. Code Style and Conventions

* Adhere to standard Dart and Flutter linting rules (`flutter analyze`).
* Use clear, descriptive names (variables, functions, classes). Consider using English for code elements even if the UI is Vietnamese, for consistency with Flutter/Dart conventions (e.g., `HarvestSeason`, `RiceBatch`, `calculateTotalWeight`).
* Follow the chosen state management pattern consistently.
* Create reusable widgets.

## 8. Patterns to Prefer/Avoid

* **Prefer:** Separation of concerns (UI, logic, data). Using models/classes for `Vụ`, `Mã`, `Unit`. Clear data flow for CRUD.
* **Avoid:** Complex logic in build methods. Direct manipulation of UI from asynchronous data operations without proper state management. Inconsistent handling of the 5-unit limit.
