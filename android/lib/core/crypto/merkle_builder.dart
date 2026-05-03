import 'dart:convert';
import 'dart:typed_data';
import 'package:pointycastle/pointycastle.dart';
import 'package:hex/hex.dart';

/// Builds a Merkle tree from GPS checkpoints off-chain.
/// Only the root is submitted on-chain at trip completion.
/// Compatible with OpenZeppelin MerkleProof.verify on-chain.
class MerkleBuilder {
  final List<Uint8List> _leaves = [];

  // -------------------------
  // Adding checkpoints
  // -------------------------

  /// Add a GPS checkpoint to the tree.
  /// lat and lng are stored as × 1e6 integers to match Solidity.
  void addCheckpoint({
    required double lat,
    required double lng,
    required int    timestamp,
    required int    sequence,
  }) {
    final latInt = (lat * 1e6).round();
    final lngInt = (lng * 1e6).round();

    final leaf = _buildLeaf(latInt, lngInt, timestamp, sequence);
    _leaves.add(leaf);
  }

  int get checkpointCount => _leaves.length;

  // -------------------------
  // Root computation
  // -------------------------

  /// Compute Merkle root from all added checkpoints.
  /// Returns root as hex string for on-chain submission.
  String computeRoot() {
    if (_leaves.isEmpty) throw MerkleException('No checkpoints added');
    if (_leaves.length == 1) return HEX.encode(_leaves[0]);

    List<Uint8List> layer = List.from(_leaves);

    while (layer.length > 1) {
      final nextLayer = <Uint8List>[];

      for (int i = 0; i < layer.length; i += 2) {
        if (i + 1 < layer.length) {
          nextLayer.add(_hashPair(layer[i], layer[i + 1]));
        } else {
          // odd node — carry up unchanged
          nextLayer.add(layer[i]);
        }
      }

      layer = nextLayer;
    }

    return HEX.encode(layer[0]);
  }

  /// Get root as bytes32-compatible Uint8List.
  Uint8List computeRootBytes() {
    return Uint8List.fromList(HEX.decode(computeRoot()));
  }

  // -------------------------
  // Proof generation
  // -------------------------

  /// Generate Merkle proof for a specific checkpoint index.
  /// Proof can be submitted to on-chain verifyGpsProof.
  List<String> generateProof(int leafIndex) {
    if (leafIndex >= _leaves.length) {
      throw MerkleException('Leaf index out of bounds');
    }

    final proof = <String>[];
    List<Uint8List> layer = List.from(_leaves);
    int index = leafIndex;

    while (layer.length > 1) {
      final nextLayer = <Uint8List>[];

      for (int i = 0; i < layer.length; i += 2) {
        if (i + 1 < layer.length) {
          // record sibling as proof element
          if (i == index || i + 1 == index) {
            final sibling = (i == index) ? layer[i + 1] : layer[i];
            proof.add(HEX.encode(sibling));
          }
          nextLayer.add(_hashPair(layer[i], layer[i + 1]));
        } else {
          nextLayer.add(layer[i]);
        }
      }

      index = index ~/ 2;
      layer = nextLayer;
    }

    return proof;
  }

  // -------------------------
  // Internal helpers
  // -------------------------

  /// Build leaf: keccak256(abi.encodePacked(lat, lng, timestamp, sequence))
  /// Must match MerkleVerifier.buildLeafWithSequence in Solidity.
  Uint8List _buildLeaf(int lat, int lng, int timestamp, int sequence) {
    final buffer = BytesBuilder();

    // encode as int256 (32 bytes each) to match Solidity abi.encodePacked
    buffer.add(_encodeInt256(lat));
    buffer.add(_encodeInt256(lng));
    buffer.add(_encodeUint256(timestamp));
    buffer.add(_encodeUint256(sequence));

    return _keccak256(buffer.toBytes());
  }

  Uint8List _hashPair(Uint8List a, Uint8List b) {
    // sort to match OpenZeppelin's sorted pair hashing
    final comparison = _compareBytes(a, b);
    final buffer     = BytesBuilder();

    if (comparison <= 0) {
      buffer.add(a);
      buffer.add(b);
    } else {
      buffer.add(b);
      buffer.add(a);
    }

    return _keccak256(buffer.toBytes());
  }

  Uint8List _keccak256(Uint8List data) {
    final digest = Digest('Keccak/256');
    return digest.process(data);
  }

  Uint8List _encodeInt256(int value) {
    final bytes = Uint8List(32);
    if (value >= 0) {
      _writeUint(bytes, BigInt.from(value));
    } else {
      // two's complement for negative numbers
      final twosComplement = (BigInt.one << 256) + BigInt.from(value);
      _writeUint(bytes, twosComplement);
    }
    return bytes;
  }

  Uint8List _encodeUint256(int value) {
    final bytes = Uint8List(32);
    _writeUint(bytes, BigInt.from(value));
    return bytes;
  }

  void _writeUint(Uint8List bytes, BigInt value) {
    var v = value;
    for (int i = 31; i >= 0; i--) {
      bytes[i] = (v & BigInt.from(0xff)).toInt();
      v = v >> 8;
    }
  }

  int _compareBytes(Uint8List a, Uint8List b) {
    for (int i = 0; i < a.length && i < b.length; i++) {
      if (a[i] != b[i]) return a[i] - b[i];
    }
    return a.length - b.length;
  }
}

class MerkleException implements Exception {
  final String message;
  const MerkleException(this.message);

  @override
  String toString() => 'MerkleException: $message';
}
