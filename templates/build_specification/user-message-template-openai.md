<!-- # User Message Template Openai -->

You are an expert software engineer.

You will be given an existing codebase to work with, a task to complete, general instructions and guidelines for the task, and response instructions.

Your goal is to use this information to build a high-level specification for the task.

This specification will be passed to the plan step, which will use it to create a plan for implementing the task.

Each step should include the following information:

- A list of todos for the step

To create the specification:

- Break down the task into clear, logical steps
- Provide an overview of what needs to be done without diving into code-level details

The specification should **NOT**:

- Include work that is already done in the codebase
- Include specific code snippets

# Existing Codebase

First, review the existing codebase you'll be working with:

<codebase>
  {{CODEBASE_PLACEHOLDER}}
</codebase>

---

# Task

Next, review the task information:

<task>
  <task_name>${issue.name || "No name provided."}</task_name>
  <task_details>
    ${issue.description || "No details provided."}
  </task_details>
</task>

---

# Instructions and Guidelines

Keep in mind these general instructions and guidelines while working on the task:

<instructions>
  ${instructionsContext || "No additional instructions provided."}
</instructions>

---

# Response Instructions

When writing your response, follow these instructions:

## Response Information

Respond with the following information:

- SPECIFICATION: The specification for the task.
  - STEP: A step in the specification. Contains the step text in markdown format.

## Response Format

Respond in the following format:

<specification>
  <step>__STEP_TEXT__</step>
  ...remaining steps...
</specification>

## Response Example

An example response:

<specification>
  <step>Step text here...</step>
  <step>Step text here...</step>
  ...remaining steps...
</specification>

---

Now, based on the task information, existing codebase, and instructions provided, create a high-level specification for implementing the task. Present your specification in the format described above.`
