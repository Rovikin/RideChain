# RideChain: Protokol Ride-Hailing Peer-to-Peer Terdesentralisasi

**Versi 0.1 — Concept Paper**
**Penulis: Inisiatif RideChain**

---

- [🇬🇧 English](README.md)

## Abstrak

RideChain adalah protokol ride-hailing peer-to-peer terdesentralisasi yang dibangun di atas blockchain Polygon PoS. Protokol ini menjawab ketimpangan struktural antara operator platform ride-hailing dan mitra pengemudi — sebuah masalah yang lahir dari keberadaan pihak ketiga terpusat yang secara sepihak menetapkan tarif, memberlakukan kebijakan tidak transparan, dan mengekstrak nilai berlebihan dari kedua sisi pasar tanpa akuntabilitas yang memadai.

RideChain menghilangkan perantara sepenuhnya. Pengemudi beroperasi sebagai merchant independen — menetapkan tarif sendiri dan membangun reputasi yang menjadi milik mereka, bukan milik platform manapun. Penumpang memilih dari daftar pengemudi yang tersedia secara transparan, diurutkan berdasarkan tarif, kedekatan jarak, dan reputasi on-chain. Pembayaran disimpan dalam escrow smart contract dan dilepaskan otomatis setelah perjalanan selesai. Sengketa diselesaikan oleh komunitas arbitrer dengan akuntabilitas kriptografis. Identitas dilindungi oleh enkripsi threshold, hanya dapat diakses melalui konsensus komunitas.

Protokol ini dirancang untuk tahan sensor, transparan, dan tidak dimiliki oleh satu entitas manapun. Dikembangkan untuk pasar Indonesia — di mana ride-hailing adalah infrastruktur perkotaan yang esensial dan eksploitasi pengemudi adalah masalah nyata yang terdokumentasi — namun arsitekturnya berlaku di mana saja kondisi serupa ada.

---

## 1. Pendahuluan

### 1.1 Masalah

Platform ride-hailing di Indonesia telah tumbuh menjadi infrastruktur perkotaan yang kritis. Jutaan pengemudi menggantungkan pendapatan utama mereka pada platform ini. Namun hubungan antara platform dan pengemudi secara struktural bersifat eksploitatif:

- **Pembuatan aturan sepihak.** Operator platform mengubah struktur komisi, insentif, dan kebijakan suspensi tanpa masukan atau persetujuan pengemudi.
- **Komisi yang ekstraktif.** Biaya platform secara rutin mencapai 20–25% dari nilai tarif — angka yang lebih besar dari sebagian besar pajak negara — tanpa peningkatan layanan yang sepadan bagi pengemudi.
- **Reputasi milik platform.** Rating, riwayat perjalanan, dan kepercayaan yang dibangun pengemudi adalah aset milik platform. Pengemudi yang disuspensi atau dideplatform kehilangan segalanya yang telah dibangun selama bertahun-tahun.
- **Kegagalan regulasi.** Regulator di Indonesia secara historis lebih mengutamakan pendapatan pajak dari operator platform daripada kesejahteraan mitra pengemudi yang juga merupakan warga negara.

Ini bukan keluhan operasional. Ini adalah kegagalan struktural yang muncul secara tidak terelakkan ketika satu perantara terpusat mengendalikan sekaligus aturan dan infrastruktur pasar.

### 1.2 Peluang

Infrastruktur keuangan terdesentralisasi — smart contract, escrow on-chain, identitas kriptografis, dan jaringan peer-to-peer — telah ada dan matang selama lebih dari satu dekade. Alat yang dibutuhkan untuk membangun sistem ride-hailing tanpa operator terpusat sudah tersedia. RideChain menerapkannya pada masalah spesifik yang belum terpecahkan ini.

### 1.3 Filosofi Desain

RideChain dibangun di atas tiga prinsip:

**Kedaulatan.** Pengemudi memiliki reputasi, penetapan harga, dan hubungan mereka dengan penumpang. Tidak ada entitas yang dapat mendeplatform pengemudi, mengubah riwayat mereka, atau menyita penghasilan mereka.

**Transparansi.** Setiap aturan yang dikodekan dalam protokol dapat dilihat, diaudit, dan bersifat konsisten. Tidak ada algoritma yang beroperasi secara rahasia. Tidak ada biaya tersembunyi.

**Akuntabilitas proporsional.** Setiap peserta — pengemudi, penumpang, arbitrer — memiliki pertaruhan ekonomi. Biaya ketidakjujuran selalu melebihi potensi keuntungannya.

---

## 2. Gambaran Sistem

RideChain terdiri dari lima lapisan yang saling terhubung:

```
┌─────────────────────────────────────────────────────┐
│                   Lapisan Aplikasi                   │
│         Android APK  ·  Pesan P2P (XMTP)            │
└──────────────────────┬──────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────┐
│                  Lapisan Discovery                   │
│      libp2p  ·  DHT  ·  Super Node  ·  GPS         │
└──────────────────────┬──────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────┐
│                  Lapisan Routing                     │
│         OSRM  ·  OpenStreetMap  ·  Node ENS        │
└──────────────────────┬──────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────┐
│              Lapisan Smart Contract                  │
│   Registry · OrderBook · RideSession · Dispute      │
│              ThresholdKYC · Governance               │
└──────────────────────┬──────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────┐
│                 Lapisan Blockchain                   │
│              Polygon PoS  ·  MATIC                  │
└─────────────────────────────────────────────────────┘
```

---

## 3. Komponen Inti

### 3.1 Pengemudi sebagai Merchant P2P

Fondasi konseptual RideChain adalah perubahan framing pengemudi dari kontraktor yang bergantung pada platform menjadi merchant independen.

Dalam pasar P2P konvensional — seperti bursa kripto peer-to-peer — merchant menetapkan harga sendiri, membangun reputasi sendiri, dan bersaing untuk mendapatkan pelanggan berdasarkan kualitas layanan. Tidak ada operator terpusat yang mendiktekan syarat mereka. Platform hanya menyediakan infrastruktur escrow dan mekanisme penemuan.

RideChain menerapkan model ini pada transportasi:

- Pengemudi menetapkan tarif per kilometer mereka sendiri
- Pengemudi membangun reputasi yang tersimpan on-chain dan dimiliki oleh alamat wallet mereka
- Penumpang menelusuri pengemudi yang tersedia dan memilih berdasarkan tarif, kedekatan, dan reputasi
- Protokol menyediakan escrow, penyelesaian sengketa, dan infrastruktur identitas — tidak lebih

Framing ini menyelesaikan asimetri kekuasaan yang mendasar. Pengemudi tidak dapat dideplatform karena tidak ada platform untuk dideplatform. Reputasi mereka tidak dapat disita karena tersimpan di blockchain publik, bukan di database korporasi.

### 3.2 Matching Engine

#### 3.2.1 Discovery Pengemudi via DHT dan libp2p

Discovery pengemudi di RideChain menggunakan arsitektur hybrid yang dirancang untuk realita jaringan mobile di Indonesia, di mana sebagian besar pengguna beroperasi di belakang CGNAT dan koneksi bersifat tidak stabil.

**Super Node** membentuk tulang punggung lapisan discovery. Ini adalah node yang sama yang menyediakan infrastruktur routing (lihat Bagian 3.3), difungsikan ganda sebagai titik relay dan rendezvous. Mereka memiliki alamat IP publik yang stabil, mendapat insentif untuk tetap online, dan berfungsi sebagai titik anchor untuk konektivitas P2P.

**libp2p** menangani transport antar semua node. Menyediakan NAT traversal bawaan, CGNAT hole-punching, dan circuit relay — artinya dua perangkat mobile yang tidak bisa terhubung langsung dapat berkomunikasi melalui relay super node tanpa server terpusat apapun.

**Kehadiran pengemudi** dijaga melalui pengumuman berkala ke super node terdekat setiap 30 detik selama aplikasi aktif di foreground. Pola foreground service Android — yang sudah familiar bagi pengemudi ojol Indonesia dari platform yang sudah ada — menjaga proses tetap hidup dan mencegah optimisasi baterai OS mematikannya.

#### 3.2.2 Logika Pencocokan Order

Ketika penumpang memasukkan titik penjemputan dan tujuan:

1. Aplikasi mengquery super node terdekat untuk pengemudi yang tersedia dalam radius yang dapat dikonfigurasi
2. Setiap entri pengemudi mencakup: tarif per km, jarak saat ini dari titik penjemputan, skor reputasi, estimasi waktu tiba
3. Penumpang memilih satu pengemudi dari daftar
4. Smart contract mengunci escrow dan sesi dimulai

Pengurutan dapat dikonfigurasi oleh penumpang: terdekat dulu, termurah dulu, reputasi tertinggi dulu, atau skor komposit. Algoritma pengurutan bersifat open source dan identik untuk semua pengguna — tidak ada prioritas tersembunyi.

**Penemuan harga secara alami** muncul dari model ini tanpa algoritma surge pricing apapun. Saat jam sibuk, pengemudi dengan tarif lebih tinggi tetap dipilih jika pasokan langka. Saat jam sepi, tekanan kompetitif mendorong tarif turun. Pasar menetapkan harga secara transparan.

### 3.3 Infrastruktur Routing

#### 3.3.1 OpenStreetMap sebagai Fondasi Data

RideChain menggunakan OpenStreetMap (OSM) sebagai sumber data peta. Data OSM dikontribusikan oleh komunitas global, dilisensikan di bawah Open Database License, dan tidak dapat dicabut atau dibatasi oleh entitas manapun. Di kota-kota besar Indonesia, cakupan dan akurasi OSM sudah memadai untuk keperluan routing.

#### 3.3.2 Node OSRM dengan Registrasi ENS

Komputasi routing dilakukan oleh node OSRM (Open Source Routing Machine) yang dioperasikan oleh anggota komunitas. Setiap node mendaftarkan subdomain di bawah namespace ENS proyek (misalnya `node1.ridechain.eth`), yang meresolve ke alamat server mereka.

ENS beroperasi di Ethereum mainnet dan menyediakan resolusi domain yang tahan sensor — tidak ada registrar yang dapat mensuspensi atau menyita domain ENS di bawah tekanan eksternal.

Operator node melakukan sinkronisasi data OSM mingguan dari file planet OpenStreetMap. Karena semua node menggunakan sumber data yang sama, hasil routing secara alami konsisten tanpa memerlukan koordinasi antar node.

#### 3.3.3 Insentif Node

Node routing mendapat kompensasi dari biaya kecil yang dibagi rata antara pengemudi dan penumpang pada setiap perjalanan yang selesai:

```
Biaya routing per transaksi: 0,5% dari tarif
  Pembagian: 0,25% dari penumpang + 0,25% dari pengemudi

Model biaya: per query dengan batas per transaksi
  Setiap routing query: ~Rp10
  Batas per transaksi: Rp100 total

Break-even: ~50 transaksi/hari
  (cukup untuk biaya VPS Rp100.000–150.000/bulan)
```

Biaya routing dibayarkan saat order dibuat, bukan saat perjalanan selesai — node telah memberikan layanannya terlepas dari hasil perjalanan.

Node dengan hasil outlier (tidak konsisten dengan mayoritas node yang diquery) tidak mendapat kompensasi. Perilaku outlier yang persisten memicu penghapusan dari registry.

### 3.4 Order Book dan Mekanisme Penetapan Harga

Pengemudi mempublikasikan ketersediaan mereka sebagai ask persisten dalam order book:

```
Ask Pengemudi:
  wallet_address: 0x...
  tarif_per_km: X MATIC (ditampilkan sebagai ekuivalen IDR)
  nilai_order_maksimal: ditentukan oleh deposit
  lokasi: diperbarui setiap 30 detik via super node
  skor_reputasi: diambil dari Registry Contract
  status: tersedia | sibuk | offline
```

Penumpang tidak melakukan bid. Mereka menelusuri dan memilih. Ini adalah marketplace satu sisi, bukan lelang dua sisi.

Kalkulasi tarif saat order dibuat:

```
estimasi_jarak = query OSRM (hasil mayoritas dari 3–5 node)
estimasi_tarif = tarif_per_km_pengemudi × estimasi_jarak
jumlah_escrow  = estimasi_tarif + biaya_routing + buffer_gas
```

Estimasi tarif dikunci saat order dibuat. Jika jarak aktual menyimpang secara signifikan dari estimasi (threshold yang dapat dikonfigurasi), selisihnya diselesaikan saat perjalanan selesai menggunakan rute aktual yang diverifikasi GPS.

### 3.5 Escrow dan Alur Pembayaran

```
ORDER DIBUAT
  Penumpang deposit escrow ke RideSession Contract
  Escrow = estimasi_tarif + biaya_routing + buffer_gas
  Biaya routing langsung didistribusikan ke node routing
  
PERJALANAN BERLANGSUNG
  Checkpoint GPS diakumulasi secara lokal sebagai Merkle tree
  Hanya Merkle root yang di-submit on-chain secara berkala
  
PERJALANAN SELESAI
  Pengemudi submit klaim penyelesaian
  Jendela konfirmasi 10 menit terbuka
  
DIKONFIRMASI (penumpang konfirmasi ATAU timeout berakhir)
  Tarif dilepaskan ke pengemudi
  Sisa buffer gas dikembalikan ke penumpang
  
DISENGKETAKAN
  Escrow dibekukan
  Dispute Contract diaktifkan
  Merkle proof tersedia sebagai bukti forensik
```

### 3.6 Mekanisme Deposit dan Slash

Semua peserta harus mempertahankan deposit jaminan yang melebihi nilai transaksi yang mereka ikuti. Ini memastikan bahwa biaya ekonomi ketidakjujuran selalu melebihi potensi keuntungannya.

#### 3.6.1 Persyaratan Deposit

```
Deposit pengemudi:  2× nilai order maksimal yang ingin diterima
Deposit penumpang:  2× nilai perjalanan saat ini (per perjalanan)
Deposit arbitrer:   2× biaya arbitrase yang akan diterima
```

Faktor pengali 2× (bukan 1,5×) menyediakan buffer terhadap volatilitas harga MATIC. Penurunan harga 25% mengurangi jaminan efektif menjadi 1,5× — masih cukup untuk integritas sistem.

#### 3.6.2 Pemantauan Deposit Dinamis

Oracle harga Chainlink memantau nilai MATIC/IDR secara berkelanjutan:

```
Nilai deposit > 1,5× nilai order  →  eligible beroperasi
Nilai deposit 1,2×–1,5×           →  notifikasi peringatan
Nilai deposit < 1,2×               →  operasi ditangguhkan
                                       sampai top-up
```

Pengguna melihat semua nilai dalam ekuivalen IDR. Denominasi MATIC diabstraksi.

#### 3.6.3 Aturan Slash

```
Fraud pengemudi terkonfirmasi  →  slash deposit pengemudi sebesar nilai tarif
                                   → ke penumpang + biaya arbitrer
Fraud penumpang terkonfirmasi  →  slash deposit penumpang sebesar nilai tarif
                                   → ke pengemudi + biaya arbitrer
Arbitrer tidak responsif       →  slash deposit arbitrer (kecil)
                                   → dibagi antara pengemudi dan penumpang
                                   → kasus dialihkan ke arbitrer baru
```

### 3.7 Penyelesaian Sengketa

#### 3.7.1 Default Optimistik

Sistem mengasumsikan perilaku jujur secara default. Setelah pengemudi submit klaim penyelesaian, dana dilepaskan otomatis setelah timeout jika penumpang tidak mengajukan sengketa. Ini meminimalkan aktivitas on-chain yang tidak perlu untuk mayoritas perjalanan yang selesai tanpa masalah.

#### 3.7.2 Alur Sengketa

```
1. Penumpang sengketakan dalam jendela konfirmasi
   → Penumpang deposit biaya arbitrer di muka
   → Escrow dibekukan di RideSession Contract

2. Dispute Contract memilih arbitrer secara acak dari pool aktif
   → Arbitrer dinotifikasi dengan detail kasus dan batas waktu

3. Ruang chat tiga pihak dibuka via protokol XMTP
   → Pengemudi, penumpang, dan arbitrer berpartisipasi
   → Merkle proof GPS tersedia untuk review arbitrer
   → Log konfirmasi proximity tersedia

4. Arbitrer memberikan keputusan: pengemudi benar ATAU penumpang benar
   → Tidak ada keputusan split. Satu pihak dinyatakan bersalah.
   → Contract mengeksekusi segera setelah keputusan disubmit

5. Deposit pihak yang kalah di-slash
   → Pihak yang menang mendapat kompensasi
   → Arbitrer menerima biaya dari deposit yang di-slash
   → Pihak yang menang memberikan rating arbitrer (1–5 bintang)
```

#### 3.7.3 Aturan Pembatalan

```
Penumpang batal saat CREATED               →  refund penuh
Penumpang batal saat ACCEPTED (pra-gerak)  →  refund penuh
Penumpang batal saat PICKING_UP            →  penalti 20% ke pengemudi
Penumpang batal saat IN_PROGRESS           →  proporsional per jarak GPS
Pengemudi batal saat ACCEPTED/PICKING_UP   →  refund penuh ke penumpang
                                               + slash kecil dari deposit pengemudi
```

### 3.8 Sistem Arbitrer dan Reputasi

Setiap pengemudi atau penumpang aktif dengan riwayat on-chain yang cukup dapat mendaftar sebagai arbitrer dengan mendepositkan jaminan.

#### 3.8.1 Reputasi Arbitrer

Semua aktivitas arbitrer dicatat on-chain:

```solidity
struct Arbitrer {
  uint256 totalKasus;
  uint256 totalRating;
  uint256 jumlahSlash;
  bool aktif;
}
```

Rating diberikan oleh **pihak yang menang saja** setelah resolusi. Pihak yang kalah tidak memiliki hak rating — insentif mereka untuk memberikan rating negatif terlepas dari kualitas arbitrer akan merusak sinyal reputasi.

#### 3.8.2 Diskualifikasi Otomatis

```
Rata-rata rating < 3,5 / 5,0  →  otomatis dinonaktifkan
Jumlah slash ≥ 3               →  banned permanen
                                   sebagian deposit hangus
```

#### 3.8.3 Pemilihan Arbitrer

Arbitrer dipilih secara acak dari pool aktif untuk setiap sengketa. Pemilihan acak mencegah manipulasi penugasan kasus. Jika arbitrer yang dipilih gagal merespons dalam batas waktu, mereka dikenakan penalti dan arbitrer baru dipilih otomatis.

### 3.9 Threshold KYC dan Keamanan Komunitas

#### 3.9.1 Filosofi

RideChain tidak melibatkan penegak hukum negara secara by design. Data identitas dilindungi oleh komunitas itu sendiri, hanya dapat diakses melalui konsensus kolektif dalam kondisi yang terdefinisi.

#### 3.9.2 Shamir's Secret Sharing

Dokumen identitas pengemudi dan penumpang (KTP, SIM, registrasi kendaraan) dienkripsi saat pendaftaran menggunakan skema enkripsi threshold berdasarkan Shamir's Secret Sharing.

Kunci enkripsi dipecah menjadi N shard yang didistribusikan ke N arbitrer aktif. Minimal M shard harus dikombinasikan untuk merekonstruksi kunci dan mengakses data identitas.

```
Deployment awal (komunitas kecil):  3-of-5
Fase pertumbuhan:                   5-of-9
Deployment matang:                  7-of-13
```

Upgrade skema diatur secara on-chain. Shard kunci di-re-enkripsi dan didistribusikan ulang selama setiap upgrade melalui proactive secret sharing — secret yang mendasarinya tidak berubah, tetapi pemegang shard dirotasi.

#### 3.9.3 Kondisi Akses Identitas

Threshold KYC Contract hanya akan mengizinkan rekonstruksi identitas dalam kondisi yang terdefinisi secara ketat:

```
Diizinkan:
  - Panic button diaktifkan oleh peserta
  - Vote governance komunitas mencapai threshold
  - Nilai escrow yang dibekukan melebihi threshold yang ditetapkan
    (indikator insiden serius)

Dilarang:
  - Semua permintaan lainnya, termasuk dari developer protokol
```

Setiap upaya akses dicatat permanen on-chain. Akses diam-diam secara arsitektural tidak mungkin.

#### 3.9.4 Penyimpanan Data Terenkripsi

Dokumen identitas disimpan di IPFS/Arweave setelah enkripsi. Hanya content hash yang disimpan on-chain. Dokumen tidak dapat diakses tanpa kunci yang direkonstruksi terlepas dari siapa yang memegang hash IPFS.

#### 3.9.5 Tombol Darurat (Panic Button)

Tombol SOS tersembunyi tersedia bagi pengemudi dan penumpang sepanjang setiap perjalanan:

```
Aktivasi:
  → Lokasi GPS real-time dikirimkan ke kontak darurat yang terdaftar
  → Hash lokasi dicommit ke blockchain (tidak dapat dibatalkan)
  → Arbitrer aktif di jaringan dinotifikasi sebagai saksi digital
  → Tidak dapat dibatalkan setelah aktivasi
```

Sifat tidak dapat dibatalkan dari aktivasi panic button adalah pilihan desain yang disengaja. Pemaksaan untuk membatalkan alert yang sudah diaktifkan tidak mungkin dilakukan di level protokol.

---

## 4. Arsitektur Smart Contract

RideChain menggunakan arsitektur contract modular. Setiap contract memiliki tanggung jawab tunggal dan dapat di-upgrade secara independen tanpa mempengaruhi yang lain.

### 4.1 Registry Contract

Menyimpan semua catatan peserta: pengemudi, penumpang, arbitrer.

```solidity
// Struktur data inti (disederhanakan)

struct Pengemudi {
  address wallet;
  uint256 jumlahDeposit;
  uint256 nilaiOrderMaksimal;
  uint256 tarifPerKm;
  uint256 skorReputasi;
  uint256 totalPerjalanan;
  bool aktif;
  bytes32 kycHash;        // hash IPFS dari identitas terenkripsi
}

struct Penumpang {
  address wallet;
  uint256 skorReputasi;
  uint256 totalPerjalanan;
  bool aktif;
  bytes32 kycHash;
}

struct Arbitrer {
  address wallet;
  uint256 jumlahDeposit;
  uint256 totalKasus;
  uint256 totalRating;
  uint256 jumlahSlash;
  bool aktif;
}
```

### 4.2 OrderBook Contract

Mengelola pengumuman ketersediaan pengemudi dan pembuatan order.

```
Tanggung jawab:
  - Menerima dan menyimpan entri ask pengemudi
  - Menerima permintaan order penumpang dengan escrow
  - Mencocokkan penumpang dengan pengemudi yang dipilih
  - Membuat RideSession saat match terjadi
  - Mendistribusikan biaya routing saat order dibuat
```

### 4.3 RideSession Contract

State machine inti untuk setiap perjalanan.

```
State:
  CREATED → ACCEPTED → PICKING_UP → IN_PROGRESS
  → COMPLETED → CONFIRMED
  → DISPUTED → RESOLVED
  → CANCELLED
  → EXPIRED

Transisi state bersifat permissioned:
  CREATED → ACCEPTED:       pengemudi saja
  ACCEPTED → PICKING_UP:    pengemudi saja
  PICKING_UP → IN_PROGRESS: pengemudi saja (proximity penumpang terkonfirmasi)
  IN_PROGRESS → COMPLETED:  pengemudi saja
  COMPLETED → CONFIRMED:    penumpang atau timeout
  ANY → DISPUTED:           penumpang saja (dalam jendela waktu)
  DISPUTED → RESOLVED:      Dispute Contract saja
  ANY → CANCELLED:          berbasis aturan (lihat Bagian 3.7.3)
  ANY → EXPIRED:            berbasis timeout (otomatis)
```

Semua transisi state memancarkan event on-chain. Merkle root GPS disubmit pada state COMPLETED.

### 4.4 Dispute Contract

```
Tanggung jawab:
  - Menerima trigger sengketa dari RideSession
  - Memilih arbitrer secara acak dari pool Registry
  - Mengelola timeout respons arbitrer dan penggantian
  - Menerima keputusan arbitrer
  - Mengeksekusi slash dan distribusi dana
  - Memperbarui skor reputasi di Registry
  - Mencatat audit trail
```

### 4.5 Threshold KYC Contract

```
Tanggung jawab:
  - Menyimpan hash identitas terenkripsi per wallet
  - Mengelola metadata distribusi shard
  - Memverifikasi kondisi akses sebelum mengizinkan rekonstruksi
  - Mencatat setiap upaya akses on-chain
  - Mengelola rotasi shard selama upgrade skema
```

### 4.6 Edge Cases dan Mekanisme Keamanan

#### Proteksi Reentrancy
Semua fungsi yang mentransfer dana mengikuti pola Checks → Effects → Interactions dan menggunakan ReentrancyGuard dari OpenZeppelin.

#### Nilai Order Minimum
Nilai order minimum di level protokol mencegah griefing melalui dust order yang menghabiskan kapasitas contract tanpa intent yang genuine.

#### Timeout Universal
Setiap state memiliki durasi maksimal yang eksplisit. Tidak ada state yang dapat bertahan selamanya. State yang expired mengembalikan dana ke pemilik yang sah secara otomatis.

#### Keamanan Gas via EIP-1559
Semua transaksi menetapkan `maxFeePerGas` sebesar 5× rata-rata normal. Transaksi antre selama kongesti daripada gagal atau membayar terlalu mahal. Buffer gas disertakan dalam escrow saat order dibuat dan dikembalikan jika tidak terpakai.

#### Transaksi Gasless via ERC-4337
Account abstraction memungkinkan paymaster protokol menanggung biaya gas atas nama pengguna. Pendanaan paymaster berasal dari sebagian biaya routing. Pengguna tidak perlu memegang MATIC untuk gas — hanya untuk tarif dan deposit.

#### Timelock Upgrade Contract
Semua upgrade contract tunduk pada timelock 48 jam. Pengguna memiliki waktu untuk menarik dana sebelum upgrade apapun berlaku. Timelock diberlakukan oleh contract TimelockController terpisah.

---

## 5. Model Ekonomi

### 5.1 Distribusi Biaya Per Perjalanan

```
Dari penumpang:
  Tarif                 →  100% ke pengemudi (via pelepasan escrow)
  Biaya routing (0,25%) →  ke node routing (saat order dibuat)
  Buffer gas            →  gas aktual yang terpakai, sisa dikembalikan

Dari pengemudi:
  Biaya routing (0,25%) →  ke node routing (dipotong dari tarif)
  
Biaya protokol:           0% (fase 1), dapat diaktifkan via governance
```

### 5.2 Ringkasan Struktur Deposit

```
Pengemudi:  2× nilai order maksimal (dikunci di Registry Contract)
Penumpang:  2× tarif perjalanan (dikunci di RideSession Contract per perjalanan)
Arbitrer:   2× biaya arbitrase (dikunci di Dispute Contract per kasus)
```

### 5.3 Mitigasi Volatilitas MATIC

Faktor deposit 2× menyediakan buffer penurunan harga 25% sambil mempertahankan jaminan efektif 1,5×. Oracle harga Chainlink MATIC/USD menyediakan pemantauan berkelanjutan. Operasi ditangguhkan secara otomatis ketika jaminan jatuh di bawah threshold aman, dengan notifikasi pengguna dalam ekuivalen IDR.

### 5.4 Proteksi Biaya Gas

Data GPS disimpan off-chain sebagai Merkle tree. Hanya Merkle root yang disubmit on-chain — satu transaksi terlepas dari panjang perjalanan. Ini mengurangi transaksi on-chain per perjalanan dari potensial puluhan menjadi empat dalam kasus normal.

---

## 6. Governance

### 6.1 Fase 1 — Deployer Key

Deployment awal dikendalikan oleh satu deployer key yang dipegang oleh penulis protokol. Semua tindakan bersifat on-chain dan dapat diaudit secara publik. Fase ini ada untuk memungkinkan iterasi cepat selama pengembangan awal.

### 6.2 Fase 2 — Multisig

Seiring bergabungnya kontributor aktif ke proyek, deployer key diganti oleh wallet Gnosis Safe multisig (di-deploy di Polygon). Perubahan protokol memerlukan tanda tangan M-of-N kontributor. Tidak ada kontributor tunggal yang dapat membuat perubahan sepihak.

### 6.3 Fase 3 — Governance On-chain Penuh

Pada skala komunitas yang cukup, governance beralih ke voting on-chain oleh arbitrer aktif — peserta dengan komitmen yang terbukti terhadap integritas protokol. Proposal disubmit on-chain, tunduk pada periode voting, dan dieksekusi otomatis setelah lolos.

---

## 7. Roadmap

### Fase 1 — Fondasi
- Pengembangan smart contract dan pengujian internal
- Prototipe Android APK (wallet, alur order, tracking GPS)
- Deployment node OSRM di testnet
- Implementasi Threshold KYC di testnet

### Fase 2 — Testnet
- Deployment sistem penuh di Polygon Mumbai/Amoy testnet
- Rekrutmen arbitrer komunitas
- Audit keamanan semua smart contract
- Pilot terbatas dengan pengemudi dan penumpang sukarela

### Fase 3 — Mainnet Launch
- Deployment mainnet di Polygon PoS
- Aktivasi insentif node routing
- Transisi governance ke multisig

### Fase 4 — Desentralisasi
- Aktivasi governance on-chain
- Upgrade skema Threshold KYC ke 7-of-13
- Aktivasi biaya protokol via vote governance
- Ekspansi lintas kota

---

## 8. Kesimpulan

RideChain adalah respons terhadap ketidakadilan struktural yang spesifik dan terdokumentasi: eksploitasi pengemudi ride-hailing oleh operator platform terpusat. Protokol ini menerapkan infrastruktur kriptografis dan blockchain yang sudah matang pada masalah yang belum terpecahkan oleh teknologi.

Protokol ini memberi pengemudi kepemilikan atas reputasi mereka, kendali atas penetapan harga mereka, dan perlindungan dari deplatforming sewenang-wenang. Memberi penumpang pasar yang transparan tanpa biaya tersembunyi dan tanpa manipulasi algoritmik. Memberi komunitas alat untuk menegakkan akuntabilitas tanpa menyerahkan identitas kepada negara.

Tidak ada sistem yang dapat menjamin keadilan sempurna. RideChain tidak mengklaimnya. Yang diklaim hanyalah membuat ketidakjujuran lebih mahal dari kejujuran — secara konsisten, transparan, dan tanpa perlu mempercayai satu pihak manapun.

Itu sudah cukup untuk mengubah struktur masalahnya.

---

## Referensi

- Buterin, V. (2013). *Ethereum Whitepaper*
- Nakamoto, S. (2008). *Bitcoin: A Peer-to-Peer Electronic Cash System*
- Shamir, A. (1979). *How to Share a Secret*. Communications of the ACM
- OpenZeppelin. *Smart Contract Security Guidelines*. https://docs.openzeppelin.com
- Chainlink. *Decentralized Oracle Networks*. https://chain.link
- libp2p. *Modular Networking Stack*. https://libp2p.io
- OSRM. *Open Source Routing Machine*. https://project-osrm.org
- OpenStreetMap Foundation. *OpenStreetMap Data*. https://openstreetmap.org
- Ethereum Name Service. *ENS Documentation*. https://docs.ens.domains
- XMTP. *Decentralized Messaging Protocol*. https://xmtp.org
- ERC-4337. *Account Abstraction Standard*. https://eips.ethereum.org/EIPS/eip-4337
- Kleros. *Decentralized Arbitration*. https://kleros.io
- Polygon. *Polygon PoS Documentation*. https://docs.polygon.technology

---

*RideChain adalah protokol terbuka. Tidak ada hak yang dilindungi.*
*Kontribusi disambut. Kodenya, ketika ditulis, akan bebas.*
