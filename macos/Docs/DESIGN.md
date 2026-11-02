# Yerel macOS tasarım sistemi

SwiftUI ve AppKit tabanlı, bağımlılıksız tasarım. Koyu grafit çalışma alanı; açık temada serin gri zemin ve beyaz yüzeyler. Gerçek renk değerleri `design-tokens.json` ve `DesignSystem.swift` içinde bulunur.

- Mint: olumlu sonuç ve birincil eylem. Mercan: negatif sonuç veya yıkıcı eylem. Amber: süreç ihlali. Mavi: bilgi ve ikincil vurgu.
- Sistem yazı tipleri; ölçümlerde yuvarlatılmış ve hizalı rakamlar. Metin, renk tek başına yeterli olmadığında anlamı açıklar.
- Panel/alan/buton ayrımı, düşük yoğunluklu kenarlıklar, kalıcı alan etiketleri ve belirgin klavye odağı.
- 80–180 ms kontrol geçişleri; uygulama animasyon tercihi ve Reduce Motion dikkate alınır.
- Çizimlerde veri, tarih, sıra ve hesaplamalar korunur. Eğrilerde gerçek değerleri çarpıtan yumuşatma kullanılmaz.
- Dar macOS penceresinde yeniden akış ve ekran boyutuna uyan kaydırılabilir modallar kullanılır.
- Native dosya panelleri, tarih kontrolleri ve metin düzenleme korunur.

Ayrıntılar: `PREMIUM-REDESIGN.md`. Gerçek SwiftUI önizlemeleri: `../build/previews`.
