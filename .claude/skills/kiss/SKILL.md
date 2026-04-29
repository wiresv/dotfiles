---
name: kiss
description: Use when starting system design, implementation, refactoring, or dependency selection. Also use when the user asks for minimal, boring, or "least clever" solutions, when complexity is creeping into a design, when speculative requirements or over-engineering are stalling work, or when reviewing recent changes for unnecessary abstraction, dead options, or premature flexibility.
---

# Keep It Simple Paradigm (KISS)

Stop. Before designing or writing anything, shift your default posture. You are about to make decisions whose costs accumulate every time someone reads, modifies, debugs, or extends this code. Most of those readers will not be you, and most of them will arrive without your context.

In this mode, **simplicity is the default and complexity must justify itself.** Every concept, every layer, every option, every dependency, and every line is a liability. They earn their place by solving a real problem that exists *right now*, not one you imagine might exist later.

## What "simple" means here

"Simple" is not "easy" and not "short." It is:

- **Few concepts.** Fewer types, fewer layers, fewer moving parts, fewer things a reader must hold in their head at once.
- **Untangled.** One unit does one thing. Concerns do not bleed into each other. (Hickey's "simple," not "easy.")
- **Direct.** The shortest reasonable path from input to outcome. No detour through indirection that doesn't pay rent.
- **Boring.** The thing a competent engineer would expect, written the way the language and codebase already do it.
- **Reversible.** Easy to delete, replace, or change later — because complexity arrives eventually, and reversibility is what lets you defer it cheaply.

Short, clever, "elegant" code is *not* automatically simple. A four-line metaprogramming trick that nobody else can debug is more complex than twenty lines of obvious procedure.

## Core principles

These are sharp on purpose. Apply them by default. The "when this bends" notes appear only on principles whose exceptions are non-obvious.

- **YAGNI — You Aren't Gonna Need It.** Build only what is required by a real requirement that exists today. Speculative features, options, and abstractions get cut.
- **Rule of Three.** Don't extract an abstraction until you have at least three real, divergent uses. Two cases is a coincidence; three is a pattern. *When this bends:* a true external boundary (HTTP, plugin, public API, persistence schema) — extract once, because the boundary itself is the abstraction.
- **The best code is no code.** The cheapest line is the one you didn't write. Before writing, look for: deletion, the standard library, code already present in the codebase.
- **Boring technology wins.** Prefer the language's standard tools, the framework's intended path, and the dependency everyone already uses. Novelty has a tax paid every day.
- **Inline before extract.** Write the three lines inline. If the same shape appears a third time, unchanged, *then* extract.
- **Make it work, then make it right, then (maybe) make it fast.** In that order. Optimization without measurement is fiction.
- **The simplest thing that could possibly work.** Solve the actual problem in front of you. Not the generalized version. Not the configurable version. The actual one.
- **Reversibility before flexibility.** A reversible decision needs no flexibility built in — you can change it later cheaply. Flexibility ("we might want to swap X someday") is complexity you pay for now to avoid a cost you may never incur.
- **Minimum viable surface area.** Public functions, exported types, config options, CLI flags, environment variables — every one of these is a contract you'll have to keep. Expose the smallest set that satisfies real callers.
- **Premature abstraction is a sin equal to premature optimization.** Both freeze a guess about the future into the structure of the code.
- **Cognitive load is the budget.** What a reader can hold in their head simultaneously is the limit. If they can't, the design is wrong, no matter how clean each piece looks in isolation.
- **Violating the letter of these rules is usually violating the spirit.** Don't talk yourself into a special case.

## Anti-patterns to refuse to write

When you notice yourself about to do any of these, **stop and choose the simpler default.**

**Speculative parameters and config knobs.** A function with options nobody passes. A config file with values nobody overrides. A flag that exists "in case." → Delete it. Add it the day a real caller needs it.

**Framework-of-one.** A plugin system, registry, factory, or strategy pattern with one implementation. → Replace with the one implementation, inlined.

**Premature DRY.** Two pieces of code that look alike but represent different concepts, merged into a single helper that now grows flags to satisfy both callers. Coincidental duplication is not duplication. → Keep them separate until they truly diverge or truly converge.

**Defensive code for impossible states.** Validating that an internal function received the type its signature already guarantees. Try/catches around code that cannot throw. Null checks for values that cannot be null. → Trust internal code. Validate once at system boundaries.

**Deep inheritance and ceremonial OO.** Class hierarchies with one or two real subclasses. `AbstractBaseFooFactoryProvider`. → Use a function. Use composition. Use a plain record/struct.

**Microservices for a monolith problem.** Splitting a service that fits in one process into many because of pattern aspiration, not real load or boundary needs. → Start as a monolith. Split when there is a measured reason.

**Abstraction layers that don't pay rent.** A "service layer" that just forwards to a "repository layer" that just forwards to the ORM. → Collapse. Add the layer back if and when it earns its keep.

**Custom solutions for solved problems.** Hand-rolled date math, hand-rolled CSV parsing, hand-rolled retry loops, hand-rolled DI containers. → Use the library or the standard. Reach for "custom" only when the off-the-shelf option genuinely doesn't fit.

**Configuration explosion.** Env vars and flags for every constant. Configuration that is never set in any deployment. → Inline the constant. Promote it to config the day a real environment needs a different value.

**"Just in case" code and dead branches.** `if (false)`, commented-out blocks, feature flags whose decision was made months ago, unused exports kept "for symmetry." → Delete. Git remembers.

**Premature interfaces.** Defining `IThing` before you have one `Thing`. → Write the concrete first. Extract an interface only when there are real callers needing to vary the implementation.

**Speculative generality.** Type parameters with one instantiation. Hooks that no one calls. Extension points nobody extends. → Concrete first. Generalize on demand.

**Custom DSLs and config languages.** A YAML schema that grows expressions, conditionals, includes. → Either it's data (keep it flat) or it's code (write code).

**Comment-driven complexity.** Long block comments explaining why a tangled piece of code is necessary. → The complexity is the bug. Simplify until the comment isn't needed.

**Future-proofing for hypothetical scale.** Sharding, caching layers, queues, and read replicas added before measured load demands them. → Solve the load you have. Architectural fixes for imagined load are guesses with debt attached.

## Decision heuristics

Sharp rules to apply at the moment of decision. "When this bends" notes only where the exception is non-obvious.

**One file until proven otherwise.** If it fits comfortably in one file, it lives in one file. New directories and packages need a real reason. *When this bends:* a true module boundary (separately deployable, separately testable, separately ownable).

**Don't extract until three real instances exist.** Two is a coincidence; three is a pattern.

**No config option without two real callers needing different values.** Constants are config-of-one. Promote to config only on real demand.

**Prefer the standard library.** A new dependency must save more than its cost (transitive deps, supply chain, version drift, learning tax, install size).

**One datastore until you can't.** Don't add Redis/Elasticsearch/queue-of-the-week until the existing store actually fails the workload.

**Synchronous before asynchronous.** Don't introduce queues, background workers, or event buses until a synchronous call genuinely cannot do the job.

**Validate at the edge, trust the interior.** Untrusted input is checked once, where it enters the system. Internal callers are not adversaries.

**Errors only where you can do something useful.** Don't catch what you can't handle. Let it propagate to the boundary that can.

**Comments only when the WHY is non-obvious.** Hidden constraint, subtle invariant, workaround for a specific bug, behavior that would surprise a reader. Don't narrate the WHAT — names do that.

**Names: short and concrete beats long and ceremonial.** `users` over `UserCollectionManager`. `send` over `executeMessageDispatchOperation`. Length should match scope: tiny for local, longer for public.

**Delete > rewrite > extend.** When something is wrong, ask whether you can remove it before asking whether you can replace it.

**Reversible commits over big-bang refactors.** Many small, locally correct changes; not one heroic restructure.

**Prefer pure functions and plain data.** They are the simplest unit of reasoning and the easiest to test, move, and delete.

## How KISS applies by activity

### System design

- Start with the **fewest moving parts** that could plausibly satisfy the requirements.
- **Monolith first.** Decompose only when a real boundary forces it (independent scaling, independent deploy cadence, independent ownership, regulatory isolation).
- **One datastore. One language. One deployment unit.** Add a second only on hard evidence.
- **Synchronous request/response** before queues, streams, or events.
- Choose tools you and the team already know. Novelty is a tax paid every day.
- The design at the level a new engineer could explain back to you in five minutes. If you can't get there, it's too complex — keep cutting.

### Implementation

- Write the **inline three lines** before reaching for a helper.
- **Smallest API surface that satisfies the caller.** Add parameters when callers need them, not before.
- **Make it work first.** Get the happy path running end-to-end. Then handle real edge cases. Then refine.
- Prefer **plain data** (records, structs, dicts) over class hierarchies for things that are just data.
- **One way to do it.** If two patterns coexist for the same job, pick one and migrate; don't add a third.

### Refactoring

- **Delete first, extract second.** If you can't delete it, you probably shouldn't extract it either.
- Refactor in **small, reversible commits**. Each one passes tests on its own.
- Don't expand scope. The bug fix is the bug fix. Cleanup happens in a separate change.
- If a refactor adds more concepts than it removes, **stop** and reconsider.

### Debugging

- **Simplest hypothesis first.** It's almost always the obvious thing.
- **Remove code rather than add code.** Bisect by deletion. Comment out, narrow, isolate.
- **Revert before patch.** If a recent change caused this, reverting is usually the smaller fix than diagnosing forward.
- Don't add layers of logging, retries, or fallbacks to mask a bug. Find the cause and remove it.

### Dependency choices

- **Boring, popular, maintained, narrow.** A dependency that does one thing, has many users, gets regular releases, and adds few friends.
- **Read the install footprint.** Transitive deps, install size, native modules, security history.
- **Standard library first.** A `for` loop is not worth a 200kb package.
- A dependency must save **more time than it costs over its lifetime** — including the day you have to remove it.

## Red-flag thoughts

When any of these surface, you are rationalizing. Stop.

| Thought | What it really means | Default to |
|---------|----------------------|------------|
| "We might need this later." | We have no evidence we will. | Don't add it. Add it the day a real need appears. |
| "This is more flexible." | This adds knobs nobody is turning. | Remove the flexibility. Hardcode the actual case. |
| "This is cleaner." | This is more layers. | Inline it. |
| "This is the proper way." | I learned a pattern and want to use it. | Use the pattern when the problem demands it, not when the pattern wants a host. |
| "What if we want to swap implementations?" | Speculative interface. | Concrete first. Extract when a second real implementation appears. |
| "Just in case." | No real case. | Don't write it. |
| "It's only a few extra lines." | Each line is read many times more than it is written. | Cut them. |
| "We'll clean it up later." | We won't. | Do less now, so there is less to clean. |
| "Let me add a config option for that." | One caller wanted it once. | Hardcode. Promote to config when a second caller needs a different value. |
| "Let me handle this just in case." | Defensive code for an impossible state. | Trust internal code. Validate at edges. |
| "Let me extract this helper." | Two similar lines. | Inline until three. |
| "This is elegant." | This is clever. | Choose obvious over clever. |
| "It's the same pattern we used before." | The shape matches; the meaning may not. | Compare meanings, not shapes, before unifying. |
| "I'll generalize while I'm in here." | Scope creep dressed as efficiency. | Make the change you came to make. Open a separate change for anything else. |

## Closing posture

**When in doubt, choose less.** Less code, fewer concepts, fewer dependencies, fewer layers, fewer options.

The cost of removing complexity later is much higher than the cost of adding it later. Code that exists must be read, maintained, ported, debugged, secured, and eventually deleted. Code that doesn't exist costs nothing.

Your goal is not the cleverest design. Your goal is the design a competent reader can fully understand on first read, change without fear, and delete without regret.
