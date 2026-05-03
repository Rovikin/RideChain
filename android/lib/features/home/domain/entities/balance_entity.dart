import 'package:equatable/equatable.dart';

class BalanceEntity extends Equatable {
  final BigInt  weiBalance;
  final double  maticBalance;
  final double? idrEquivalent;

  const BalanceEntity({
    required this.weiBalance,
    required this.maticBalance,
    this.idrEquivalent,
  });

  String get maticDisplay =>
      '${maticBalance.toStringAsFixed(4)} MATIC';

  String get idrDisplay {
    if (idrEquivalent == null) return '-';
    final formatted = idrEquivalent!.toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
    return 'Rp $formatted';
  }

  @override
  List<Object?> get props => [weiBalance, maticBalance, idrEquivalent];
}
