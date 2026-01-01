import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/product_model.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  late Map<ProductCategory, bool> _categorySelections;
  bool _isSaving = false;

  static const String _prefsKey = 'notification_categories';

  @override
  void initState() {
    super.initState();
    _categorySelections = {for (final c in ProductCategory.values) c: false};
    _loadPrefs();
  }

  @override
  Widget build(BuildContext context) {
    final allEnabled = _categorySelections.values.every((v) => v);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Preferences'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : () {
              setState(() {
                final newValue = !allEnabled;
                for (final key in _categorySelections.keys) {
                  _categorySelections[key] = newValue;
                }
              });
            },
            child: Text(
              allEnabled ? 'Disable All' : 'Enable All',
              style: TextStyle(
                color: allEnabled 
                    ? Colors.red 
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Choose which product categories you want to receive notifications for.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              if (kIsWeb)
                Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 20,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Web notification preferences are saved locally',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              ...ProductCategory.values.map((category) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: SwitchListTile(
                    value: _categorySelections[category] ?? false,
                    onChanged: (value) {
                      setState(() {
                        _categorySelections[category] = value;
                      });
                    },
                    title: Text(category.displayName),
                    subtitle: Text(_getSubtitle(category)),
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (_categorySelections[category] ?? false)
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _iconFor(category),
                        color: (_categorySelections[category] ?? false)
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(_isSaving ? 'Saving...' : 'Save Preferences'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getSubtitle(ProductCategory category) {
    switch (category) {
      case ProductCategory.electronics:
        return 'Notifications for electronics products';
      case ProductCategory.furniture:
        return 'Notifications for furniture products';
      case ProductCategory.clothing:
        return 'Notifications for clothing products';
      case ProductCategory.books:
        return 'Notifications for books';
      case ProductCategory.toys:
        return 'Notifications for toys and games';
      case ProductCategory.vehicles:
        return 'Notifications for vehicles';
      case ProductCategory.healthbeauty:
        return 'Notifications for health and beauty products';  
      case ProductCategory.homegarden:
        return 'Notifications for home and garden products';
      case ProductCategory.sports:
        return 'Notifications for sports equipment';
      case ProductCategory.toolsandequipment:
        return 'Notifications for tools and equipment';  
      case ProductCategory.other:
        return 'Notifications for other product categories';
    }
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      setState(() {
        for (final entry in decoded.entries) {
          final category = ProductCategory.values.firstWhere(
            (c) => c.name == entry.key,
            orElse: () => ProductCategory.other,
          );
          _categorySelections[category] = entry.value as bool? ?? false;
        }
      });
    } catch (_) {
      // Ignore malformed prefs
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      // Ensure notifications are allowed before subscribing to topics
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.getNotificationSettings();
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bildirim izni kapalı. Lütfen sistem ayarlarından açın.'),
            ),
          );
        }
        return;
      }

      // Persist selections
      final prefs = await SharedPreferences.getInstance();
      final mapToSave = {
        for (final entry in _categorySelections.entries)
          entry.key.name: entry.value,
      };
      await prefs.setString(_prefsKey, jsonEncode(mapToSave));

      // Subscribe/unsubscribe topics per category (not supported on web)
      if (!kIsWeb) {
        for (final entry in _categorySelections.entries) {
          final topic = _topicFor(entry.key);
          if (entry.value) {
            await messaging.subscribeToTopic(topic);
          } else {
            await messaging.unsubscribeFromTopic(topic);
          }
        }
      }

      // Save preferences to Firestore for web notification targeting
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .set({
            'notificationPreferences': mapToSave,
          }, SetOptions(merge: true));
        } catch (_) {
          // Ignore Firestore save errors
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preferences saved.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String _topicFor(ProductCategory category) => 'category_${category.name}';
  IconData _iconFor(ProductCategory category) {
    switch (category) { 
      case ProductCategory.electronics:
        return Icons.electrical_services;
      case ProductCategory.furniture:
        return Icons.chair;
      case ProductCategory.clothing:
        return Icons.checkroom;
      case ProductCategory.books:
        return Icons.book;
      case ProductCategory.toys:
        return Icons.toys;
      case ProductCategory.vehicles:
        return Icons.directions_car;
      case ProductCategory.healthbeauty:
        return Icons.health_and_safety;  
      case ProductCategory.homegarden:
        return Icons.grass;
      case ProductCategory.sports:
        return Icons.sports_soccer;
      case ProductCategory.toolsandequipment:
        return Icons.build;  
      case ProductCategory.other:
        return Icons.category;

 
    }
  }
}