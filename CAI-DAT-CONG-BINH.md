# CÀI ZL-CRM LÊN VPS – BẢN CÔNG BÌNH MEDICAL

Làm lần lượt từ trên xuống. Mỗi khối lệnh copy dán vào cửa sổ SSH của VPS.
Thời gian: khoảng 30–45 phút.

## 0. Chuẩn bị

- 1 VPS Ubuntu 22.04/24.04, **2 vCPU, 4 GB RAM, 40 GB ổ** (Vultr, DigitalOcean, Viettel IDC, BizFly…).
- 1 tên miền phụ, ví dụ `crm.congbinh.vn`, trỏ bản ghi A về IP VPS.
- 1 tên miền phụ cho file, ví dụ `files.congbinh.vn`, cũng trỏ về IP VPS.
- Quyền vào repo `congbinhmedical-maker/zl-crm-congbinh` trên GitHub.

## 1. Cài Docker

```bash
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker $USER
exit
```

SSH lại vào VPS, kiểm tra:

```bash
docker --version && docker compose version
```

## 2. Tải mã nguồn

```bash
git clone https://github.com/congbinhmedical-maker/zl-crm-congbinh.git
cd zl-crm-congbinh
```

## 3. Tạo file cấu hình .env với mật khẩu ngẫu nhiên

Sửa 2 dòng đầu cho đúng tên miền của mình, rồi dán cả khối:

```bash
CRM_DOMAIN=crm.congbinh.vn
FILES_DOMAIN=files.congbinh.vn

cp .env.example .env
DBPASS=$(openssl rand -hex 24)
MINIOPASS=$(openssl rand -hex 24)
ADMINPASS=$(openssl rand -base64 18 | tr -d '/+=')
sed -i \
  -e "s|^APP_URL=.*|APP_URL=https://$CRM_DOMAIN|" \
  -e "s|^JWT_SECRET=.*|JWT_SECRET=$(openssl rand -hex 32)|" \
  -e "s|^ENCRYPTION_KEY=.*|ENCRYPTION_KEY=$(openssl rand -hex 32)|" \
  -e "s|^DB_PASSWORD=.*|DB_PASSWORD=$DBPASS|" \
  -e "s|^DATABASE_URL=.*|DATABASE_URL=postgresql://crmuser:$DBPASS@db:5432/zalocrm|" \
  -e "s|^S3_PUBLIC_URL=.*|S3_PUBLIC_URL=https://$FILES_DOMAIN|" \
  -e "s|^S3_ACCESS_KEY=.*|S3_ACCESS_KEY=crmminio|" \
  -e "s|^S3_SECRET_KEY=.*|S3_SECRET_KEY=$MINIOPASS|" \
  -e "s|^MINIO_ROOT_USER=.*|MINIO_ROOT_USER=crmminio|" \
  -e "s|^MINIO_ROOT_PASSWORD=.*|MINIO_ROOT_PASSWORD=$MINIOPASS|" \
  -e "s|^FB_TOKEN_ENC_KEY=.*|FB_TOKEN_ENC_KEY=$(openssl rand -hex 32)|" \
  -e "s|^BOOTSTRAP_ADMIN_PASSWORD=.*|BOOTSTRAP_ADMIN_PASSWORD=$ADMINPASS|" \
  -e "s|^BOOTSTRAP_ORG_NAME=.*|BOOTSTRAP_ORG_NAME=Cong Binh Medical|" \
  .env
chmod 600 .env
echo "MAT KHAU ADMIN: $ADMINPASS   (chep lai ngay, cat vao noi an toan)"
```

Kiểm tra thêm bằng `nano .env`:
- `BOOTSTRAP_ADMIN_PHONE=` đổi thành số điện thoại admin.
- `BOOTSTRAP_ADMIN_EMAIL=` điền email admin.
- Phần AI: điền `ANTHROPIC_AUTH_TOKEN=` (khóa Claude) hoặc `GEMINI_AUTH_TOKEN=`. **Không dùng Qwen/Kimi** cho dữ liệu khách hàng.

Lưu: `Ctrl+X` → `Y` → `Enter`.

## 4. Khởi chạy

```bash
docker compose up -d --build
docker compose ps
```

Tất cả container phải ở trạng thái `Up` / `healthy`. Lần đầu build mất 3–5 phút.

## 5. Bật HTTPS bằng Caddy (tự lấy chứng chỉ SSL)

```bash
sudo apt-get install -y caddy
sudo tee /etc/caddy/Caddyfile >/dev/null <<EOF
$CRM_DOMAIN {
    reverse_proxy localhost:3080
}
$FILES_DOMAIN {
    reverse_proxy localhost:9000
}
EOF
sudo systemctl restart caddy
```

(Nếu đã thoát SSH và mất biến, thay `$CRM_DOMAIN`, `$FILES_DOMAIN` bằng tên miền thật.)

## 6. Tường lửa – chỉ mở cổng cần thiết

```bash
sudo ufw allow OpenSSH
sudo ufw allow 80
sudo ufw allow 443
sudo ufw --force enable
```

Lưu ý: Docker tự mở cổng 3080 và 9000 qua ufw. Không sao vì Caddy đã chạy HTTPS phía trước, nhưng chỉ chia sẻ link `https://...` cho nhân viên.

## 7. Đăng nhập lần đầu

1. Mở `https://crm.congbinh.vn`
2. Đăng nhập bằng số điện thoại admin + mật khẩu in ra ở bước 3.
3. **Đổi mật khẩu ngay** trong phần hồ sơ.
4. Tạo tài khoản cho từng nhân viên sales (Cài đặt → Phân quyền → Thêm nhân viên).

## 8. Kết nối Zalo (CHỈ NICK PHỤ trong 30 ngày đầu)

1. Menu **Tài khoản Zalo** → **Thêm Zalo** → đặt tên (VD: "Zalo Sale Hương").
2. Bấm biểu tượng **QR** → mở Zalo trên điện thoại quét mã.
3. Trạng thái xanh lá = đã kết nối.

Quy tắc an toàn nick:
- Không gửi tin hàng loạt (broadcast) trong 30 ngày đầu.
- Giữ `ZALO_MSG_BURST=5` và `BROADCAST_GROUP_DELAY_MS=15000` như mặc định.
- Thấy Zalo cảnh báo → ngắt kết nối nick đó ngay, báo lại.

## 9. Sao lưu

Docker đã có container `backup` sao lưu database hằng ngày vào thư mục `~/zl-crm-congbinh/backups` (giữ 7 ngày, 4 tuần, 3 tháng). Thêm: mỗi tuần tải file backup về máy khác.

```bash
ls -lh ~/zl-crm-congbinh/backups/daily
```

Database chứa **phiên đăng nhập Zalo** – ai có file backup là chiếm được nick. Không gửi file backup qua Zalo/email.

## 10. Cập nhật phiên bản

```bash
cd ~/zl-crm-congbinh
git pull
docker compose up -d --build
```

## Lỗi thường gặp

| Hiện tượng | Xử lý |
|---|---|
| Container `app` khởi động rồi tắt | `docker compose logs app --tail 50` – thường do thiếu JWT_SECRET/ENCRYPTION_KEY |
| Không vào được web | Kiểm tra tên miền trỏ đúng IP, `sudo systemctl status caddy` |
| Gửi ảnh cho khách bị lỗi | Kiểm tra `S3_PUBLIC_URL` đúng `https://files...` và mở được từ ngoài |
| Nick Zalo tự ngắt | Quét QR lại; nếu lặp lại nhiều lần, tạm dừng nick đó |
