# Sunny Sip Bar — 3D

Godot 4.7.2 ile hazırlanmış, Android odaklı gerçek 3D sahil kafesi işletme oyunu.

## 3D sahne
- Ortografik perspektifli gerçek 3D sahne; yönlü ışık, gölgeler, malzeme parlaklığı ve derinlik.
- Hacimli karakterler: gövde, yüz, saç, göz, kollar ve bacaklar ayrı 3D mesh parçalarıdır.
- Dört ayrı masa, sandalyeler, ahşap zemin, bar tezgâhı, kahve makinesi, renkli tente, palmiye ağaçları, sahil ve deniz.
- Müşteriler sahne kenarından yürüyerek gelir, masaya yanaşır, oturur, bekler; kızınca yüzleri değişir ve masaya iki eliyle vurur.
- Servis edilen içeceği ellerine alıp içer, sonra ayağa kalkıp yürüyerek sahneden çıkar. Boşalan masaya yeni müşteri gelir.
- Beş farklı hacimli bardak biçimi, içecek rengi, pipet ve meyve süslemesi.

## İşletme
- 12 içecek, her biri için özgün fiyat, renk ve 3–6 adımlı sıralı reçete.
- 20 malzeme; başlangıç stoğu her üründen 40 adet.
- Başlangıç sermayesi $4.000; malzeme kullanıldıkça stok azalır, raftan 10 adetlik paket satın alınır.
- İşletme puanı 5.00 yıldızla başlar; memnuniyetle küsuratlı artar veya düşer. Puan 2.00 altına inince işletme kapanır.
- Doğru sırada hazırlama kaliteyi belirler; %60 altındaki içecek reddedilir ve ödeme alınamaz.

## Android kimliği ve yayın
- Android application ID: com.dincer552.testpak2
- Merkezi imza anahtarı: testpak2 (değiştirilmez)
- My App Store dosyası: testpak2.apk
- Godot Android export unsigned APK üretir; GitHub Actions mevcut merkezi imzalayıcı ile imzalar ve aynı paket kimliğinde sürüm yayımlar.

## Derleme
Godot 4.7.2 stable editor ve eşleşen Android export templates gerekir. Komut satırından Android preset adı Android ile dışa aktarılır.
