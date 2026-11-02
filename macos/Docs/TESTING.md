# Doğrulama kaydı

1 Kasım 2026 tarihinde yapılan kontroller:

- `swift test`: 14 test, 0 hata.
- `bash Scripts/test-local.sh`: 24 test, 0 hata; bunların 10'u SwiftData kalıcılık ve kurtarma testidir.
- `bash Scripts/build-local.sh`: optimize edilmiş yerel macOS uygulaması başarıyla derlendi ve imzalandı.
- `bash Scripts/render-previews.sh`: 15 görünüm üretildi; dashboard, 1060 piksel dar pencere, açık tema, boş günlük, işlem listesi, analizler, takvim, düzenleyici, ayrıntılar, stratejiler, değerlendirmeler ve ayarlar kontrol edildi.
- Kurulu paket `codesign --verify --deep --strict` kontrolünden geçti.
- Kurulu uygulama ayrı geçici veritabanıyla başlatıldı; ana pencere ve yeni yerel veritabanı oluştuğu doğrulandı.
- Gerçek uygulamada ⌘K araması, Enter ile sayfa açma, ⌘N düzenleyicisi, Esc ile iptal, ⌘, ayarları, manuel kurtarma kopyası ve ayrı demo alanından gerçek günlüğe dönüş kontrol edildi.
- Mevcut gerçek günlüğe örnek işlem eklenmedi. Kayıt sayısı korunarak manuel JSON kurtarma kopyası oluşturuldu.
- Dock'taki tek `com.liquidityedge.journal` kısayolu `~/Applications/Liquidity Edge.app` yoluna bağlandı ve tekrar okunarak doğrulandı.

Yerel sürüm mevcut `~/Library/Application Support/LiquidityEdge` klasörünü kullanır. Xcode'un sandbox sürümü ayrı macOS kapsayıcısını kullanır; iki veritabanı otomatik birleştirilmez.

## Grafik arayüzü ve Dock güncellemesi — 2 Kasım 2026

- Sermaye/R/gerileme/hareketli oran eğrileri, kategori çubukları, aylık uyum ve ısı haritasının çizim stilleri yenilendi. Analiz hesaplamaları ve kayıt katmanı değiştirilmedi.
- Analize filtrelenen işlemler için süreç/risk/süre ile R/net KZ karşılaştırmasını sunan scatter plot eklendi. Eksik eksen verileri dışlanır; örneklem sayısı açıklanır; nokta inceleme ve ilişki özeti bulunur.
- Optimize edilmiş yerel derleme başarılı. 21 önizleme üretildi; yeni scatter koyu/açık tema, çizgi grafikleri, kategori grafiği, ısı haritası ve dar dashboard görsel olarak incelendi.
- Kurulu uygulama geçici günlük ile açıldı; tam ana pencere ve yerel veritabanı doğrulandı. Kurulu sürümün imza kontrolü geçti.
- Gerçek kurulu süreçte pencereyi kapatma/yeniden etkinleştirme ve küçültme/yeniden etkinleştirme akışları kontrol edildi; aynı kurulu süreç ve ana pencere geri geldi.
- Dock tercihlerindeki tek günlük kısayolunun ~/Applications/Liquidity Edge.app yoluna bağlı olduğu tekrar doğrulandı. Kurulu yol LaunchServices'e kaydedildi; önceki uygulama arşivi ZIP olarak saklandı.
- Yerel gerçek günlüğün kayıt sayısı korundu; örnek veriler yalnızca demo ve önizleme alanlarında kullanıldı.


## Tam görsel yenileme doğrulaması — 2 Kasım 2026

- Xcode Release universal (arm64/x86_64) derlemesi başarılı.
- Optimize edilmiş yerel paket derlemesi, imza ve kurulu paket açılış kontrolü başarılı.
- 24 otomatik test geçti; 0 hata.
- 26 SwiftUI önizlemesi üretildi ve ekran/form/grafik yerleşimleri incelendi.
- Native alan düzenleme, boş enstrümanda doğrulama, Escape ile iptal, ⌘K/Enter gezinmesi ve demo alanında açık tema kaydetme çalışan uygulamada test edildi.
- Demo dönüşünde gerçek günlüğün teması ve kayıt sayısı korundu.
- Korunan 12 çekirdek dosya aşama öncesi kopyalarla karşılaştırıldı; değişiklik yok.
- Ayrıntılar ve açık doğrulama sınırları: PREMIUM-REDESIGN.md.
