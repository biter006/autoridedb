# Nhật ký trao đổi AI cho AutoRide

## Kiểu dữ liệu tài chính

**Prompt:** Với tiền cọc, phí trả trễ và phí hư hỏng trong MySQL, nên dùng `FLOAT`, `DOUBLE` hay `DECIMAL`?

**Kết quả áp dụng:** Dùng `DECIMAL(10,2)` vì kiểu này lưu giá trị thập phân chính xác. `FLOAT` và `DOUBLE` có thể sinh sai số nhị phân, làm chênh lệch tiền hoàn cọc khi tính toán.

## Quan hệ biên bản kiểm tra

**Prompt:** Bảng `Inspections` nên có quan hệ 1-1 hay 1-N với `Rentals` khi mỗi xe được kiểm tra một lần lúc trả?

**Kết quả áp dụng:** Chọn 1-1 theo quy trình hiện tại: mỗi hợp đồng có tối đa một biên bản trả xe. Cột `rental_id` là khóa ngoại và có ràng buộc `UNIQUE`. Nếu sau này công ty cần kiểm tra nhiều lần trong thời gian thuê, có thể bỏ `UNIQUE` để chuyển thành 1-N.

## Chặn biên bản không hợp lệ

**Prompt:** Làm thế nào chặn việc chèn biên bản kiểm tra cho hợp đồng đang `BOOKED` ở tầng CSDL?

**Kết quả áp dụng:** Tạo trigger `BEFORE INSERT` trên `Inspections`. Trigger kiểm tra `Rentals.status` và chỉ cho phép thêm biên bản khi hợp đồng đang `ACTIVE`; các trạng thái khác gây lỗi `SIGNAL SQLSTATE '45000'`.
