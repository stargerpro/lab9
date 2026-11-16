# Lab 9 Notes

## Part 1

**Why is CartLine immutable?**
Riverpod, Cubit and Bloc only update the UI when they get a *new* state object. If I changed `qty` in place, it's the same object, so nothing rebuilds. setState would still work, because it rebuilds every time. That's the trap: it works in setState and silently breaks in the other three.

**Why does CartBody take callbacks?**
So one UI widget works with all four styles. CartBody just shows data and calls functions. It doesn't care where the state lives.

## Part 2 (setState)

**Why not store `total`?**
It depends on lines and coupon. If it's stored, I must update it every time they change, and forgetting once shows a wrong total. As a getter it's always correct.

**Why `if (!mounted) return;` after await?**
If the user leaves the page during checkout, the State is disposed. Calling setState after that throws an error.

**T6:** most of the widget test is finding and tapping widgets. Only the last line checks the actual total.

**How would a second page read the cart?**
It can't. The cart is a private field of this page and is gone when the page closes. I'd have to move it higher up and pass it down (prop drilling), or use a state management library.

**Where does `_history` live? Hot reload vs hot restart?**
In the page's State. Hot reload keeps it. Hot restart wipes it.

## Part 3 (Riverpod)

**ref.read (3 places):**
- `ref.read(cartProvider.notifier)` in the page, just to call methods.
- `ref.read(checkoutApiProvider)` in checkout, a one-time lookup.
- `ref.read(cartProvider)` inside `ref.listen`, reading once in a callback.

**ref.watch (2 places):**
- `ref.watch(cartProvider)` in the page, because it shows the lines.
- `ref.watch(cartProvider.select((s) => s.total))` in the total widget, because it shows only the total.

**Why does the summary rebuild less than in setState?**
setState reruns the whole build every time. Here the total widget only watches `total`, so it rebuilds only when the total changes.

**Same coupon twice, does it notify?** Without `==`, yes, because every `copyWith` is a new object. With `==` and `hashCode`, the states are equal, so no notify.

**Why no mounted check?** The state lives in the provider, not the page. Leaving the page doesn't destroy it.

**What does canUndoProvider watch?** `cartProvider`. `_history` is a normal field, so changing it notifies nobody.

**autoDispose:** when I leave the page, nobody watches the provider, so it's destroyed. The cart and history are gone.

## Part 4 (Cubit)

**BlocProvider inside CartBody?**
The page above it (BlocBuilder, BlocListener, context.read) couldn't find the cubit and would crash. The cubit would also be recreated on rebuild and lose its state.

**Riverpod equivalents:**
- BlocProvider = ProviderScope + provider
- BlocBuilder = ref.watch
- BlocListener = ref.listen
- context.read = ref.read
- buildWhen = select

**Same coupon twice:** the second emit is dropped because the state is equal.

**emit after close:** throws an error, so I check `if (isClosed) return;`.

**Undo:** a getter on the cubit doesn't rebuild the UI. Only a new state does. So I put history inside CartState.

## Part 5 (Bloc)

**When are events worth it?**
When I want to see what caused each change, and control how events run. Checkout is better in Bloc (`droppable()` ignores extra taps). Adding a product is just overhead (an event class for a one-liner).

**Drop duplicate taps declaratively?**
Only Bloc, with `droppable()`. In the others I check by hand: `if (submitting) return;`.

**Observer vs Cubit onChange:** the observer also shows *which event* caused the change.

**Triple-tap checkout:** only the first one runs. Cubit without a guard would send three requests. After await I check `emit.isDone`.

**Undoable events:** add, remove, change qty, coupon. Not checkout or undo. I used a switch on the sealed event type.

## Checkpoint questions

**1. Where state lives and when it dies:**
- setState: in the page, dies when the page closes.
- Riverpod: in the provider, lives for the whole app.
- Cubit: in BlocProvider, dies when the page closes.
- Bloc: same as Cubit.

**2. The one way to change state:**
Riverpod: `state = ...`. Cubit: `emit()`. Bloc: `add(event)`. setState has none, it's just a private field.

**3. Mapping:**
ref.watch = BlocBuilder, ref.read = context.read, ref.listen = BlocListener. setState does all of it by hand: change the data, rebuild everything.

**4. Why skip when the state is equal?**
To avoid useless rebuilds. CartState must be (1) immutable and (2) have `==` and `hashCode`.

**5. Guard after await:**
- setState: `mounted`, the page may be gone.
- Riverpod: nothing, the provider outlives the page.
- Cubit: `isClosed`, the cubit is closed when the page closes.
- Bloc: `emit.isDone`, the handler is finished when the bloc closes.

## Stretch goals

**1. Observers:** (paste both logs here)
Bloc's log shows which event caused each change. Riverpod's only shows the new value.

**2. Persistence:** the toJson/fromJson code lives in the model and is shared.
Riverpod needed more wiring (prefs provider, override in main, listenSelf).
Bloc only needed a small subclass with HydratedMixin; it saves automatically.

**4. Debounce:** Bloc was easier, it's one transformer on the event.
Riverpod needed a Timer by hand, and I had to remember to cancel it in onDispose.

## Comparison table

| Style | Lines (T1–T5) | Test lines | Files | Strength | Weakness |
| --- | --- | --- | --- | --- | --- |
| setState | | | 1 | Simplest, no extra concepts | State stuck in one page, rebuilds everything |
| Riverpod | | | 2 | Little code, precise rebuilds, easy tests | Fields on the notifier aren't watchable |
| Cubit | | | 2 | Simple methods + emit, tests check every state | Tied to the page, getters not watchable |
| Bloc | | | 3 | Every change is a named event, droppable | Most boilerplate |