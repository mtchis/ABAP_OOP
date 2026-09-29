*&---------------------------------------------------------------------*
*& Report ZOOP_QUAN_LY_LUONG
*&---------------------------------------------------------------------*
*& Minh họa lập trình hướng đối tượng (OOP) trong ABAP:
*&   1. Tính trừu tượng (Abstraction) : lớp ABSTRACT + phương thức ABSTRACT
*&   2. Tính kế thừa   (Inheritance) : INHERITING FROM, kế thừa nhiều cấp
*&   3. Tính đa hình    (Polymorphism): REDEFINITION, gọi qua tham chiếu
*&                                      lớp cha, up-cast / down-cast
*&
*& Cập nhật: thêm LƯƠNG THƯỞNG đa hình - mỗi loại nhân viên có một
*&           công thức tính thưởng riêng (tinh_thuong).
*&
*& Yêu cầu: SAP NetWeaver ABAP 7.40 trở lên (dùng NEW, DATA(...) inline)
*&---------------------------------------------------------------------*
REPORT zoop_quan_ly_luong.

TYPES: ty_tien  TYPE p LENGTH 15 DECIMALS 2,
       ty_ty_le TYPE p LENGTH 5  DECIMALS 3.

*----------------------------------------------------------------------*
* 1. LỚP TRỪU TƯỢNG: Nhân viên
*----------------------------------------------------------------------*
CLASS lcl_nhan_vien DEFINITION ABSTRACT.
  PUBLIC SECTION.
    METHODS:
      constructor
        IMPORTING iv_ma  TYPE string
                  iv_ten TYPE string,

      " --- Phương thức trừu tượng: mỗi lớp con BẮT BUỘC tự cài đặt ---
      tinh_luong ABSTRACT
        RETURNING VALUE(rv_luong) TYPE ty_tien,

      tinh_thuong ABSTRACT                     " MỚI: thưởng đa hình
        RETURNING VALUE(rv_thuong) TYPE ty_tien,

      get_cong_thuc_thuong ABSTRACT            " MỚI: mô tả công thức
        RETURNING VALUE(rv_cong_thuc) TYPE string,

      get_loai ABSTRACT
        RETURNING VALUE(rv_loai) TYPE string,

      " --- Phương thức cụ thể: dùng chung cho mọi lớp con ---
      tinh_tong_thu_nhap                       " MỚI: lương + thưởng
        RETURNING VALUE(rv_tong) TYPE ty_tien,

      get_ma
        RETURNING VALUE(rv_ma) TYPE string,

      hien_thi.

    CLASS-METHODS get_so_luong
      RETURNING VALUE(rv_so) TYPE i.

  PROTECTED SECTION.
    DATA: mv_ma  TYPE string,
          mv_ten TYPE string.

  PRIVATE SECTION.
    CLASS-DATA gv_so_luong TYPE i.
ENDCLASS.

CLASS lcl_nhan_vien IMPLEMENTATION.
  METHOD constructor.
    mv_ma  = iv_ma.
    mv_ten = iv_ten.
    gv_so_luong = gv_so_luong + 1.
  ENDMETHOD.

  METHOD tinh_tong_thu_nhap.
    " Template method: lớp cha định nghĩa "cái khung",
    " còn tinh_luong / tinh_thuong chạy theo lớp con thực tế (ĐA HÌNH)
    rv_tong = tinh_luong( ) + tinh_thuong( ).
  ENDMETHOD.

  METHOD get_ma.
    rv_ma = mv_ma.
  ENDMETHOD.

  METHOD hien_thi.
    DATA(lv_loai)      = get_loai( ).
    DATA(lv_luong)     = tinh_luong( ).
    DATA(lv_thuong)    = tinh_thuong( ).
    DATA(lv_cong_thuc) = get_cong_thuc_thuong( ).
    DATA(lv_tong)      = tinh_tong_thu_nhap( ).

    WRITE: / 'Mã NV       :', mv_ma,
           / 'Họ tên      :', mv_ten,
           / 'Loại NV     :', lv_loai,
           / 'Lương       :', lv_luong, 'VND',
           / 'Thưởng      :', lv_thuong, 'VND',
           / 'Công thức   :', lv_cong_thuc,
           / 'Tổng thu nhập:', lv_tong, 'VND'.
  ENDMETHOD.

  METHOD get_so_luong.
    rv_so = gv_so_luong.
  ENDMETHOD.
ENDCLASS.

*----------------------------------------------------------------------*
* 2. LỚP CON CẤP 1: Nhân viên chính thức
*    Thưởng = 50% lương cơ bản
*----------------------------------------------------------------------*
CLASS lcl_nv_chinh_thuc DEFINITION INHERITING FROM lcl_nhan_vien.
  PUBLIC SECTION.
    METHODS:
      constructor
        IMPORTING iv_ma              TYPE string
                  iv_ten             TYPE string
                  VALUE(iv_luong_cb) TYPE ty_tien
                  VALUE(iv_phu_cap)  TYPE ty_tien,
      tinh_luong           REDEFINITION,
      tinh_thuong          REDEFINITION,
      get_cong_thuc_thuong REDEFINITION,
      get_loai             REDEFINITION.

  PROTECTED SECTION.
    CONSTANTS c_ty_le_thuong_cb TYPE ty_ty_le VALUE '0.500'.
    DATA: mv_luong_cb TYPE ty_tien,
          mv_phu_cap  TYPE ty_tien.
ENDCLASS.

CLASS lcl_nv_chinh_thuc IMPLEMENTATION.
  METHOD constructor.
    super->constructor( iv_ma = iv_ma iv_ten = iv_ten ).
    mv_luong_cb = iv_luong_cb.
    mv_phu_cap  = iv_phu_cap.
  ENDMETHOD.

  METHOD tinh_luong.
    rv_luong = mv_luong_cb + mv_phu_cap.
  ENDMETHOD.

  METHOD tinh_thuong.
    rv_thuong = mv_luong_cb * c_ty_le_thuong_cb.
  ENDMETHOD.

  METHOD get_cong_thuc_thuong.
    rv_cong_thuc = '50% x Lương cơ bản'.
  ENDMETHOD.

  METHOD get_loai.
    rv_loai = 'Chính thức'.
  ENDMETHOD.
ENDCLASS.

*----------------------------------------------------------------------*
* 3. LỚP CON CẤP 1: Nhân viên bán thời gian
*    Thưởng chuyên cần = 10% lương nếu làm đủ >= 80 giờ, ngược lại = 0
*----------------------------------------------------------------------*
CLASS lcl_nv_ban_thoi_gian DEFINITION INHERITING FROM lcl_nhan_vien FINAL.
  PUBLIC SECTION.
    METHODS:
      constructor
        IMPORTING iv_ma             TYPE string
                  iv_ten            TYPE string
                  VALUE(iv_so_gio)  TYPE i
                  VALUE(iv_don_gia) TYPE ty_tien,
      tinh_luong           REDEFINITION,
      tinh_thuong          REDEFINITION,
      get_cong_thuc_thuong REDEFINITION,
      get_loai             REDEFINITION.

  PRIVATE SECTION.
    CONSTANTS: c_gio_chuyen_can   TYPE i        VALUE 80,
               c_ty_le_chuyen_can TYPE ty_ty_le VALUE '0.100'.
    DATA: mv_so_gio  TYPE i,
          mv_don_gia TYPE ty_tien.
ENDCLASS.

CLASS lcl_nv_ban_thoi_gian IMPLEMENTATION.
  METHOD constructor.
    super->constructor( iv_ma = iv_ma iv_ten = iv_ten ).
    mv_so_gio  = iv_so_gio.
    mv_don_gia = iv_don_gia.
  ENDMETHOD.

  METHOD tinh_luong.
    rv_luong = mv_so_gio * mv_don_gia.
  ENDMETHOD.

  METHOD tinh_thuong.
    IF mv_so_gio >= c_gio_chuyen_can.
      rv_thuong = tinh_luong( ) * c_ty_le_chuyen_can.
    ELSE.
      rv_thuong = 0.
    ENDIF.
  ENDMETHOD.

  METHOD get_cong_thuc_thuong.
    rv_cong_thuc = '10% x Lương nếu >= 80 giờ, ngược lại 0'.
  ENDMETHOD.

  METHOD get_loai.
    rv_loai = 'Bán thời gian'.
  ENDMETHOD.
ENDCLASS.

*----------------------------------------------------------------------*
* 4. LỚP CON CẤP 2: Nhân viên kinh doanh (kế thừa từ NV chính thức)
*    Thưởng = Thưởng NV chính thức (super) + 2% doanh số
*             nếu doanh số đạt >= 150.000.000
*----------------------------------------------------------------------*
CLASS lcl_nv_kinh_doanh DEFINITION INHERITING FROM lcl_nv_chinh_thuc FINAL.
  PUBLIC SECTION.
    METHODS:
      constructor
        IMPORTING iv_ma              TYPE string
                  iv_ten             TYPE string
                  VALUE(iv_luong_cb) TYPE ty_tien
                  VALUE(iv_phu_cap)  TYPE ty_tien
                  VALUE(iv_doanh_so) TYPE ty_tien
                  VALUE(iv_ty_le)    TYPE ty_ty_le,
      tinh_luong           REDEFINITION,
      tinh_thuong          REDEFINITION,
      get_cong_thuc_thuong REDEFINITION,
      get_loai             REDEFINITION,
      hien_thi             REDEFINITION.

  PRIVATE SECTION.
    CONSTANTS: c_nguong_doanh_so TYPE ty_tien  VALUE '150000000',
               c_ty_le_thuong_ds TYPE ty_ty_le VALUE '0.020'.
    DATA: mv_doanh_so TYPE ty_tien,
          mv_ty_le    TYPE ty_ty_le.
ENDCLASS.

CLASS lcl_nv_kinh_doanh IMPLEMENTATION.
  METHOD constructor.
    super->constructor( iv_ma       = iv_ma
                        iv_ten      = iv_ten
                        iv_luong_cb = iv_luong_cb
                        iv_phu_cap  = iv_phu_cap ).
    mv_doanh_so = iv_doanh_so.
    mv_ty_le    = iv_ty_le.
  ENDMETHOD.

  METHOD tinh_luong.
    rv_luong = super->tinh_luong( ) + mv_doanh_so * mv_ty_le.
  ENDMETHOD.

  METHOD tinh_thuong.
    " Tái sử dụng công thức thưởng của lớp cha, rồi mở rộng thêm
    rv_thuong = super->tinh_thuong( ).
    IF mv_doanh_so >= c_nguong_doanh_so.
      rv_thuong = rv_thuong + mv_doanh_so * c_ty_le_thuong_ds.
    ENDIF.
  ENDMETHOD.

  METHOD get_cong_thuc_thuong.
    rv_cong_thuc = super->get_cong_thuc_thuong( ) &&
                   ' + 2% Doanh số (nếu DS >= 150tr)'.
  ENDMETHOD.

  METHOD get_loai.
    rv_loai = 'Kinh doanh'.
  ENDMETHOD.

  METHOD hien_thi.
    super->hien_thi( ).
    WRITE: / 'Doanh số    :', mv_doanh_so, 'VND',
           / 'Tỷ lệ HH    :', mv_ty_le.
  ENDMETHOD.
ENDCLASS.

*----------------------------------------------------------------------*
* 5. LỚP QUẢN LÝ: chỉ làm việc với kiểu lớp cha trừu tượng
*----------------------------------------------------------------------*
CLASS lcl_quan_ly_luong DEFINITION FINAL.
  PUBLIC SECTION.
    TYPES tt_nhan_vien TYPE STANDARD TABLE OF REF TO lcl_nhan_vien
                       WITH DEFAULT KEY.
    METHODS:
      them_nhan_vien
        IMPORTING io_nv TYPE REF TO lcl_nhan_vien,
      in_bang_luong,
      in_bang_thuong,                          " MỚI
      tinh_tong_luong
        RETURNING VALUE(rv_tong) TYPE ty_tien,
      tinh_tong_thuong                         " MỚI
        RETURNING VALUE(rv_tong) TYPE ty_tien.

  PRIVATE SECTION.
    DATA mt_nhan_vien TYPE tt_nhan_vien.
ENDCLASS.

CLASS lcl_quan_ly_luong IMPLEMENTATION.
  METHOD them_nhan_vien.
    APPEND io_nv TO mt_nhan_vien.
  ENDMETHOD.

  METHOD in_bang_luong.
    LOOP AT mt_nhan_vien INTO DATA(lo_nv).
      lo_nv->hien_thi( ).
      ULINE.
    ENDLOOP.
  ENDMETHOD.

  METHOD in_bang_thuong.
    " Cùng MỘT lời gọi lo_nv->tinh_thuong( ) nhưng mỗi dòng chạy
    " một công thức khác nhau tùy đối tượng thực tế -> ĐA HÌNH
    WRITE: / 'Mã NV', 9 'Loại NV', 25 'Thưởng (VND)', 47 'Công thức thưởng'.
    ULINE.
    LOOP AT mt_nhan_vien INTO DATA(lo_nv).
      DATA(lv_ma)        = lo_nv->get_ma( ).
      DATA(lv_loai)      = lo_nv->get_loai( ).
      DATA(lv_thuong)    = lo_nv->tinh_thuong( ).
      DATA(lv_cong_thuc) = lo_nv->get_cong_thuc_thuong( ).
      WRITE: / lv_ma,
             9      lv_loai,
             25(20) lv_thuong,
             47     lv_cong_thuc.
    ENDLOOP.
    ULINE.
  ENDMETHOD.

  METHOD tinh_tong_luong.
    LOOP AT mt_nhan_vien INTO DATA(lo_nv).
      rv_tong = rv_tong + lo_nv->tinh_luong( ).
    ENDLOOP.
  ENDMETHOD.

  METHOD tinh_tong_thuong.
    LOOP AT mt_nhan_vien INTO DATA(lo_nv).
      rv_tong = rv_tong + lo_nv->tinh_thuong( ).
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.

*----------------------------------------------------------------------*
* CHƯƠNG TRÌNH CHÍNH
*----------------------------------------------------------------------*
START-OF-SELECTION.

  " DATA(lo_loi) = NEW lcl_nhan_vien( ... ).
  " -> Lỗi cú pháp: không thể tạo đối tượng từ lớp trừu tượng

  DATA(lo_quan_ly) = NEW lcl_quan_ly_luong( ).

  " UP-CAST ngầm định: đối tượng lớp con gán vào tham chiếu lớp cha
  DATA lo_nhan_vien TYPE REF TO lcl_nhan_vien.

  lo_nhan_vien = NEW lcl_nv_chinh_thuc( iv_ma       = 'NV001'
                                        iv_ten      = 'Nguyễn Văn An'
                                        iv_luong_cb = '15000000'
                                        iv_phu_cap  = '2000000' ).
  lo_quan_ly->them_nhan_vien( lo_nhan_vien ).

  lo_nhan_vien = NEW lcl_nv_ban_thoi_gian( iv_ma      = 'NV002'
                                           iv_ten     = 'Trần Thị Bình'
                                           iv_so_gio  = 80
                                           iv_don_gia = '50000' ).
  lo_quan_ly->them_nhan_vien( lo_nhan_vien ).

  lo_nhan_vien = NEW lcl_nv_ban_thoi_gian( iv_ma      = 'NV004'
                                           iv_ten     = 'Phạm Thu Dung'
                                           iv_so_gio  = 40
                                           iv_don_gia = '45000' ).
  lo_quan_ly->them_nhan_vien( lo_nhan_vien ).

  lo_nhan_vien = NEW lcl_nv_kinh_doanh( iv_ma       = 'NV003'
                                        iv_ten      = 'Lê Hoàng Cường'
                                        iv_luong_cb = '12000000'
                                        iv_phu_cap  = '1000000'
                                        iv_doanh_so = '200000000'
                                        iv_ty_le    = '0.050' ).
  lo_quan_ly->them_nhan_vien( lo_nhan_vien ).

  "--- Chi tiết từng nhân viên ----------------------------------------
  WRITE: / '============ CHI TIẾT LƯƠNG & THƯỞNG ============'.
  ULINE.
  lo_quan_ly->in_bang_luong( ).

  "--- Bảng thưởng đa hình -------------------------------------------
  SKIP.
  WRITE: / '============ BẢNG THƯỞNG (ĐA HÌNH) ============'.
  lo_quan_ly->in_bang_thuong( ).

  DATA(lv_tong_luong)  = lo_quan_ly->tinh_tong_luong( ).
  DATA(lv_tong_thuong) = lo_quan_ly->tinh_tong_thuong( ).
  DATA(lv_tong_chi)    = lv_tong_luong + lv_tong_thuong.
  DATA(lv_so_nv)       = lcl_nhan_vien=>get_so_luong( ).

  WRITE: / 'Tổng số nhân viên :', lv_so_nv,
         / 'Tổng quỹ lương    :', lv_tong_luong,  'VND',
         / 'Tổng quỹ thưởng   :', lv_tong_thuong, 'VND',
         / 'Tổng chi trả      :', lv_tong_chi,    'VND'.
  SKIP.

  "--- DOWN-CAST: ép kiểu từ lớp cha xuống lớp con --------------------
  WRITE: / '============ MINH HỌA DOWN-CAST ============'.
  DATA lo_chinh_thuc TYPE REF TO lcl_nv_chinh_thuc.

  " lo_nhan_vien đang trỏ tới NV003 (kinh doanh, là con của chính thức)
  TRY.
      lo_chinh_thuc ?= lo_nhan_vien.
      WRITE: / 'Down-cast NV003 sang lcl_nv_chinh_thuc: thành công'.
      " Dù gọi qua tham chiếu kiểu lcl_nv_chinh_thuc, công thức thưởng
      " của lớp kinh doanh vẫn được dùng (dynamic binding)
      DATA(lv_thuong_nv3) = lo_chinh_thuc->tinh_thuong( ).
      WRITE: / 'Thưởng NV003 gọi qua tham chiếu NV chính thức:',
               lv_thuong_nv3, 'VND'.
    CATCH cx_sy_move_cast_error.
      WRITE: / 'Down-cast NV003: thất bại'.
  ENDTRY.

  " NV bán thời gian KHÔNG phải là NV chính thức -> ngoại lệ
  lo_nhan_vien = NEW lcl_nv_ban_thoi_gian( iv_ma      = 'NV005'
                                           iv_ten     = 'Võ Minh Em'
                                           iv_so_gio  = 60
                                           iv_don_gia = '45000' ).
  TRY.
      lo_chinh_thuc ?= lo_nhan_vien.
      WRITE: / 'Down-cast NV005 sang lcl_nv_chinh_thuc: thành công'.
    CATCH cx_sy_move_cast_error.
      WRITE: / 'Down-cast NV005 sang lcl_nv_chinh_thuc: thất bại',
             / '(NV bán thời gian không kế thừa từ NV chính thức)'.
  ENDTRY.
