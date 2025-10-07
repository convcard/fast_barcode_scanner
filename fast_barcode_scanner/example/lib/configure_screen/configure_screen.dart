import 'package:fast_barcode_scanner/fast_barcode_scanner.dart';
import 'package:flutter/material.dart';

import 'type_selector.dart';

class ConfigureScreen extends StatefulWidget {
  const ConfigureScreen({super.key});

  @override
  State<ConfigureScreen> createState() => _ConfigureScreenState();
}

class _ConfigureScreenState extends State<ConfigureScreen> {
  _ConfigureScreenState();

  final cameraController = CameraController.shared;

  @override
  Widget build(BuildContext context) {
    final state = cameraController.state.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuration'),
        leading: BackButton(
          onPressed: () async {
            final shouldReturn = await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Apply Changes?'),
                content: const Text('Return without applying changes?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Ok'),
                  ),
                ],
              ),
            );

            if (shouldReturn && context.mounted) {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: applyChanges,
            child: const Text(
              'Apply',
              style: TextStyle(color: Colors.white),
            ),
          )
        ],
      ),
      body: ListView(
        children: ListTile.divideTiles(
          context: context,
          tiles: [
            ListTile(
              title: const Text('Active code types'),
              subtitle: Text(state.scannerConfig!.types.map((e) => e.name).join(', ')),
              onTap: () async {
                final types = await Navigator.push<List<BarcodeType>>(context, MaterialPageRoute(builder: (_) {
                  return BarcodeTypeSelector(state.scannerConfig!);
                }));
                // TODO: Update camera config
              },
            ),
            // ListTile(
            //   title: const Text('Mode'),
            //   trailing: DropdownButton<PerformanceMode>(
            //       value: state.scannerConfig!.mode,
            //       onChanged: (value) {
            //         // TODO: Update camera config
            //       },
            //       items: buildDropdownItems(PerformanceMode.values)),
            // ),
            ListTile(
              title: const Text('Position'),
              trailing: DropdownButton<CameraPosition>(
                  value: state.scannerConfig!.position,
                  onChanged: (value) {
                    // TODO: Update camera config
                  },
                  items: buildDropdownItems(CameraPosition.values)),
            ),
            ListTile(
              title: const Text('Detection Mode'),
              trailing: DropdownButton<DetectionMode>(
                value: state.scannerConfig!.mode,
                onChanged: (value) {
                  // TODO: Update camera configt
                },
                items: buildDropdownItems(DetectionMode.values),
              ),
            ),
            const Divider(),
            //   CheckboxListTile(
            //   value: _selected.contains(item),
            //   title: Text("Material Design"),
            //   onChanged: (newValue) {
            //     setState(() {
            //       if (newValue == true) {
            //         _selected.add(item);
            //       } else {
            //         _selected.remove(item);
            //       }
            //     });
            //   },
            // );
          ],
        ).toList(),
      ),
    );
  }

  List<DropdownMenuItem<E>> buildDropdownItems<E extends Enum>(List<E> enumCases) =>
      enumCases.map((v) => DropdownMenuItem(value: v, child: Text(v.name))).toList();

  Future<void> applyChanges() async {
    try {
      await CameraController.shared.configure(
        types: cameraController.state.value.scannerConfig!.types,
        mode: cameraController.state.value.scannerConfig!.mode,
        position: cameraController.state.value.scannerConfig!.position,
      );
    } catch (error) {
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Fehler'),
          content: Text(error.toString()),
        ),
      );

      return;
    } finally {
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }
}
