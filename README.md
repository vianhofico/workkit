<div align="center">
  <img src="assets/icon/workkit_launcher.png" width="140" alt="Biểu tượng WorkKit" />

# WorkKit

### Bộ công cụ tài liệu miễn phí cho công việc hằng ngày

**Quét tài liệu · OCR · PDF · Chữ ký · QR · Xử lý ảnh · Sao lưu**

**Miễn phí trước tiên · Xử lý cục bộ · Ưu tiên quyền riêng tư**

[![TẢI WORKKIT - ANDROID APK](https://img.shields.io/badge/TẢI_WORKKIT-ANDROID_APK-5565FF?style=for-the-badge&logo=android&logoColor=white)](https://github.com/vianhofico/workkit/actions)

**Phiên bản: WorkKit 1.1.0 · Android hiện khả dụng · iOS-ready**
</div>

---

## WorkKit là gì?

**WorkKit** là ứng dụng tiện ích tài liệu dành cho điện thoại, tập trung vào những thao tác thường xuyên trong học tập và công việc: quét giấy tờ, nhận dạng chữ, xử lý PDF, ký tài liệu, quét/tạo QR, xử lý ảnh và sao lưu dữ liệu.

WorkKit được xây dựng theo nguyên tắc **local-first**: các công cụ cốt lõi chạy ngay trên thiết bị, không yêu cầu tạo tài khoản và không cần backend để sử dụng các tính năng chính.

### Phù hợp với

- Sinh viên cần quét bài, OCR tài liệu và xử lý PDF nhanh.
- Nhân viên văn phòng thường xuyên ký, gộp, tách hoặc chỉnh PDF.
- Người dùng muốn một ứng dụng QR, ảnh và tài liệu gọn trong cùng một nơi.
- Người ưu tiên quyền riêng tư và không muốn tải tài liệu cá nhân lên máy chủ không cần thiết.

---

## 🌐 Ngôn ngữ

WorkKit hiện hỗ trợ đầy đủ giao diện:

- 🇻🇳 **Tiếng Việt**
- 🇬🇧 **English**
- 🌐 **Theo ngôn ngữ hệ thống**

Bạn có thể đổi ngôn ngữ ngay trong:

**Cài đặt → Ngôn ngữ → Theo hệ thống / Tiếng Việt / English**

Thay đổi có hiệu lực ngay và được lưu cục bộ trên thiết bị.

> Ngôn ngữ giao diện và ngôn ngữ OCR là hai phần độc lập. OCR hiện sử dụng mô hình Latin của Google ML Kit và được tối ưu cho văn bản **tiếng Việt + tiếng Anh**.

---

## ✨ Chức năng chính

### 📷 Quét tài liệu

- Quét giấy tờ trực tiếp bằng camera.
- Nhận diện cạnh và cắt tài liệu trong giao diện scanner native.
- Xoay và tăng cường hình ảnh.
- Quét nhiều trang.
- Lưu từng trang thành ảnh hoặc lưu chung thành PDF.
- Tệp hoàn tất được đưa vào thư viện cục bộ của WorkKit.

### 🔍 OCR — Nhận dạng văn bản

- OCR ảnh đã nhập hoặc ảnh vừa quét.
- OCR tài liệu PDF theo từng trang.
- Nhận dạng tiếng Việt và tiếng Anh bằng ML Kit trên thiết bị.
- Chỉnh sửa và lưu lại nội dung OCR.
- Smart Extract tự phát hiện email, số điện thoại, URL, ngày và số tiền.

### 📑 PDF Toolkit

- Ảnh → PDF.
- Gộp nhiều PDF.
- Tách PDF.
- Xóa trang.
- Sắp xếp lại trang.
- Xoay trang.
- PDF → ảnh.
- Hỗ trợ PDF có mật khẩu ở các thao tác tương thích.
- Luôn tạo bản sao mới thay vì ghi đè tệp gốc.

### ✍️ Chữ ký

- Vẽ chữ ký bằng tay ngay trên màn hình.
- Lưu nhiều chữ ký cục bộ.
- Chọn chữ ký và đặt lên PDF.
- Chọn trang, vị trí, kích thước và góc xoay.
- Xuất ra một bản PDF đã ký mới.

### 🔳 QR

- Quét QR bằng camera.
- Tạo QR từ văn bản, URL hoặc dữ liệu ngắn bất kỳ.
- Lưu lịch sử quét và QR đã tạo trên thiết bị.
- Không cần gửi nội dung QR lên server.

### 🖼 Xử lý ảnh

- Nén ảnh.
- Đổi kích thước.
- Cắt ảnh theo tọa độ/kích thước.
- Chuyển đổi JPG / PNG / WebP.
- Xóa EXIF, metadata văn bản nhúng và ICC profile.
- Giữ tệp gốc, tạo bản sao mới sau xử lý.

### 📁 Thư viện tài liệu

- Nhập tệp từ thiết bị.
- Recent files.
- Tìm kiếm.
- Yêu thích.
- Đổi tên.
- Xóa.
- Chia sẻ / xuất tệp.
- Xem nhanh dung lượng thư viện.

### 💾 Sao lưu & khôi phục

- Tạo bản sao lưu cục bộ của dữ liệu WorkKit.
- Sao lưu tài liệu, OCR, chữ ký, QR history và settings.
- Khôi phục dữ liệu từ backup.
- Tự dọn tệp tạm còn sót sau khi ứng dụng bị gián đoạn.

> Bản sao lưu hiện không được mã hóa. Hãy lưu nó ở vị trí an toàn.

---

## 🔒 Quyền riêng tư

WorkKit được thiết kế với các nguyên tắc:

- **Không bắt buộc tài khoản.**
- **Không backend cho các tính năng cốt lõi.**
- **Tệp ở trên thiết bị theo mặc định.**
- **OCR chạy on-device.**
- **QR được xử lý on-device.**
- **Không tự ghi đè tài liệu gốc.**
- Android tắt cloud backup tự động cho dữ liệu WorkKit và chặn cleartext traffic.

---

## ⬇️ Cài WorkKit trên Android

### Cách 1 — GitHub Actions

1. Nhấn nút **TẢI WORKKIT – ANDROID APK** ở đầu README.
2. Mở workflow **CI** mới nhất có trạng thái xanh.
3. Kéo xuống phần **Artifacts**.
4. Tải artifact có tên bắt đầu bằng `WorkKit-android-debug-`.
5. Giải nén file ZIP.
6. Mở `app-debug.apk` trên điện thoại Android và cài đặt.

Nếu Android chặn cài đặt, hãy cho phép **Install unknown apps / Cài ứng dụng không rõ nguồn gốc** cho trình duyệt hoặc ứng dụng quản lý tệp bạn đang dùng.

> File `.aab` dùng cho Google Play Console và không phải file cài trực tiếp lên điện thoại.

---

## 🛠 Công nghệ

- Flutter / Dart
- Riverpod
- go_router
- Drift + SQLite
- Google ML Kit Text Recognition
- ML Kit Document Scanner / VisionKit
- pdf_manipulator
- mobile_scanner
- qr_flutter
- package `image`
- GitHub Actions

---

## 🧑‍💻 Dành cho developer

```bash
flutter pub get
flutter gen-l10n
dart run tool/bootstrap_platforms.dart
dart run flutter_launcher_icons
dart run build_runner build
flutter analyze
flutter test
flutter build apk --debug
```

Platform Android/iOS được bootstrap có kiểm soát để giữ các thiết lập privacy, release hardening, tên hiển thị **WorkKit** và launcher icon nhất quán.

### Thêm ngôn ngữ mới

Xem tài liệu trong `docs/localization/`. Kiến trúc hiện tại dùng Flutter `gen_l10n`, nên một locale mới chủ yếu cần ARB translation, khai báo locale và test tương ứng.

---

## Trạng thái dự án

WorkKit 1.1.0 đã hoàn thiện M0–M8 ở cấp source/CI, bao gồm nền tảng local-first, document library, scanner, OCR, PDF toolkit, signature, QR, image toolkit, production hardening, giao diện Việt/Anh và launcher icon chính thức.

Các bước phát hành store vẫn cần Android signing key, Play Console và physical-device validation trước khi đưa lên production.

---

<div align="center">
  <strong>WorkKit — Scan. Convert. Extract. Sign. Organize.</strong><br/>
  Làm việc thông minh hơn, ngay trên thiết bị của bạn.
</div>
