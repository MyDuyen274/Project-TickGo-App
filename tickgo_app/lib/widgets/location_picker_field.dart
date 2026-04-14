import 'package:flutter/material.dart';

class LocationPickerField extends StatelessWidget {
  final String? locationName;
  final String? locationAddress;
  final VoidCallback onTap;

  const LocationPickerField({
    super.key,
    this.locationName,
    this.locationAddress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.location_on_outlined, color: Colors.grey[600]),
            const SizedBox(width: 12),
            Expanded(
              child: locationName == null
                  ? Text("Chọn địa điểm tổ chức (*)", style: TextStyle(color: Colors.grey[600], fontSize: 16))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          locationName!,
                          style: const TextStyle(
                            color: Color(0xFF00B14F), // Xanh lá Ticketbox
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          locationAddress ?? '',
                          style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        ),
                      ],
                    ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}