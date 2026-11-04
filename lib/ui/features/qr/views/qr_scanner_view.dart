import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:gudang_mobile/core/constants/app_colors.dart';
import '../../products/views/product_detail_view.dart';
import '../view_models/scanner_view_model.dart';
import 'stock_action_modal.dart';

class QrScannerView extends StatefulWidget {
  final ScannerMode mode;

  const QrScannerView({
    super.key,
    this.mode = ScannerMode.search,
  });

  @override
  State<QrScannerView> createState() => _QrScannerViewState();
}

class _QrScannerViewState extends State<QrScannerView> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _isProcessing = false;
  late ScannerMode _currentMode;

  @override
  void initState() {
    super.initState();
    _currentMode = widget.mode;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onBarcodeDetected(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final rawValue = barcodes.first.rawValue;
    if (rawValue == null || rawValue.trim().isEmpty) return;

    _handleScannedSku(rawValue.trim());
  }

  void _handleScannedSku(String sku) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    final scannerVm = context.read<ScannerViewModel>();
    final product = await scannerVm.processScannedCode(sku);

    if (!mounted) return;

    if (product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            scannerVm.errorMessage ?? 'Barang dengan SKU "$sku" tidak ditemukan.',
          ),
          backgroundColor: AppColors.critical,
          duration: const Duration(seconds: 3),
        ),
      );
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) setState(() => _isProcessing = false);
      return;
    }

    // Action based on mode
    if (_currentMode == ScannerMode.search) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailView(product: product),
        ),
      );
      if (mounted) setState(() => _isProcessing = false);
    } else {
      // Inbound or Outbound mode
      final initialType = _currentMode == ScannerMode.inbound ? 'IN' : 'OUT';
      final updated = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => StockActionModal(
          product: product,
          initialType: initialType,
        ),
      );

      if (mounted) {
        setState(() => _isProcessing = false);
        if (updated == true && Navigator.canPop(context)) {
          Navigator.pop(context, true);
        }
      }
    }
  }

  void _showManualInputDialog() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Input SKU Manual'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gunakan jika kamera bermasalah atau pada emulator / PC:',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                hintText: 'Contoh: ELK-001, KMS-001',
                prefixIcon: Icon(Icons.qr_code, size: 20),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = textController.text.trim();
              Navigator.pop(ctx);
              if (val.isNotEmpty) {
                _handleScannedSku(val);
              }
            },
            child: const Text('Cari'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(_getTitle()),
        actions: [
          IconButton(
            tooltip: 'Senter / Flash',
            icon: const Icon(Icons.flash_on, color: Colors.white),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            tooltip: 'Putar Kamera',
            icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
            onPressed: () => _controller.switchCamera(),
          ),
          IconButton(
            tooltip: 'Input Manual',
            icon: const Icon(Icons.keyboard, color: Colors.white),
            onPressed: _showManualInputDialog,
          ),
        ],
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Camera scanner
          MobileScanner(
            controller: _controller,
            onDetect: _onBarcodeDetected,
            errorBuilder: (context, error) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.videocam_off, size: 48, color: Colors.white70),
                      const SizedBox(height: 12),
                      const Text(
                        'Kamera Tidak Tersedia',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Kamera tidak terdeteksi pada emulator/perangkat. Anda dapat menggunakan tombol Input Manual di kanan atas.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _showManualInputDialog,
                        icon: const Icon(Icons.keyboard),
                        label: const Text('Masukkan SKU Manual'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Viewfinder Overlay Frame
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _getFrameColor(),
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _getModeBadgeText(),
                        style: TextStyle(
                          color: _getFrameColor(),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Processing Indicator
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Memeriksa kode barang...',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),

          // Bottom Mode Selector Bar
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                children: [
                  _buildModeTab('Cari Detail', ScannerMode.search, Icons.search),
                  _buildModeTab('Barang Masuk', ScannerMode.inbound, Icons.transit_enterexit),
                  _buildModeTab('Barang Keluar', ScannerMode.outbound, Icons.call_made),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeTab(String label, ScannerMode mode, IconData icon) {
    final isSelected = _currentMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentMode = mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : Colors.white60,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : Colors.white60,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTitle() {
    switch (_currentMode) {
      case ScannerMode.inbound:
        return 'Scan Barang Masuk';
      case ScannerMode.outbound:
        return 'Scan Barang Keluar';
      case ScannerMode.search:
        return 'Pindai QR Barang';
    }
  }

  Color _getFrameColor() {
    switch (_currentMode) {
      case ScannerMode.inbound:
        return AppColors.inbound;
      case ScannerMode.outbound:
        return AppColors.outbound;
      case ScannerMode.search:
        return AppColors.primaryLight;
    }
  }

  String _getModeBadgeText() {
    switch (_currentMode) {
      case ScannerMode.inbound:
        return 'MODE INBOUND (+)';
      case ScannerMode.outbound:
        return 'MODE OUTBOUND (-)';
      case ScannerMode.search:
        return 'MODE CARI';
    }
  }
}
