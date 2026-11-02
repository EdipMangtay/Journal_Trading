# Liquidity Edge — native macOS günlüğü

SwiftUI, SwiftData ve Swift Charts ile geliştirilmiş, macOS 14 ve üzeri için yerel işlem günlüğü. Harici servis veya hesap gerektirmez.

## Kullanım

- `⌘N`: yeni işlem. `⌘S`: işlem düzenleyicisinde kaydet. `Esc`: pencereyi kapat / iptal.
- `⌘K`: işlem ara veya sayfa aç. `⌘,`: ayarlar.
- Sermaye grafiğinde imleci hareket ettirerek tarih ve değeri incele; para, R ve yüzde görünümleri arasında geçiş yap.
- İşlem günlüğünde arama, hızlı sonuç sekmeleri, gelişmiş filtreler ve sıralama bulunur.
- Analizlerdeki dağılım grafiğinde süreç puanı, risk veya süreyi R/net sonuçla karşılaştır; bir noktayı imleçle incele. Grafik yalnızca seçili filtreleri ve kayıtlı ölçümleri kullanır.
- Takvimde bir gün seçerek işlemlerini incele. R kaydedilmemişse `—` gösterilir.
- Örnek günlük gerçek verilerden ayrı, geçici bellekte açılır.

## Kayıt ve kurtarma

Yerel kurulumda veritabanı `~/Library/Application Support/LiquidityEdge/Journal.store` konumundadır. Görseller SwiftData tarafından aynı klasörde yönetilir. Bu klasör uygulama paketinden ayrıdır; uygulamayı güncellemek kayıtları silmez. Kaydet işlemi tamamlanmadan düzenleyici kapanmaz; hatalar gösterilir. Uygulama verileri kendiliğinden temizlemez.

Tercihler atomik olarak `Journal.preferences.json` dosyasına yazılır. Önceki sürümün tercihleri ilk kullanımda okunur.

`Journal-Backups` klasöründe günde bir otomatik kurtarma kopyası tutulur. İşlem/strateji silme, yedek geri yükleme ve CSV içe aktarma öncesinde ek güvenlik kopyaları oluşturulur. Bu dosyalar otomatik silinmez. Ayarlar → Veri ve Yedek bölümünde kayıt konumunu, son yedeği ve yedek klasörünü görebilir, elle kopya oluşturabilir veya JSON/CSV dışa aktarabilirsin. JSON yedeği işlemleri, görselleri, açıklamaları, stratejileri ve tercihleri kapsar.

Veritabanı açılamazsa uygulama hata gösterir; sessizce boş bir günlük oluşturup mevcut dosyayı değiştirmez.

## Derleme ve kurulum

```sh
bash Scripts/build-local.sh
python3 Scripts/install-local.py
```

Yerel kurulum `~/Applications/Liquidity Edge.app` yolunu kullanır ve Dock kısayolunu bu uygulamaya bağlar. Önceki uygulama ve Dock tercihleri değiştirilmeden önce yedeklenir. Xcode projesi de kullanılabilir; Xcode'un sandbox sürümü kendi macOS kapsayıcısındaki veritabanını kullanır.

## Doğrulama

```sh
swift test
bash Scripts/test-local.sh
bash Scripts/render-previews.sh
```

Testler hesaplamaları, Türkçe aramayı, kayıtların yeniden açılmasını, görselleri, içe/dışa aktarmayı ve kurtarma kopyalarını kapsar. Önizlemeler `build/previews` klasörüne üretilir.

## Tasarım raporu

Güncellenen ekranlar, bileşenler, dosyalar ve doğrulama kapsamı için [görsel yenileme raporuna](Docs/PREMIUM-REDESIGN.md), gerçek SwiftUI görüntüleri için [önizleme galerisine](Docs/design-preview.html) bakabilirsin.
