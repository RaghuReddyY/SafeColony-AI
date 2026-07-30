import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/section.dart';
import '../providers/section_provider.dart';
import 'section_form_screen.dart';

class SectionListScreen extends ConsumerStatefulWidget {
  final int? propertyId;
  final bool isSetupFlow;

  const SectionListScreen({
    super.key,
    this.propertyId,
    this.isSetupFlow = false,
  });

  @override
  ConsumerState<SectionListScreen> createState() =>
      _SectionListScreenState();
}

class _SectionListScreenState
    extends ConsumerState<SectionListScreen> {

  late Future<List<Section>> _sections;

  @override
  void initState() {
    super.initState();
    _loadSections();
  }

 void _loadSections() {

  if (widget.propertyId != null) {

    _sections = ref
        .read(sectionProvider)
        .loadSectionsByProperty(
          widget.propertyId!,
        );

  } else {

    _sections = ref
        .read(sectionProvider)
        .loadSections();

  }

}

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Sections"),
      ),

      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {

          final result =
              await Navigator.push(
            context,
            MaterialPageRoute(
            builder: (_) => SectionFormScreen(
                propertyId: widget.propertyId,
              ),
            ),
          );

          if (result == true) {

            setState(() {
              _loadSections();
            });

          }
        },
      ),

      body: FutureBuilder<List<Section>>(

        future: _sections,

        builder: (context, snapshot) {

          if (snapshot.connectionState ==
              ConnectionState.waiting) {

            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {

            return Center(
              child: Text(
                snapshot.error.toString(),
              ),
            );
          }

          final sections =
              snapshot.data ?? [];

          if (sections.isEmpty) {

            return const Center(
              child:
                  Text("No sections found"),
            );
          }

          return RefreshIndicator(

            onRefresh: () async {

              setState(() {
                _loadSections();
              });

            },

            child: ListView.builder(

              itemCount: sections.length,

              itemBuilder: (context, index) {

                final section =
                    sections[index];

                return Card(

                  margin:
                      const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),

                  child: ListTile(

                    leading: const Icon(
                      Icons.dashboard,
                    ),

                    title: Text(
                      section.name,
                    ),

                    subtitle: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [

                        Text(
                          section.description,
                        ),

                        const SizedBox(height: 4),

                        Text(
                          "Property ID : ${section.propertyId}",
                          style:
                              const TextStyle(
                            fontSize: 12,
                            color:
                                Colors.grey,
                          ),
                        ),
                      ],
                    ),

                    trailing:
                        PopupMenuButton<String>(

                      onSelected:
                          (value) async {

                        if (value ==
                            "edit") {

                          final result =
                              await Navigator
                                  .push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  SectionFormScreen(
                                section:
                                    section,
                              ),
                            ),
                          );

                          if (result ==
                              true) {

                            setState(() {
                              _loadSections();
                            });

                          }

                        }

                        if (value ==
                            "delete") {

                          final confirm =
                              await showDialog<
                                  bool>(
                            context:
                                context,
                            builder: (_) =>
                                AlertDialog(
                              title:
                                  const Text(
                                      "Delete Section"),
                              content:
                                  const Text(
                                "Are you sure you want to delete this section?",
                              ),
                              actions: [

                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(
                                          context,
                                          false),
                                  child:
                                      const Text(
                                          "Cancel"),
                                ),

                                ElevatedButton(
                                  onPressed: () =>
                                      Navigator.pop(
                                          context,
                                          true),
                                  child:
                                      const Text(
                                          "Delete"),
                                ),
                              ],
                            ),
                          );

                          if (confirm ==
                              true) {

                            await ref
                                .read(
                                    sectionProvider)
                                .deleteSection(
                                  section.id,
                                );

                            if (!mounted)
                              return;

                            ScaffoldMessenger.of(
                                    context)
                                .showSnackBar(
                              const SnackBar(
                                backgroundColor:
                                    Colors.green,
                                content: Text(
                                  "Section deleted successfully.",
                                ),
                              ),
                            );

                            setState(() {
                              _loadSections();
                            });

                          }
                        }
                      },

                      itemBuilder: (_) =>
                          const [

                        PopupMenuItem(
                          value: "edit",
                          child:
                              Text("Edit"),
                        ),

                        PopupMenuItem(
                          value: "delete",
                          child:
                              Text("Delete"),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      bottomNavigationBar: widget.isSetupFlow
    ? SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
            child: const Text("Finish Setup"),
          ),
        ),
      )
    : null,
    );
  }
}