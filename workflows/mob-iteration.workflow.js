export const meta = {
  name: 'mob-iteration',
  description: 'One mob pipeline iteration with deterministic station sequencing and artifact verification between stations',
  whenToUse: 'Pilot: run a coding task through design, critique, implement, review, validate, and tone scrub with the loop caps and artifact checks enforced in code instead of prose.',
  phases: [
    { title: 'Design', detail: 'Babbage design, Oppenheimer critique with block-back loop (cap 2 returns)' },
    { title: 'Implement', detail: 'Lovelace implementation on the prepared branch' },
    { title: 'Review', detail: 'Friedman single-pass review loop with Lovelace fixes (cap 3 iterations)' },
    { title: 'Validate', detail: 'Curie validation plan and known risks' },
    { title: 'Scrub', detail: 'Asimov tone pass, terminal' },
  ],
}

// Inputs: { featureSlug, taskDescription, workLocation, branchName, mode: "fresh" | "fixup" }
// The orchestrator prepares the worktree/WIP branch BEFORE invoking this workflow and
// handles squash/transport AFTER it returns (protocols/local/worktree-transport.md).
// Scope-proportional station skipping (protocols/scope-proportional-pipeline.md) is an
// orchestrator pre-decision; this script encodes the full default pipeline.
const { featureSlug, taskDescription, workLocation, branchName, mode } = args
if (!featureSlug || !taskDescription || !workLocation || !branchName || !mode) {
  throw new Error('args must provide featureSlug, taskDescription, workLocation, branchName, mode ("fresh"|"fixup")')
}

const featureDirRef = `the feature directory scratch/output/_${featureSlug}/ in the framework repo (resolve the absolute path per rules/scratch-path-resolution.md)`

// Loop caps (protocols/mob-pipeline.md; review loop cap 3, design block-back cap 2).
const MAX_DESIGN_RETURNS = 2
const MAX_REVIEW_ITERATIONS = 3

// ---------- schemas ----------

const NEXT_ARTIFACT_SCHEMA = {
  type: 'object',
  properties: { filename: { type: 'string' } },
  required: ['filename'],
  additionalProperties: false,
}

const VERIFY_SCHEMA = {
  type: 'object',
  properties: {
    exists: { type: 'boolean' },
    nonEmpty: { type: 'boolean' },
  },
  required: ['exists', 'nonEmpty'],
  additionalProperties: false,
}

// Terse findings only: what is broken and where. No reasoning chains, no suggested
// fixes. This is the one sanctioned relay in the hub-and-spoke model (mob-pipeline.md
// iteration loop: compression without interpretation).
const CRITIQUE_SCHEMA = {
  type: 'object',
  properties: {
    clean: { type: 'boolean', description: 'true when there are no blocking findings' },
    blockers: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          location: { type: 'string', description: 'file/section the finding anchors to' },
          problem: { type: 'string', description: 'one sentence: what is broken' },
        },
        required: ['location', 'problem'],
        additionalProperties: false,
      },
    },
  },
  required: ['clean', 'blockers'],
  additionalProperties: false,
}

const IMPLEMENT_SCHEMA = {
  type: 'object',
  properties: {
    workCommitted: { type: 'boolean', description: 'true when the implementation is committed on the working branch' },
    summary: { type: 'string', description: 'one or two sentences: what was implemented or fixed' },
    unaddressed: {
      type: 'array',
      items: { type: 'string' },
      description: 'blockers that could not be addressed or were interpreted ambiguously',
    },
  },
  required: ['workCommitted', 'summary', 'unaddressed'],
  additionalProperties: false,
}

const VALIDATE_SCHEMA = {
  type: 'object',
  properties: {
    outcome: { type: 'string', enum: ['ran-clean', 'ran-with-failures', 'plan-only'] },
    knownRisks: { type: 'array', items: { type: 'string' } },
    openQuestions: { type: 'array', items: { type: 'string' } },
  },
  required: ['outcome', 'knownRisks', 'openQuestions'],
  additionalProperties: false,
}

const SCRUB_SCHEMA = {
  type: 'object',
  properties: {
    unresolvedFindings: {
      type: 'array',
      items: { type: 'string' },
      description: 'tone findings that could not be resolved mechanically; empty when the scrub is clean',
    },
  },
  required: ['unresolvedFindings'],
  additionalProperties: false,
}

// ---------- helpers ----------

// Artifact numbering is delegated to the deterministic script rather than inferred
// (rules/feature-directory-lifecycle.md). Runs as a low-effort checker agent because
// workflow scripts have no filesystem access.
async function nextArtifact(agentName, phaseTitle) {
  const r = await agent(
    `Run scripts/next-artifact.sh in the framework repo against ${featureDirRef} for agent "${agentName}" and return exactly the filename it prints. Create the feature directory first if it does not exist. Single discrete commands only.`,
    { label: `next:${agentName}`, phase: phaseTitle, schema: NEXT_ARTIFACT_SCHEMA, effort: 'low' },
  )
  if (!r || !r.filename) throw new Error(`artifact numbering failed for ${agentName}`)
  return r.filename
}

// protocols/post-dispatch-artifact-verify.md Step 1, as code: never trust the
// station's completed signal; check the file landed.
async function verifyArtifact(filename, phaseTitle) {
  const r = await agent(
    `Check whether ${filename} inside ${featureDirRef} exists and is non-empty (a single ls / wc check, per protocols/post-dispatch-artifact-verify.md Step 1). Do not read or summarize its content.`,
    { label: `verify:${filename}`, phase: phaseTitle, schema: VERIFY_SCHEMA, effort: 'low' },
  )
  return Boolean(r && r.exists && r.nonEmpty)
}

function failure(station, reason, extra) {
  log(`HALT at ${station}: ${reason}`)
  return { status: 'failed', station, reason, ...(extra || {}) }
}

const baseVerification = mode === 'fixup'
  ? 'First thing: run `git branch --show-current` to confirm you are on the WIP branch, then `git log --oneline -3` to confirm the PR\'s commits are present. If either check fails, STOP and report the error.'
  : 'First thing: run `git log --oneline -3` to confirm you are on a branch based on main. If you see commits from a different feature branch, STOP and report the error.'

const terse = (blockers) => blockers.map((b) => `- ${b.location}: ${b.problem}`).join('\n')

// ---------- Design ----------

phase('Design')

const babbageFile = await nextArtifact('babbage', 'Design')
await agent(
  `<intent>Produce the technical design for this task.</intent>
<inputs>Feature slug: ${featureSlug}. Work location: ${workLocation}. Task: ${taskDescription}</inputs>
<scope>Design only; no implementation. Write your design to ${babbageFile} in ${featureDirRef}.</scope>`,
  { agentType: 'babbage', label: 'babbage:design', phase: 'Design' },
)
if (!(await verifyArtifact(babbageFile, 'Design'))) {
  return failure('design', `design artifact ${babbageFile} missing or empty after the architect station`)
}

let designReturns = 0
let critique
while (true) {
  const oppFile = await nextArtifact('oppenheimer', 'Design')
  critique = await agent(
    `<intent>Stress-test the current design for structural flaws before implementation.</intent>
<inputs>Feature slug: ${featureSlug}. Work location: ${workLocation}.</inputs>
<scope>Full independent critique of the latest design artifact in the feature directory. Write your report to ${oppFile} in ${featureDirRef}. In the structured output, report blocking findings only, as location plus one-sentence problem.</scope>`,
    { agentType: 'oppenheimer', label: `oppenheimer:${oppFile}`, phase: 'Design', schema: CRITIQUE_SCHEMA },
  )
  if (!critique) return failure('critique', 'design critique dispatch returned no result')
  if (!(await verifyArtifact(oppFile, 'Design'))) {
    return failure('critique', `critique artifact ${oppFile} missing or empty`)
  }
  if (critique.clean || critique.blockers.length === 0) break
  if (designReturns >= MAX_DESIGN_RETURNS) {
    return failure('critique', `design blockers persist after ${MAX_DESIGN_RETURNS} architect revisions`, {
      blockers: critique.blockers,
      designReturns,
    })
  }
  designReturns += 1
  log(`design blocked (${critique.blockers.length} findings), return ${designReturns}/${MAX_DESIGN_RETURNS} to the architect`)
  const revisionFile = await nextArtifact('babbage', 'Design')
  await agent(
    `<intent>Revise the design to resolve the blocking critique findings.</intent>
<inputs>Feature slug: ${featureSlug}. Work location: ${workLocation}. Blocking findings (location: problem):
${terse(critique.blockers)}</inputs>
<scope>Read the cited locations and the prior artifacts in the feature directory yourself; derive the resolution from the material. Write the revised design to ${revisionFile} in ${featureDirRef}.</scope>`,
    { agentType: 'babbage', label: `babbage:revision-${designReturns}`, phase: 'Design' },
  )
  if (!(await verifyArtifact(revisionFile, 'Design'))) {
    return failure('design', `revised design artifact ${revisionFile} missing or empty`)
  }
}

// ---------- Implement ----------

phase('Implement')

const implementation = await agent(
  `<intent>Implement the approved design.</intent>
<inputs>Feature slug: ${featureSlug}. Work location: ${workLocation}. Branch: ${branchName}. Mode: ${mode}.</inputs>
<scope>${baseVerification} Orient from the design artifacts in the feature directory and the codebase. Implement, write tests per your definition, and commit on the working branch.</scope>`,
  { agentType: 'lovelace', label: 'lovelace:implement', phase: 'Implement', schema: IMPLEMENT_SCHEMA },
)
if (!implementation) return failure('implement', 'implementation dispatch returned no result')
if (!implementation.workCommitted) {
  return failure('implement', 'implementer reports no committed work', { summary: implementation.summary })
}

// ---------- Review ----------

phase('Review')

let review
let iterations = 0
while (true) {
  const friedmanFile = await nextArtifact('friedman', 'Review')
  review = await agent(
    `<intent>Review the implementation for correctness, security, quality, tests, and pattern consistency.</intent>
<inputs>Feature slug: ${featureSlug}. Work location: ${workLocation}.</inputs>
<scope>Full independent pass over the current state of the working branch. Write your report to ${friedmanFile} in ${featureDirRef}. In the structured output, report blockers only, as location plus one-sentence problem.</scope>`,
    { agentType: 'friedman', label: `friedman:${friedmanFile}`, phase: 'Review', schema: CRITIQUE_SCHEMA },
  )
  if (!review) return failure('review', 'review dispatch returned no result')
  if (!(await verifyArtifact(friedmanFile, 'Review'))) {
    return failure('review', `review artifact ${friedmanFile} missing or empty`)
  }
  if (review.clean || review.blockers.length === 0) break
  if (iterations >= MAX_REVIEW_ITERATIONS) {
    return failure('review', `blockers persist after ${MAX_REVIEW_ITERATIONS} revision iterations`, {
      blockers: review.blockers,
      iterations,
    })
  }
  iterations += 1
  log(`review blocked (${review.blockers.length} findings), iteration ${iterations}/${MAX_REVIEW_ITERATIONS}`)
  const fix = await agent(
    `<intent>Resolve the review blockers on the working branch.</intent>
<inputs>Feature slug: ${featureSlug}. Work location: ${workLocation}. Branch: ${branchName}. Blockers (location: problem):
${terse(review.blockers)}</inputs>
<scope>${baseVerification} Read the code at the cited locations and derive each fix yourself. Commit the fixes. Flag anything you could not address.</scope>`,
    { agentType: 'lovelace', label: `lovelace:fix-${iterations}`, phase: 'Review', schema: IMPLEMENT_SCHEMA },
  )
  if (!fix) return failure('review', 'fix dispatch returned no result')
  if (!fix.workCommitted) return failure('review', 'fix iteration produced no committed work', { summary: fix.summary })
}

// ---------- Validate ----------

phase('Validate')

const curieFile = await nextArtifact('curie', 'Validate')
const validation = await agent(
  `<intent>Validate the implementation: assess coverage, write tests where needed, produce the validation plan.</intent>
<inputs>Feature slug: ${featureSlug}. Work location: ${workLocation}.</inputs>
<scope>Per your definition and protocols/validation-plan.md. Write the validation artifact to ${curieFile} in ${featureDirRef}. Report outcome, known risks, and open questions in the structured output.</scope>`,
  { agentType: 'curie', label: 'curie:validate', phase: 'Validate', schema: VALIDATE_SCHEMA },
)
if (!validation) return failure('validate', 'validation dispatch returned no result')
if (!(await verifyArtifact(curieFile, 'Validate'))) {
  return failure('validate', `validation artifact ${curieFile} missing or empty`)
}

// ---------- Scrub ----------

phase('Scrub')

const scrub = await agent(
  `<intent>Run the mob-context tone-and-identifier pass on the pipeline's output.</intent>
<inputs>Feature slug: ${featureSlug}. Work location: ${workLocation}.</inputs>
<scope>Mob context per your definition and protocols/asimov-catalog.md: code comments and any pr-description.md present in the feature directory. Edit in place, commit inside the work location. Report unresolved findings in the structured output; write asimov artifact only if there are any, per your definition.</scope>`,
  { agentType: 'asimov', label: 'asimov:scrub', phase: 'Scrub', schema: SCRUB_SCHEMA },
)
if (!scrub) return failure('scrub', 'tone-scrub dispatch returned no result')

// ---------- Done ----------

log('pipeline complete; squash and transport remain with the orchestrator')
return {
  status: 'complete',
  featureSlug,
  mode,
  designReturns,
  reviewIterations: iterations,
  validationOutcome: validation.outcome,
  knownRisks: validation.knownRisks,
  openQuestions: validation.openQuestions,
  unresolvedToneFindings: scrub.unresolvedFindings,
  nextSteps: 'Orchestrator: compose the commit-body kernel from knownRisks/openQuestions, squash working commits, and transport per protocols/local/worktree-transport.md and the deployment bridge protocol.',
}
