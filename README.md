# Patro for macOS (Menu Bar App)

Native macOS Menu Bar application for **Bikram Sambat (वि.सं.) Nepali Calendar**, built with Swift, SwiftUI, and AppKit. Powered by the offline astronomical and calendar engine derived from [yogeshojha/patro](https://github.com/yogeshojha/patro).

---

## मुख्य विशेषताहरू (Features)

1. **macOS Menu Bar मा प्रत्यक्ष नेपाली मिति**:
   - शीर्ष मेनु बारमा आजको सफा नेपाली मिति (उदा: `१७ कात्तिक २०८३`) प्रत्यक्ष देखिन्छ।
   - Right-click गरेर विभिन्न फर्म्याटहरू (`१७ कात्तिक २०८३`, `मङ्गलबार, १७ कात्तिक २०८३`, `अंग्रेजी मितिसहित`, `अङ्क मात्र`) तुरुन्तै फेर्न सकिन्छ।
2. **सफा र अन्तरक्रियात्मक महिना पात्रो (Clean Monthly Popover)**:
   - मेनु बारको मितिमा क्लिक गर्दा सुन्दर म्याक-शैलीको पपओभर खुल्छ।
   - महिना र वर्ष सजिलै अगाडि/पछाडि सार्न सकिने (`<`, `>`, `<<`, `>>`, र `आज` बटन)।
   - शनिबार र सार्वजनिक बिदाहरू स्पष्ट रातो रङ्गमा देखिने।
   - कुनै अनावश्यक झन्झटविना सरल, चिटिक्क र मिनिमल क्यालेन्डर।
3. **छानिएको दिनको कार्ड (Selected Day Card)**:
   - क्यालेन्डरको कुनै पनि गतेमा क्लिक गर्दा त्यस दिनको पूर्ण बिक्रम संवत् मिति, बार, र इस्वी मिति (AD) देखिन्छ।
   - **One-Click Copy**: एक क्लिकमा मिति क्लिपबोर्डमा कपी हुन्छ।
4. **वि.सं. ↔ ई.सं. प्रत्यक्ष मिति रूपान्तरक (Date Converter)**:
   - बिक्रम संवत् (BS) मिति लेख्दा तुरुन्तै अंग्रेजी (AD) मा रूपान्तरण हुन्छ।
   - अंग्रेजी (AD) मिति लेख्दा तुरुन्तै नेपाली (BS) मा रूपान्तरण हुन्छ।
   - देवनागरी (२०८३-०७-१७) र ल्याटिन (2083-07-17) दुवै अङ्क सपोर्ट गर्छ।
   - "पात्रोमा हेर्नुहोस्" बटनबाट सीधै त्यो महिनाको क्यालेन्डर खुल्छ।
5. **भविष्य-सुरक्षित र स्वचालित अद्यावधिक (Zero-Rebuild Auto Update)**:
   - आउँदो नयाँ वर्ष (२०८४, २०८५...) को लागि पुनः नयाँ कोड लेख्न वा एप रिबिल्ड गर्नुपर्दैन।
   - मुख्य GitHub मा नयाँ वर्षको डेटा अपडेट हुनासाथ एपले पृष्ठभूमिमै स्वतः नयाँ क्यालेन्डर तालिका तान्छ, वा सेटिङबाट १-क्लिकमा अपडेट गर्न सकिन्छ।
6. **१००% अफलाइन र शुद्ध खगोलशास्त्र (Zero External APIs)**:
   - कुनै बाह्य सर्भर वा इन्टरनेट नभए पनि निर्बाध रूपमा चल्छ।
   - २००० देखि २०९० सम्मका ९१ वर्षको प्रमाणित तालिका।
   - Howard Hinnant को Civil Algorithm मार्फत टाइमजोन बग-रहित रूपान्तरण।

---

## निर्माण तथा इन्स्टलेसन (Build & Install)

### १. कमान्ड लाइनबाट सिधै बिल्ड गर्न:
```bash
git clone https://github.com/bishalramdam/patro-macos.git
cd patro-macos
chmod +x build.sh
./build.sh
```

### २. Applications फोल्डरमा सार्न:
```bash
cp -R build/Patro.app /Applications/
open /Applications/Patro.app
```

### ३. म्याक खुल्दा स्वतः सुरु हुन (Launch at Login):
- `System Settings` → `General` → `Login Items` मा जानुहोस्।
- `Open at Login` मा `+` थिचेर `/Applications/Patro.app` छान्नुहोस्।

---

## प्रविधि (Tech Stack)
- **Language**: Swift 6, AppKit & SwiftUI
- **Engine**: JavaScriptCore (Running consolidated Patro Engine offline)
- **Design**: Native macOS frosted glass (`NSVisualEffectView`, `NSStatusItem`, `NSPopover`)
- **Bundle ID**: `com.bishal.patromac`

---

## Credits & License
- Original Calendar & Astronomical Engine: [yogeshojha/patro](https://github.com/yogeshojha/patro) by Yogesh Ojha.
- macOS Menu Bar Native Implementation: **Er. Bishal Ramdam B.K.**
- License: [MIT License](LICENSE)
