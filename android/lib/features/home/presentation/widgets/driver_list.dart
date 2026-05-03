import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/driver_entity.dart';

class DriverList extends StatelessWidget {
  final List<DriverEntity> drivers;
  const DriverList({super.key, required this.drivers});

  @override
  Widget build(BuildContext context) {
    if (drivers.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.directions_bike_outlined,
                size:  64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Tidak ada pengemudi tersedia\ndi area Anda saat ini',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _DriverCard(driver: drivers[index]),
          childCount: drivers.length,
        ),
      ),
    );
  }
}

class _DriverCard extends StatelessWidget {
  final DriverEntity driver;
  const _DriverCard({required this.driver});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin:  const EdgeInsets.only(bottom: 12),
      child:   InkWell(
        onTap:        () => context.push(
          '/home/order',
          extra: driver,
        ),
        borderRadius: BorderRadius.circular(16),
        child:        Padding(
          padding: const EdgeInsets.all(16),
          child:   Row(
            children: [
              // avatar
              CircleAvatar(
                radius:          24,
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .primaryContainer,
                child: Text(
                  driver.address.substring(2, 4).toUpperCase(),
                  style: TextStyle(
                    color:      Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${driver.address.substring(0, 6)}...${driver.address.substring(driver.address.length - 4)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize:   14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          driver.reputationDisplay,
                          style: const TextStyle(fontSize: 13),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.directions_walk,
                          size:  14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${(driver.distanceMeters / 1000).toStringAsFixed(1)} km',
                          style: const TextStyle(
                            fontSize: 13,
                            color:    Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // fare
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${driver.farePerKm} wei',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color:      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const Text(
                    'per km',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),

              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
