// Copy into lib/main.dart of a fresh `dn create` scaffold.
// The scaffold owns platform bindings and local license configuration.
import 'dart:convert';

import 'package:dartnative/dartnative.dart';

import 'dartnative_plugin_registrant.dart';

int mountSerial = 0;
int eventSerial = 0;

void main() {
  DartNativePluginRegistrant.registerAll();
  runApp(const ThemeRetentionRepro());
}

class ThemeRetentionRepro extends StatefulWidget {
  const ThemeRetentionRepro({super.key});

  @override
  State<ThemeRetentionRepro> createState() => _ThemeRetentionReproState();
}

class _ThemeRetentionReproState extends State<ThemeRetentionRepro> {
  final draft = TextEditingController(text: 'Initial draft');
  final focus = FocusNode();
  final scroll = ScrollController();
  late final int generation;
  int count = 0;

  @override
  void initState() {
    super.initState();
    generation = ++mountSerial;
    record('mount');
  }

  void record(String event) {
    // Synthetic data only. A surviving isolate keeps event/mount serials,
    // making a new State distinguishable from a fresh process launch.
    print(
      'DN_THEME_REPRO ${jsonEncode({
        'sequence': ++eventSerial,
        'event': event,
        'generation': generation,
        'state_id': identityHashCode(this),
        'controller_id': identityHashCode(draft),
        'count': count,
        'text': draft.text,
        'selection': [draft.selection.start, draft.selection.end],
        'focus': focus.hasFocus,
        'scroll': scroll.hasClients ? scroll.offset : null,
      })}',
    );
  }

  void seed() {
    draft.value = const TextEditingValue(
      text: 'Edited locally',
      selection: TextSelection(baseOffset: 1, extentOffset: 6),
    );
    focus.requestFocus();
    if (scroll.hasClients) scroll.jumpTo(120);
    setState(() => count = 7);
  }

  @override
  void dispose() {
    record('dispose');
    draft.dispose();
    focus.dispose();
    scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    final foreground = dark ? Colors.white : Colors.black;
    final background = dark ? Colors.black : Colors.white;
    final textStyle = TextStyle(color: foreground, fontSize: 18);
    return Scaffold(
      brightness: dark ? Brightness.dark : Brightness.light,
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        title: Text('OS theme retention repro', style: textStyle),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('OS ${dark ? 'dark' : 'light'}', style: textStyle),
            Text('State generation $generation', style: textStyle),
            Text('Count $count', style: textStyle),
            TextField(controller: draft, focusNode: focus, style: textStyle),
            TextButton(onPressed: seed, child: const Text('Seed state')),
            TextButton(
              onPressed: () => record('capture'),
              child: const Text('Capture state'),
            ),
            SizedBox(
              height: 132,
              child: ListView(
                controller: scroll,
                children: [
                  for (var i = 0; i < 24; i++)
                    SizedBox(
                      height: 44,
                      child: Text('Retained row $i', style: textStyle),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
