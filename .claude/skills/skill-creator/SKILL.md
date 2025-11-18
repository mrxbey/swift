---
name: skill-creator
description: Meta-skill for creating new Claude Code Skills. Use when user asks to "create a skill", "add a new skill", "make a skill for X", or when you identify a need for a new reusable capability. Creates properly structured SKILL.md files with YAML frontmatter, descriptions, instructions, and examples following best practices.
allowed-tools: Write, Read, Glob, Grep, Bash
---

# Skill Creator

A meta-skill that helps create new Claude Code Skills following best practices.

## When to Use

Activate this skill when:
- User explicitly requests "create a skill for X"
- You identify a repetitive task that should be automated
- A new capability needs to be added to the project
- Team workflows need standardization

## Skill Creation Process

### 1. Gather Requirements

**Ask the user:**
- What should the skill do? (functionality)
- When should it activate? (trigger conditions)
- What tools does it need? (Read, Write, Bash, etc.)
- Is it project-specific or personal?
- Should it be read-only or have write access?

### 2. Determine Skill Name

**Naming conventions:**
- Use lowercase with hyphens: `swift-testing`, `database-migration`
- Be specific and descriptive
- Avoid generic names like `helper` or `utility`
- Match the primary function

### 3. Write Description (Critical)

**Description must include:**
- What it does (functionality)
- When to use it (activation triggers)
- Max 1024 characters
- Specific keywords users would mention

**Good example:**
```
Analyzes Swift code for TCA (The Composable Architecture) patterns.
Use when working with @Reducer, @ObservableState, TCA features, or
when debugging state management. Checks for proper dependency injection,
action handling, and reducer composition.
```

**Bad example:**
```
Helps with Swift development
```

### 4. Structure the SKILL.md

```markdown
---
name: skill-name
description: Specific description with trigger words (max 1024 chars)
allowed-tools: Read, Write, Grep, Glob, Bash
---

# Skill Title

Brief overview of what this skill does.

## When to Use

Clear list of scenarios where this skill should activate.

## Instructions

Step-by-step process:

1. First step with details
2. Second step with details
3. etc.

## Examples

### Example 1: Common Use Case

Input: "User request example"
Output: Expected behavior

### Example 2: Edge Case

Input: "Another scenario"
Output: How to handle it

## Best Practices

- Tip 1
- Tip 2
- Tip 3

## Common Pitfalls

- What to avoid
- Error handling
- Edge cases
```

### 5. Choose Allowed Tools

**Read-only skills (analysis, search, reporting):**
```yaml
allowed-tools: Read, Grep, Glob
```

**Write skills (code generation, file creation):**
```yaml
allowed-tools: Read, Write, Edit, Grep, Glob
```

**Automation skills (build, deploy, test):**
```yaml
allowed-tools: Read, Write, Bash, Grep, Glob
```

**No restrictions (full access):**
```yaml
# Omit allowed-tools field
```

### 6. Create Supporting Files (Optional)

**For complex skills, add:**

`reference.md` - Technical reference, API docs
`examples.md` - More detailed examples
`templates/` - Code templates
`scripts/` - Helper scripts

### 7. Test the Skill

**Validation checklist:**
- [ ] SKILL.md has valid YAML frontmatter
- [ ] Description includes trigger words
- [ ] Name uses lowercase-with-hyphens
- [ ] Instructions are clear and actionable
- [ ] Examples demonstrate common use cases
- [ ] Allowed-tools match the skill's needs
- [ ] File location is correct (.claude/skills/skill-name/)

### 8. Test Activation

**Try multiple prompts:**
- Direct: "Use X skill to do Y"
- Indirect: Mention trigger words naturally
- Context: Provide files/scenarios that should activate it

## Skill Templates

### Analysis Skill Template

```markdown
---
name: code-analyzer
description: Analyzes [LANGUAGE] code for [PATTERNS]. Use when working with [FILE_TYPES] or when debugging [SPECIFIC_ISSUES]. Keywords: [TRIGGER_WORDS]
allowed-tools: Read, Grep, Glob
---

# Code Analyzer

Analyzes code for specific patterns and issues.

## When to Use

- When user mentions [KEYWORD1]
- Working with [FILE_TYPE]
- Debugging [ISSUE]

## Instructions

1. Use Glob to find relevant files
2. Use Grep to search for patterns
3. Use Read to analyze file content
4. Report findings with file:line references

## Examples

### Example: Find Issues

Input: "Check for [ISSUE] in my code"

Process:
1. Glob for *.swift files
2. Grep for pattern
3. Analyze results
4. Report with actionable recommendations
```

### Code Generation Skill Template

```markdown
---
name: code-generator
description: Generates [COMPONENT_TYPE] following [PATTERN]. Use when creating new [ENTITIES] or when user asks to "generate", "create", "scaffold" [COMPONENT]. Keywords: [TRIGGER_WORDS]
allowed-tools: Read, Write, Grep, Glob
---

# Code Generator

Generates code following project patterns.

## When to Use

- User asks to "create new [COMPONENT]"
- Mentions "generate", "scaffold"
- Needs boilerplate for [USE_CASE]

## Instructions

1. Read existing examples for patterns
2. Gather requirements from user
3. Generate code following conventions
4. Write to appropriate location
5. Update related files (imports, etc.)

## Templates

### [Component] Template

```[language]
// Template code here
```

## Examples

### Example: Create New Component

Input: "Create a new [COMPONENT] called X"

Output:
- Generated file at correct location
- Follows project conventions
- Includes documentation
- Updates related files
```

### Automation Skill Template

```markdown
---
name: task-automator
description: Automates [TASK] workflow including [STEPS]. Use when user wants to [ACTION] or mentions [KEYWORDS]. Runs [COMMANDS] in sequence with error handling.
allowed-tools: Bash, Read, Write, Grep, Glob
---

# Task Automator

Automates repetitive task workflows.

## When to Use

- User says "[TRIGGER_PHRASE]"
- Need to [ACTION]
- Working on [WORKFLOW]

## Instructions

1. Verify prerequisites
2. Run command sequence
3. Check for errors
4. Report results

## Commands

```bash
# Step 1: [Description]
command1

# Step 2: [Description]
command2

# Step 3: [Description]
command3
```

## Error Handling

- If X fails: Do Y
- If Z error: Suggest A
```

## Best Practices for Skills

### DO:
✅ Write specific, detailed descriptions
✅ Include trigger keywords users would actually say
✅ Provide clear, step-by-step instructions
✅ Add concrete examples
✅ Restrict tools to minimum needed
✅ Test with various prompts
✅ Update when workflows change

### DON'T:
❌ Use vague descriptions like "helps with development"
❌ Make skills too broad (split into multiple focused skills)
❌ Forget YAML frontmatter
❌ Grant unnecessary tool permissions
❌ Skip examples
❌ Use uppercase or spaces in skill names
❌ Create skills for one-time tasks

## Troubleshooting

**Skill not activating?**
1. Check description has specific trigger words
2. Verify YAML syntax is correct
3. Ensure skill name is lowercase-with-hyphens
4. Try mentioning exact words from description

**YAML parsing errors?**
1. Check for tabs (use spaces only)
2. Verify `---` delimiters
3. Ensure proper indentation
4. Quote strings with special characters

**Wrong tool restrictions?**
1. Read-only: Read, Grep, Glob
2. File creation: Add Write, Edit
3. Command execution: Add Bash
4. Full access: Omit allowed-tools

## Example: Creating a Swift Testing Skill

**User request:** "Create a skill for running Swift tests"

**Process:**

1. **Gather requirements:**
   - Functionality: Run tests, parse output, report failures
   - Triggers: "run tests", "test", "check tests"
   - Tools needed: Bash (to run swift test), Read (to check files)
   - Project-specific: Yes (.claude/skills/)

2. **Create the skill:**

```markdown
---
name: swift-testing
description: Runs Swift tests using SPM and reports results. Use when user asks to "run tests", "test the code", "check if tests pass", or mentions "XCTest", "swift test". Parses test output and highlights failures.
allowed-tools: Bash, Read, Grep
---

# Swift Testing

Runs Swift Package Manager tests and provides detailed results.

## When to Use

- User mentions "run tests" or "test"
- Before committing code
- After making changes
- Debugging test failures

## Instructions

1. Run `swift test` command
2. Parse output for failures
3. If failures, use Grep to find relevant test files
4. Report results with file:line references
5. Suggest fixes for common issues

## Examples

### Example: Run All Tests

Input: "Run the tests"

Process:
```bash
cd HabitTracker
swift test --parallel
```

Output:
- Total tests run
- Passing/failing counts
- Failure details with file locations
- Suggested fixes

### Example: Run Specific Test

Input: "Test the TodayFeature"

Process:
```bash
swift test --filter TodayFeatureTests
```

## Common Test Failures

- Async timing issues → Increase timeout
- Mock data setup → Check mock configuration
- State assertions → Verify initial state
```

3. **Save to:** `.claude/skills/swift-testing/SKILL.md`

4. **Test activation:**
   - "Run the tests"
   - "Are the tests passing?"
   - "Test the TodayFeature"

## Meta-Usage

This skill can create more skills! If you need a new capability:

1. Tell me what you need
2. I'll use this skill-creator to build it
3. The new skill will be available immediately
4. Share with team via git

**Example:** "Create a skill for validating database migrations"
→ This skill creates a new migration-validator skill

## Skill Library Growth

As you create skills, your project becomes more powerful:
- Fewer repetitive explanations
- Consistent workflows
- Team knowledge captured
- Faster development
- Better quality

Each skill makes future work easier!
