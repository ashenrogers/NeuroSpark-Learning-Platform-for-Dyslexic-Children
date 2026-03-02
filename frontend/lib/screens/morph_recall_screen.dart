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
      backgroundColor: const Color(0xFFF4F5F7), // Soft, low-glare background
      appBar: AppBar(
        title: const Text(
          "Recall Sequence",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: const Color(0xFF2D3142),
        actions: [
          TextButton(
            onPressed: reset,
            child: const Text(
              "Reset",
              style: TextStyle(
                color: Color(0xFF2D3142),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        ],
      ),
      body: Column(
        children: [
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
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.blueAccent.withOpacity(0.3), 
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blueAccent.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.drag_indicator_rounded, size: 36, color: Colors.blueAccent),
                        ),
                        const SizedBox(width: 20),
                        const Expanded(
                          child: Text(
                            "Drag the shapes into the correct order!",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              height: 1.4,
                              letterSpacing: 0.5,
                              color: Color(0xFF2D3142),
                            ),
                          ),
                        ),
                      ],
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
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Shapes to choose from:",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2D3142),
                        letterSpacing: 0.5,
                      ),
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
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50), // Friendly Green
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: isComplete
                          ? () {
                              Navigator.pop(
                                context,
                                slots.whereType<String>().toList(),
                              );
                            }
                          : null,
                      child: const Text(
                        "Submit",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
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
      elevation: elevated ? 6 : 0,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 80,
        height: 80,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.blueAccent.withOpacity(0.2), width: 2),
          color: Colors.white,
        ),
        child: Image.asset(icon, fit: BoxFit.contain),
      ),
    );
  }
}
