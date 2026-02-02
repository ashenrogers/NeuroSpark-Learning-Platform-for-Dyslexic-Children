import 'dart:math';
import 'package:flutter/material.dart';

class MorphRecallScreen extends StatefulWidget {
  final List<String> correctOrder;
  final String Function(String label) iconAssetForLabel;

  const MorphRecallScreen({
    super.key,
    required this.correctOrder,
    required this.iconAssetForLabel,
  });
  

  @override
  State<MorphRecallScreen> createState() => _MorphRecallScreenState();
}

class _MorphRecallScreenState extends State<MorphRecallScreen> {
  late final List<String> pool;
  late List<String?> slots;

  @override
  void initState() {
    super.initState();
    final unique = widget.correctOrder.toSet().toList();
    unique.shuffle(Random());
    pool = unique;
    slots = List<String?>.filled(widget.correctOrder.length, null);
  }

  bool get isComplete => slots.every((e) => e != null);

  void reset() {
    setState(() {
      slots = List<String?>.filled(widget.correctOrder.length, null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        title: const Text("Recall Sequence"),
        actions: [
          TextButton(
            onPressed: reset,
            child: const Text(
              "Reset",
              style: TextStyle(color: Colors.white),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          // ===== MEDICAL MONITORING STRIP (NON-OVERLAY) =====
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.black12),
              ),
            ),
            
          ),

          // ===== TASK CONTENT =====
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Instruction Card
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          const Icon(Icons.visibility,
                              color: Colors.blueGrey),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Drag the icons into the exact order you saw.",
                              style:
                                  Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Slots Grid
                  Expanded(
                    child: GridView.builder(
                      itemCount: slots.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                      ),
                      itemBuilder: (_, i) {
                        return DragTarget<String>(
                          onWillAcceptWithDetails: (_) => true,
                          onAcceptWithDetails: (d) {
                            setState(() => slots[i] = d.data);
                          },
                          builder: (context, candidates, rejects) {
                            final label = slots[i];
                            return Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  width: 2,
                                  color: candidates.isNotEmpty
                                      ? Colors.blue
                                      : Colors.black26,
                                ),
                                color: Colors.white,
                              ),
                              child: Center(
                                child: label == null
                                    ? Text(
                                        "${i + 1}",
                                        style: const TextStyle(
                                          fontSize: 18,
                                          color: Colors.black38,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      )
                                    : Image.asset(
                                        widget.iconAssetForLabel(label),
                                        fit: BoxFit.contain,
                                      ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Options
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Options",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: pool.map((label) {
                      final icon = widget.iconAssetForLabel(label);
                      return Draggable<String>(
                        data: label,
                        feedback: Material(
                          color: Colors.transparent,
                          child: _OptionTile(icon: icon, elevated: true),
                        ),
                        childWhenDragging: Opacity(
                          opacity: 0.35,
                          child: _OptionTile(icon: icon),
                        ),
                        child: _OptionTile(icon: icon),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isComplete
                          ? () {
                              Navigator.pop(
                                context,
                                slots.whereType<String>().toList(),
                              );
                            }
                          : null,
                      child: const Text("Submit"),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String icon;
  final bool elevated;

  const _OptionTile({required this.icon, this.elevated = false});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: elevated ? 4 : 0,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 72,
        height: 72,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black12),
          color: Colors.white,
        ),
        child: Image.asset(icon, fit: BoxFit.contain),
      ),
    );
  }
}
