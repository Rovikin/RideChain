class AppConstants {

  AppConstants._();

  // blockchain
  static const polygonChainId    = 137;
  static const polygonRpcUrl     = 'https://polygon-rpc.com'\;
  static const polygonExplorer   = 'https://polygonscan.com'\;

  // contracts — filled after deployment
  static const registryContract    = '';
  static const orderBookContract   = '';
  static const rideSessionContract = '';
  static const disputeContract     = '';
  static const thresholdKYCContract = '';

  // trip
  static const driverSearchRadiusMeters  = 5000.0;
  static const gpsCheckpointIntervalSecs = 30;
  static const confirmationTimeoutSecs   = 600;   // 10 minutes
  static const acceptTimeoutSecs         = 300;   // 5 minutes

  // routing fee
  static const routingFeeBps = 50; // 0.5%

  // deposit multiplier
  static const depositMultiplier = 2;

  // reputation
  static const minReputationScore = 350; // 3.50 / 5.00

  // display
  static const maticDecimals = 18;
}
