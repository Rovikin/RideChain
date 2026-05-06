import '../entities/balance_entity.dart';
import '../repositories/home_repository.dart';

class GetBalanceUsecase {
  final HomeRepository _repository;
  const GetBalanceUsecase(this._repository);

  Future<BalanceEntity> call(String address) async {
    return _repository.getBalance(address);
  }
}
