<div align="center">

# 🧰 WorkKit

### Bộ công cụ tài liệu miễn phí cho công việc hằng ngày

**Quét tài liệu · OCR · PDF · Chữ ký · QR · Xử lý ảnh · Sao lưu**

WorkKit là ứng dụng di động tập trung nhiều công cụ xử lý tài liệu vào một nơi, ưu tiên **miễn phí**, **hoạt động cục bộ trên thiết bị** và **quyền riêng tư**.

Không cần tạo tài khoản. Không cần backend để sử dụng các tính năng chính.

[![Tải WorkKit cho Android](https://img.shields.io/badge/TẢI_WORKKIT-ANDROID_APK-3DDC84?style=for-the-badge&logo=android&logoColor=white)](https://github.com/vianhofico/workkit/actions/workflows/ci.yml)

**Phiên bản hiện tại: WorkKit 1.0.0**

</div>

---

## WorkKit là gì?

WorkKit được xây dựng để thay thế nhiều ứng dụng nhỏ thường phải cài riêng như ứng dụng scan tài liệu, OCR, chỉnh sửa PDF, ký PDF, đọc QR hay nén ảnh.

Thay vì phải chuyển tài liệu qua nhiều dịch vụ khác nhau, WorkKit cung cấp một bộ công cụ thống nhất ngay trên điện thoại.

Phù hợp cho:

- Sinh viên cần scan bài tập, giáo trình, tài liệu.
- Nhân viên văn phòng thường xuyên làm việc với PDF và hình ảnh.
- Người cần trích xuất chữ từ ảnh hoặc tài liệu.
- Người muốn ký PDF nhanh trên điện thoại.
- Người muốn xử lý tài liệu mà hạn chế đưa dữ liệu lên dịch vụ bên ngoài.

---

## ✨ Các chức năng chính

### 📷 Quét tài liệu

Biến điện thoại thành máy scan tài liệu.

- Quét một hoặc nhiều trang.
- Tự nhận diện vùng tài liệu.
- Cắt và chỉnh phối cảnh.
- Xoay trang.
- Tăng cường chất lượng ảnh bằng công cụ native trên thiết bị.
- Lưu kết quả thành ảnh hoặc PDF.

### 🔎 OCR — nhận dạng chữ trong ảnh và PDF

Trích xuất nội dung văn bản từ tài liệu bằng OCR chạy trên thiết bị.

- OCR từ ảnh.
- OCR tài liệu đã scan.
- OCR PDF nhiều trang.
- Hỗ trợ nội dung tiếng Việt và tiếng Anh theo mô hình Latin OCR.
- Chỉnh sửa văn bản sau khi nhận dạng.
- Sao chép nội dung nhanh.
- Tự phát hiện một số dữ liệu hữu ích như số điện thoại, email, URL, ngày tháng và số tiền.

### 📄 Bộ công cụ PDF

Các thao tác PDF phổ biến được gom vào một nơi.

- Gộp nhiều PDF.
- Tách PDF.
- Trích xuất trang.
- Sắp xếp lại thứ tự trang.
- Xoay trang.
- Xóa trang.
- Chuyển ảnh thành PDF.
- Chuyển PDF thành ảnh.
- Làm việc với PDF có mật khẩu.
- Xử lý file lớn theo hướng tiết kiệm bộ nhớ.

WorkKit tạo file kết quả mới và không chủ động ghi đè lên tài liệu gốc.

### ✍️ Chữ ký điện tử trên PDF

- Vẽ chữ ký trực tiếp trên màn hình.
- Lưu nhiều chữ ký trên thiết bị.
- Chèn chữ ký vào PDF.
- Điều chỉnh vị trí.
- Thay đổi kích thước.
- Xoay chữ ký.
- Xuất thành một bản PDF mới đã ký.

### 🔳 QR Code

- Quét QR bằng camera.
- Bật/tắt đèn pin khi quét.
- Tạo QR Code từ nội dung văn bản.
- Lưu lịch sử QR ngay trên thiết bị.

### 🖼️ Công cụ xử lý ảnh

- Nén ảnh.
- Resize ảnh.
- Crop ảnh.
- Chuyển đổi JPG / PNG / WebP.
- Xóa metadata khỏi ảnh.
- Chạy các tác vụ xử lý nặng ngoài UI isolate để hạn chế làm đứng giao diện.

### 📚 Thư viện tài liệu

WorkKit có thư viện riêng để quản lý các tài liệu đã nhập hoặc tạo ra.

- Import file từ thiết bị.
- Tìm kiếm tài liệu.
- Xem tài liệu gần đây.
- Đánh dấu yêu thích.
- Đổi tên.
- Xóa.
- Chia sẻ / xuất file.
- Xem dung lượng thư viện.

### 💾 Sao lưu và khôi phục

- Tạo bản sao lưu dữ liệu WorkKit.
- Khôi phục lại dữ liệu từ backup.
- Phục hồi trạng thái khi một tác vụ dài bị gián đoạn do ứng dụng bị tắt.
- Dọn file tạm bị bỏ lại.
- Có cơ chế xử lý lỗi khi thiết bị gần hết dung lượng.

> Bản backup hiện là file di động không mã hóa. Hãy lưu nó ở nơi an toàn nếu tài liệu của bạn có dữ liệu nhạy cảm.

---

## 🔐 Quyền riêng tư

WorkKit được thiết kế theo hướng **local-first**.

Các tính năng chính như scan, OCR, xử lý PDF, chữ ký, QR và xử lý ảnh được thực hiện trên thiết bị. Ứng dụng không yêu cầu tài khoản để sử dụng các chức năng cốt lõi và không cần backend cho luồng sử dụng chính.

Nguyên tắc của WorkKit:

- Không chủ động tải tài liệu của bạn lên máy chủ WorkKit.
- Không ghi đè file nguồn khi xử lý tài liệu.
- Không cố ý ghi nội dung tài liệu hoặc mật khẩu PDF vào log.
- Chữ ký được lưu cục bộ.
- Lịch sử QR được lưu cục bộ.

---

## 📱 Tải và cài đặt trên Android

### Tải APK mới nhất

[![Tải APK Android](https://img.shields.io/badge/TẢI_APK-MỚI_NHẤT-3DDC84?style=for-the-badge&logo=android&logoColor=white)](https://github.com/vianhofico/workkit/actions/workflows/ci.yml)

Hiện tại APK được tạo tự động bởi GitHub Actions.

Cách tải:

1. Nhấn nút **Tải APK mới nhất** ở trên.
2. Mở lần chạy `CI` thành công gần nhất của nhánh `main`.
3. Kéo xuống phần **Artifacts**.
4. Tải artifact có tên bắt đầu bằng `workkit-android-debug-`.
5. Giải nén file ZIP.
6. Mở file `app-debug.apk` trên điện thoại Android.
7. Nếu Android yêu cầu, cho phép trình duyệt hoặc ứng dụng Files **cài ứng dụng không rõ nguồn gốc**.
8. Chọn **Install / Cài đặt**.

> Repository hiện có thể yêu cầu đăng nhập GitHub để tải artifact nếu đang để chế độ Private.

### Lưu ý về bản cài hiện tại

APK trong CI hiện là **debug build**, phù hợp để cài và kiểm thử các chức năng trực tiếp trên thiết bị. Bản phát hành qua Google Play sẽ sử dụng release AAB được ký bằng upload key riêng.

---

## 🍎 iOS

Codebase đã được chuẩn bị để bootstrap project iOS và có các adapter dành cho những chức năng native tương ứng.

Việc phát hành iOS chính thức vẫn cần kiểm thử trên iPhone/iPad thật, cấu hình signing của Apple và quy trình App Store/TestFlight.

---

## 🛠️ Dành cho developer

WorkKit được xây dựng bằng Flutter với kiến trúc local-first.

### Công nghệ chính

- Flutter / Dart.
- Riverpod — state management.
- go_router — navigation.
- Drift + SQLite — cơ sở dữ liệu local.
- ML Kit / native document scanning và OCR.
- Native/on-device PDF, QR và image processing.

### Khởi tạo project Android/iOS

```bash
dart run tool/bootstrap_platforms.dart
flutter pub get
dart run build_runner build
```

### Quality gate

```bash
flutter analyze
flutter test --coverage
flutter build apk --debug
flutter build appbundle --release
```

GitHub Actions tự động chạy analyzer, test, build Android APK và release AAB. Các build thành công được lưu dưới dạng workflow artifacts.

---

## 🚀 Trạng thái dự án

**WorkKit 1.0 đã hoàn thành phần implementation từ M0 đến M7.**

Các phần đã có trong repository:

- ✅ Foundation & architecture.
- ✅ Document Library.
- ✅ Document Scanner.
- ✅ OCR & Smart Extract.
- ✅ PDF Toolkit.
- ✅ Signature.
- ✅ QR Tools.
- ✅ Image Toolkit.
- ✅ Backup / Restore.
- ✅ Recovery & low-storage handling.
- ✅ Accessibility / security / performance hardening.
- ✅ Android CI build APK.
- ✅ Android release AAB pipeline.

Các bước còn phụ thuộc thiết bị hoặc tài khoản phát hành được theo dõi trong [`docs/project/external-validation.md`](docs/project/external-validation.md).

---

## 💡 Triết lý của WorkKit

> **Free first. Local first. Privacy first.**

Mục tiêu của WorkKit là cung cấp những công cụ tài liệu thường dùng trong một ứng dụng đơn giản, hữu ích và không buộc người dùng phải đăng ký thuê bao chỉ để thực hiện các tác vụ cơ bản.

---

<div align="center">

### WorkKit — Free Tools for Everyday Work

**Scan. Convert. Extract. Sign. Organize. Work smarter.**

</div>
