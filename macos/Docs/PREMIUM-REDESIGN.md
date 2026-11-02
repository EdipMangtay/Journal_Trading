# Görsel yenileme raporu — 2 Kasım 2026

## Kapsam ve proje incelemesi

Uygulama bir **macOS 14+** projesidir: SwiftUI, AppKit, Swift Charts ve SwiftData kullanır. iOS'a taşınmadı. Swift 5 dil modu ve mevcut bağımlılıksız mimari korundu. Ana pencere, kenar çubuğu, komut araması, işlem listesi, işlem düzenleme/ayrıntı, takvim, analizler, strateji analizi, istatistikler, hata incelemesi, strateji defteri, değerlendirmeler, görsel kütüphanesi, görsel işaretleme ve ayarlar incelendi.

Kimlik doğrulama, uzak API veya ağ bağlantısı bu uygulamada bulunmuyor. Veri modelleri, servisler, hesaplamalar ve taslak modeli bu kapsamlı tasarım aşamasında değiştirilmedi: korunan 12 Swift dosyası, aşama öncesi kopyalarıyla içerik bazında karşılaştırıldı ve aynı bulundu.

## Tasarım yaklaşımı

Koyu grafit ve açık gri yüzeyler, anlamı tutarlı durum renkleri, sistem yazı tipleri, hizalı sayısal değerler ve belirgin odak durumları kullanıldı. Formların etiketleri değer yazıldığında kaybolmuyor. Butonların hover, basılı, devre dışı ve yıkıcı eylem durumları ayrıştırıldı. Native macOS metin düzenleme, açılır seçimler, tarih kontrolleri, dosya panelleri ve klavye davranışları korundu. Hareketler uygulama tercihi ve Reduce Motion ile sınırlandırıldı.

## Güncellenen ekranlar

| Ekran | Görsel değişiklik |
|---|---|
| Ana sayfa | Grafik kartları, belirgin sonuç hiyerarşisi, dengeli metrik ızgaraları, dönem ve birim kontrolleri |
| İşlemler | Daha okunaklı satırlar, hizalı sonuç sütunları, odaklı arama ve etiketli gelişmiş filtreler |
| Analiz / strateji analizi / istatistik | Tutarlı eğri ve karşılaştırma panelleri, bilgi amaçlı scatter plot, veri ve örneklem açıklamaları |
| Takvim | Gün kartları, seçili gün/bugün/hover durumları, belirgin ay kontrolleri |
| Strateji defteri | Model kartları, beş sütunlu ölçüm şeridi, etiketli kurallar ve düzenleyici |
| Değerlendirmeler | Dönem kartları, odak alanları, canlı istatistik tablosu, düzenli not editörleri |
| İşlem düzenleyici | Kalıcı etiketler, uyarlanabilir alan ızgaraları, bölümlere ayrılmış bağlam ve puanlama, görünür doğrulama |
| İşlem ayrıntısı | Sonuç hiyerarşisi, kaydırılabilir işlem akışı, not ve görsel inceleme kartları |
| Görseller | Kütüphane kartları, sürükleme alanı, iki satırlı araç çubuğu ve ekrana uyan inceleme penceresi |
| Ayarlar | Görünüm ve hesap alanları, geniş pencerede iki sütunlu gruplama, seçilebilir enstrümanlar, belirgin yerel veri/yedek bölümü |
| Komut araması / boş durum / açılış hatası | Ortak yüzeyler, ikonlar, metin hiyerarşisi ve eylem stilleri |

## Grafikler

Sermaye, R, yüzde, gerileme ve hareketli kazanma eğrilerinde çizgi/dolgu ayrımı, eksenler, tarih etiketleri, seçim çizgisi ve seçili değer göstergeleri yenilendi. Gerçek noktaları değiştirmeyen doğrusal çizim korundu. Grup grafiklerinde kategori sütunu, örneklem sayısı, ölçüm birimi ve taşmayan sonuç etiketleri bulunur. Isı haritasında gün adları yatay kaydırmanın dışında kalır.

İstenen scatter plot, filtrelenen işlemlerin süreç puanı/risk yüzdesi/süresini R veya net sonuçla karşılaştırır. Eksik eksen verileri uydurulmaz; dışlanan kayıt sayısı açıklanır. Nokta incelemesi, sıfır ve ortalama referansları ile ilişki özeti sunulur. Bu grafik bilgi amaçlıdır; tahmin veya işlem sinyali üretmez.

## Ortak bileşenler

`EdgeTextFieldStyle`, `.edgeEditorSurface()`, `EdgeType`, animasyon tercihi ortam değeri eklendi. `EdgeButtonStyle`, `NavigationButtonStyle`, `SegmentedTabs`, `Panel`, `Badge`, `MetricCard`, `ChipSelection`, `ScoreSlider` ve `NoteField` ortak tasarıma uyarlandı. Mevcut çağrı arayüzleri korundu.

## Değişen dosyalar

- `LiquidityEdge/Components/DesignSystem.swift`
- `LiquidityEdge/Views/RootView.swift`
- `LiquidityEdge/Views/DashboardView.swift`
- `LiquidityEdge/Views/TradesView.swift`
- `LiquidityEdge/Views/AnalyticsView.swift`
- `LiquidityEdge/Views/CalendarView.swift`
- `LiquidityEdge/Views/SettingsView.swift`
- `LiquidityEdge/Views/PlaybookView.swift`
- `LiquidityEdge/Views/ReviewsView.swift`
- `LiquidityEdge/Views/TradeEditorView.swift`
- `LiquidityEdge/Views/TradeDetailView.swift`
- `LiquidityEdge/Views/ScreenshotViews.swift`
- `LiquidityEdge/Charts/PerformanceCharts.swift`
- `LiquidityEdge/Charts/TradeScatterChart.swift`
- `LiquidityEdge/LiquidityEdgeApp.swift`
- `LiquidityEdge.xcodeproj/project.pbxproj`
- `Scripts/build-local.sh`, `Scripts/install-local.py`, `Scripts/render-previews.swift`
- Tasarım ve doğrulama belgeleri.

## Gerçekleştirilen doğrulamalar

- `Scripts/test-local.sh`: **24 test, 0 hata**. Hesaplama, Türkçe arama, CRUD, yeniden açma, görsel/işaretleme saklama, içe/dışa aktarma ve kurtarma kopyası kontrolleri dahil.
- Optimize edilmiş yerel uygulama derlendi ve imzalandı. Xcode 27.2 ile Release derlemesi de arm64 ve x86_64 hedefleri için başarıyla tamamlandı.
- **26 SwiftUI önizlemesi** üretildi; koyu/açık tema, dar ana pencere, işlem ve strateji editörleri, değerlendirme editörü ve görsel inceleme dahil görsel kontrol yapıldı.
- Kurulu paket imza kontrolünden geçti; ayrı geçici günlük ile başlatılıp tam ana pencere ve veritabanı oluşturması doğrulandı.
- Çalışan kurulu sürümde yeni işlem penceresi, native alan düzenleme, boş enstrümanda doğrulama hatası, Escape ile iptal, ⌘K araması, Enter ile sayfa açma ve demo alanında tema kaydetme test edildi.
- Demo kapatıldığında gerçek günlüğün önceki koyu teması ve kayıt sayısı korundu.
- Dock kaydındaki tek `com.liquidityedge.journal` kısayolu `~/Applications/Liquidity Edge.app` yoluna bağlı. Güncel uygulama bu kurulu yoldan açıldı. Önceki sürüm ZIP olarak saklandı.

## Doğrulama sınırları

Çalıştırma kontrolleri bu **macOS 27.2 / Apple Silicon** bilgisayarda yapıldı. iOS cihaz/simülatör, macOS 14 çalışma zamanı ve fiziksel Intel Mac üzerinde çalıştırma testi yapılmadı. Mevcut Swift 5 dil modunda, SDK kaynaklı SwiftData `KeyPath`/`Sendable` uyarıları derlemeyi engellemiyor; Swift 6 dil moduna geçiş bu görsel çalışmanın kapsamına alınmadı. Erişilebilirlik etiketleri/odak durumları kontrol edildi; VoiceOver ile baştan sona elle gezinme yapılmadı. Tüm görsel işaretleme hareket kombinasyonları için uçtan uca UI otomasyon paketi eklenmedi; mevcut görsel saklama/geri yükleme testleri geçti ve işaretleme katmanı önizlemede çizdirildi.

Üretim verilerine örnek kayıt eklenmedi. Önizleme görselleri yalnızca ayrı, bellekte çalışan demo alanında kullanıldı.
