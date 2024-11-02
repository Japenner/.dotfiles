---
name: "Design Bug Report"
about: "Report a design-related bug with guidance for expected outcomes and remediation."
title: "[BUG] Brief description of the bug"
labels: ["bug", "design", "frontend"]
assignees: ""

---

## Issue Summary

**Description of the bug:** Provide a brief summary of the bug, including what the current display or functionality is versus the expected outcome.

**Example:**

- Current display: "Download a copy of your VA Form (PDF)"
- Expected display: "Download a copy of your VA Form 21-10210 (PDF)"

**Design Reference (if applicable):** Add a link to the design specification, such as Figma or other design tools, to clarify the intended display or functionality.

**Screenshots or Visual Reference:** Include screenshots or images that showcase both the current issue and expected design for comparison.

---

## Expected Outcome

Describe the expected behavior or display per design specifications. Be specific about the text, color, placement, and other relevant design elements.

**Example:**

- Download link should display as "Download a copy of your VA Form [Form Number] (PDF)" where `[Form Number]` is dynamically populated based on the form submitted.

---

## Steps to Reproduce

List the steps to reproduce the issue for easier debugging.

1. Navigate to the page where the issue occurs.
2. Perform the action that triggers the bug (e.g., form submission).
3. Observe the discrepancy in the UI or behavior.

---

## Remediation Steps

Provide specific guidance on what should be done to resolve the issue. Include any technical considerations, such as where changes might need to be applied or special requirements for dynamic content.

**Example:**

- Update the confirmation page component to include the form number in the download link.
- Ensure the link is dynamically populated based on submission data.

---

## Definition of Done

List the criteria for completion of this ticket to verify the fix meets expectations.

- [ ] Bug is fixed and matches design specifications.
- [ ] Code changes are implemented, and a pull request is submitted.
- [ ] Changes are reviewed and merged after peer review.
- [ ] Update is verified on Staging (or an equivalent environment).
- [ ] Documentation is updated if necessary.

**Additional Notes:** Include any dependencies or follow-up actions, such as notifications to relevant stakeholders or other teams if their areas may be impacted by this fix.

---

**Additional Context**
Provide any additional information that might be helpful for resolving the issue, such as links to related tickets or documentation.

**Example:** This could be additional guidance on using a particular color scheme, link format, or other design guidance.
