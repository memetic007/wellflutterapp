import 'package:flutter/material.dart';
import '../models/conf.dart';

class ConfView extends StatelessWidget {
  final List<Conf> confs;
  final Function(Conf?) onConfSelected;

  const ConfView({
    super.key,
    required this.confs,
    required this.onConfSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800),
        child: ListView.builder(
          itemCount: confs.length,
          itemBuilder: (context, index) {
            final conf = confs[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: ListTile(
                title: RichText(
                  text: TextSpan(
                    style: DefaultTextStyle.of(context).style,
                    children: [
                      TextSpan(
                        text: conf.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      TextSpan(
                        text: ' (${conf.topics.length} topics) ',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[850],
                        ),
                      ),
                    ],
                  ),
                ),
                onTap: () => onConfSelected(conf),
              ),
            );
          },
        ),
      ),
    );
  }
}
