**Prompt for Generating Structured, Detailed GitHub Issues Using An Issue Template**

*Objective:* Use the provided GitHub issue template to create a complete, structured, and actionable issue description for the task specified in $TASK_DETAILS. Ensure the generated issue captures all key details, is clearly organized, and is easy for team members to understand and implement. If nothing was defined or found for a specific section, omit that section all together.

**Template and Task Details**:

- *Task Information*:

```markdown
$TASK_DETAILS
```

- *Template Structure*:

```markdown
$ISSUE_TEMPLATE
```

**Instructions**:

1. **Prioritize Clarity and Actionability**:
   - In the **Description**, provide a concise overview, including any essential background, task importance, and impact.
   - List **Main Actions** that define the scope and requirements, using clear language and references to any relevant scripts, resources, or documentation links.
   - Establish **Acceptance Criteria** with measurable, specific items that define when the task is complete.

2. **Ensure Thoroughness and Completeness**:
   - Include **Technical Details** covering any critical code references, libraries, or configuration requirements.
   - Identify any **Dependencies** such as related tasks or external resources, ensuring all prerequisites are clearly noted.
   - Define a clear **Definition of Done** that includes any testing, validations, or review processes needed for issue closure.

3. **Strictly Follow Template Structure**:
   - Use each section of the template in order, providing detailed information for each part.
   - Avoid redundancy by referring to relevant sections or attachments as needed.
   - In **Attachments**, include only essential links, files, or resources that add meaningful context or requirements.

4. **Use Clear, Consistent Language**:
   - Maintain a professional, straightforward tone throughout the issue.
   - Use consistent terminology to ensure clear expectations for tasks, actions, and requirements.
   - Avoid ambiguous terms and ensure each section’s language clearly defines goals and actions for effective implementation.

---

**Example Output**:

Using $ISSUE_TEMPLATE, create an issue that includes:

1. **Description**: A task overview and context, with specific action steps outlined.
2. **Acceptance Criteria**: A checklist of measurable outcomes.
3. **Technical Details**: Detailed instructions, references, or configuration requirements.
4. **Attachments and Dependencies**: Relevant links, files, or cross-referenced tasks.
5. **Definition of Done and Requested Feedback**: Final criteria for task completion and any specific feedback requests.
