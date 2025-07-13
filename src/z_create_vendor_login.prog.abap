REPORT Z_CREATE_VENDOR_LOGIN.

*----------------------------------------------------------
* Type Declarations
*----------------------------------------------------------
TYPES: BEGIN OF ty_lifnr,
         lifnr TYPE lifnr,
       END OF ty_lifnr.

*----------------------------------------------------------
* Data Declarations
*----------------------------------------------------------
DATA: lt_lifnr       TYPE TABLE OF ty_lifnr,
      ls_lifnr       TYPE ty_lifnr,
      ls_login       TYPE zmm_vlogin_t,
      lv_lifnr       TYPE lifnr,
      lv_count       TYPE i VALUE 0,
      lt_zmm_vlogin  TYPE TABLE OF zmm_vlogin_t,
      ls_zmm_vlogin  TYPE zmm_vlogin_t.

CONSTANTS: c_default_pwd TYPE zmm_vpass_de VALUE 'demo@123'.

*----------------------------------------------------------
* Display current contents of ZMM_VLOGIN_T
*----------------------------------------------------------
WRITE: / 'Current contents of ZMM_VLOGIN_T before processing:'.
SELECT * FROM zmm_vlogin_t INTO TABLE lt_zmm_vlogin.
IF lt_zmm_vlogin IS INITIAL.
  WRITE: / 'No records found in ZMM_VLOGIN_T.'.
ELSE.
  WRITE: / 'MANDT', 10 'VENDOR_ID', 30 'PASSWORD'.
  WRITE: / '-----', 10 '---------', 30 '--------'.
  LOOP AT lt_zmm_vlogin INTO ls_zmm_vlogin.
    WRITE: / ls_zmm_vlogin-mandt,
             10 ls_zmm_vlogin-vendor_id,
             30 ls_zmm_vlogin-password.
  ENDLOOP.
ENDIF.
WRITE: /.

*----------------------------------------------------------
* Fetch up to 20 vendor numbers from LFA1
*----------------------------------------------------------
SELECT lifnr FROM lfa1 INTO TABLE lt_lifnr UP TO 20 ROWS.
IF lt_lifnr IS INITIAL.
  WRITE: / 'No vendors found in LFA1 table.'.
  RETURN.
ELSE.
  WRITE: / 'Found', lines( lt_lifnr ), 'vendors in LFA1.'.
ENDIF.

WRITE: / 'Raw LIFNR values retrieved from LFA1:'.
LOOP AT lt_lifnr INTO ls_lifnr.
  WRITE: / 'LIFNR:', ls_lifnr-lifnr.
ENDLOOP.

*----------------------------------------------------------
* Process each LIFNR
*----------------------------------------------------------
CLEAR lv_count.
LOOP AT lt_lifnr INTO ls_lifnr.
  CLEAR: ls_login, lv_lifnr.

  lv_lifnr = ls_lifnr-lifnr.

  IF lv_lifnr IS INITIAL.
    WRITE: / 'Warning: Empty LIFNR.'.
    CONTINUE.
  ENDIF.

  " Ensure ALPHA formatting (leading zeros)
  CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
    EXPORTING
      input  = lv_lifnr
    IMPORTING
      output = lv_lifnr.

  WRITE: / 'Processing Vendor ID:', lv_lifnr LEFT-JUSTIFIED NO-ZERO.

  ls_login-mandt     = sy-mandt.          " Client
  ls_login-vendor_id = lv_lifnr.          " Vendor ID (LIFNR)
  ls_login-password  = c_default_pwd.     " Default password

  " Insert or update the login record
  TRY.
      MODIFY zmm_vlogin_t FROM ls_login.
      IF sy-subrc = 0.
        ADD 1 TO lv_count.
        WRITE: '→ Inserted/Updated OK'.
      ELSE.
        WRITE: '→ Modify failed. sy-subrc =', sy-subrc.
      ENDIF.
    CATCH cx_sy_open_sql_db INTO DATA(lx_sql).
      WRITE: '→ DB Error:', lx_sql->get_text( ).
  ENDTRY.
ENDLOOP.

IF lv_count > 0.
  COMMIT WORK.
  WRITE: / 'Total records processed:', lv_count.
ELSE.
  WRITE: / 'No records processed.'.
ENDIF.

*----------------------------------------------------------
* Display updated ZMM_VLOGIN_T contents
*----------------------------------------------------------
WRITE: /.
WRITE: / 'Contents of ZMM_VLOGIN_T after processing:'.
CLEAR lt_zmm_vlogin.
SELECT * FROM zmm_vlogin_t INTO TABLE lt_zmm_vlogin.
IF lt_zmm_vlogin IS INITIAL.
  WRITE: / 'No records found in ZMM_VLOGIN_T.'.
ELSE.
  WRITE: / 'MANDT', 10 'VENDOR_ID', 30 'PASSWORD'.
  WRITE: / '-----', 10 '---------', 30 '--------'.
  LOOP AT lt_zmm_vlogin INTO ls_zmm_vlogin.
    WRITE: / ls_zmm_vlogin-mandt,
             10 ls_zmm_vlogin-vendor_id,
             30 ls_zmm_vlogin-password.
  ENDLOOP.
ENDIF.
