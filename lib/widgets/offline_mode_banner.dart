import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Offline mode banner that displays at the top when no internet connection
class OfflineModeBanner extends StatefulWidget {
  const OfflineModeBanner({super.key});

  @override
  State<OfflineModeBanner> createState() => _OfflineModeBannerState();
}

class _OfflineModeBannerState extends State<OfflineModeBanner> {
  late Stream<ConnectivityResult> _connectivityStream;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _connectivityStream = Connectivity().onConnectivityChanged;
    _checkInitialConnection();
  }

  Future<void> _checkInitialConnection() async {
    final result = await Connectivity().checkConnectivity();
    if (mounted) {
      setState(() {
        _isOnline = result != ConnectivityResult.none;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ConnectivityResult>(
      stream: _connectivityStream,
      initialData: ConnectivityResult.mobile,
      builder: (context, snapshot) {
        bool isOnline = snapshot.data != ConnectivityResult.none;

        if (_isOnline != isOnline) {
          Future.microtask(() {
            if (mounted) {
              setState(() => _isOnline = isOnline);
            }
          });
        }

        return AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: SafeArea(
            bottom: false,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.9),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.wifi_off_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'İnternet bağlantısı yok. Veriler senkronize edilemeyecek.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          crossFadeState: !_isOnline
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
        );
      },
    );
  }
}
