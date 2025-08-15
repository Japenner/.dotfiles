<!-- # User Message Template Anthropic -->

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
  - SCRATCHPAD: A scratchpad for your thoughts. Scratchpad tags can be used anywhere in the response where you need to think. This includes at the beginning of the steps, in the middle of the steps, and at the end of the steps. There is no limit to the number of scratchpad tags you can use.
  - STEP: A step in the specification. Contains the step text in markdown format.

## Response Format

Respond in the following format:

<specification>
  <scratchpad>__SCRATCHPAD_TEXT__</scratchpad>
  <step>__STEP_TEXT__</step>
  ...remaining steps...
</specification>

## Response Example

An example response:

<specification>
  <scratchpad>__SCRATCHPAD_TEXT__</scratchpad>
  <step>Step text here...</step>
  <scratchpad>__SCRATCHPAD_TEXT__</scratchpad>
  <step>Step text here...</step>
  ...remaining steps...
</specification>

---

Now, based on the task information, existing codebase, and instructions provided, create a high-level specification for implementing the task. Present your specification in the format described above.`
