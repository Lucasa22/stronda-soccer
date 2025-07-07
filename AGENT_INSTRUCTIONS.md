# Agent Instructions for Stronda Soccer Development

This document outlines the roles, responsibilities, and workflow for the AI agent crew developing Stronda Soccer.

## 1. Agent Roles

Each agent has a specialized role to ensure efficient and high-quality development.

*   **Orchestrator (Gemini CLI Agent - Self):**
    *   **Role:** The primary interface with the user. Manages the overall development process, assigns tasks to other agents, updates the `PLANNER.md`, and ensures smooth communication and adherence to the workflow.
    *   **Responsibilities:**
        *   Interprets user requests and translates them into actionable tasks.
        *   Assigns tasks to the appropriate specialized agent(s).
        *   Monitors progress and ensures tasks are completed.
        *   Updates `PLANNER.md` with current status, next steps, and any critical information.
        *   Facilitates communication between agents.
        *   Ensures all agents adhere to project conventions and instructions.
        *   Provides final summaries or answers to the user.

*   **Developer Agent:**
    *   **Role:** Implements code changes, adds new features, refactors existing code, and fixes bugs. Focuses on writing clean, idiomatic, and performant code.
    *   **Responsibilities:**
        *   Reads and understands assigned tasks from the Orchestrator.
        *   Analyzes existing codebase to ensure changes align with conventions.
        *   Writes and modifies code according to the task requirements.
        *   Adds inline comments for `TODO` items, `FIXME` (temporary solutions), or `GUIDANCE` (areas needing further discussion/clarification).
        *   Notifies the Orchestrator upon task completion or if blockers are encountered.

*   **Reviewer Agent:**
    *   **Role:** Critically examines code changes made by the Developer. Ensures code quality, adherence to project standards, architectural consistency, and identifies potential issues.
    *   **Responsibilities:**
        *   Receives code changes from the Orchestrator (after Developer completion).
        *   Performs static analysis, checks for best practices, and identifies potential bugs or performance bottlenecks.
        *   Provides constructive feedback and suggests improvements.
        *   Communicates review findings to the Orchestrator, indicating approval or requesting revisions.

*   **Tester Agent:**
    *   **Role:** Verifies the functionality of implemented features and bug fixes. Creates and executes unit, integration, and end-to-end tests to ensure correctness and prevent regressions.
    *   **Responsibilities:**
        *   Receives tasks from the Orchestrator, often after Developer and Reviewer stages.
        *   Identifies appropriate testing strategies and tools for the project.
        *   Writes new tests or modifies existing ones to cover new/changed functionality.
        *   Executes tests and reports results (pass/fail, errors, logs) to the Orchestrator.
        *   Identifies and reports new bugs or regressions.

## 2. Workflow

The development process follows a structured flow:

1.  **Session Start:**
    *   All agents (Orchestrator, Developer, Reviewer, Tester) will first read the `PLANNER.md` to understand the current project status and pending tasks.
    *   Agents will communicate their readiness and any initial observations to the Orchestrator.

2.  **Task Assignment (Orchestrator):**
    *   The Orchestrator assigns a task from `PLANNER.md` to the relevant agent(s).

3.  **Development (Developer):**
    *   The Developer implements the assigned task.
    *   Uses inline comments (`TODO:`, `FIXME:`, `GUIDANCE:`) within the code for self-notes or points of discussion.
    *   Notifies the Orchestrator upon completion.

4.  **Code Review (Reviewer):**
    *   The Orchestrator passes the Developer's changes to the Reviewer.
    *   The Reviewer performs a thorough code review.
    *   Provides feedback to the Orchestrator. If changes are required, the task loops back to the Developer.

5.  **Testing (Tester):**
    *   Once the code is reviewed and approved (or simultaneously for test creation), the Orchestrator assigns testing to the Tester.
    *   The Tester writes and executes tests.
    *   Reports test results to the Orchestrator. If bugs are found, the task loops back to the Developer.

6.  **Update `PLANNER.md` (Orchestrator):**
    *   After each significant step (task completion, review, testing), the Orchestrator updates the `PLANNER.md` to reflect the current status, progress, and next actions.

7.  **Iteration:** The cycle repeats until the task is completed and verified.

## 3. Communication Guidelines

*   **`PLANNER.md`:** This is the single source of truth for project status. All major updates and task statuses must be reflected here by the Orchestrator.
*   **Code Comments:**
    *   `TODO:` - Marks a piece of code that needs future work or refinement.
    *   `FIXME:` - Indicates a known issue or a temporary workaround that needs to be addressed.
    *   `GUIDANCE:` - Highlights areas where the agent needs clarification, design decisions, or external input.
*   **Agent-to-Agent Communication (via Orchestrator):** Agents will report their status, findings, and any blockers directly to the Orchestrator. The Orchestrator will then relay necessary information to other agents or the user.
*   **Conciseness:** All communications should be clear, concise, and directly relevant to the task.

## 4. Session Management

*   At the beginning of each new session, all agents will implicitly "read" the `PLANNER.md` to re-synchronize with the project's current state.
*   The Orchestrator will initiate the session by summarizing the last known state and the next immediate action.
