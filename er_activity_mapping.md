# Đối chiếu Activity Diagram và ERD AutoRide

`damage_fee` là cột bắt buộc để cơ sở dữ liệu phản ánh đầy đủ quy trình trả xe. Activity Diagram quy định rằng sau kiểm tra, nếu phát hiện xe bị hư hỏng thì công ty phải tính phí sửa chữa và khấu trừ khoản này vào tiền cọc. Nếu chỉ có mô tả hư hỏng mà không có `damage_fee`, nhân viên biết xe bị lỗi nhưng kế toán không thể lưu số tiền phải bồi thường, không thể tính tiền hoàn lại và không có dữ liệu để đối soát doanh thu.

Thiết kế legacy còn thiếu `security_deposit` và `late_fee`, nên cũng không thể tính công thức hoàn cọc: `security_deposit - late_fee - damage_fee`. Cột `status` dạng `VARCHAR` làm phát sinh các giá trị tùy ý như `Done` hoặc `Finished`; `ENUM` giới hạn đúng bốn trạng thái nghiệp vụ là `BOOKED`, `ACTIVE`, `COMPLETED` và `CANCELLED`.

Bảng `Inspections` tách riêng biên bản kiểm tra khỏi `Rentals` để lưu ngày kiểm tra, người kiểm tra và mô tả hư hỏng mà không làm bảng hợp đồng bị lẫn dữ liệu nghiệp vụ khác. Khóa ngoại với `ON DELETE RESTRICT` bảo vệ biên bản kiểm tra khỏi việc bị mất khi còn hợp đồng liên quan.
