REPORT Z_CREATE_CUSTOMER_LOGIN.

*----------------------------------------------------------
* Type Declarations
*----------------------------------------------------------
TYPES: BEGIN OF ty_kunnr,
         kunnr TYPE kunnr,
       END OF ty_kunnr.

*----------------------------------------------------------
* Data Declarations
*----------------------------------------------------------
DATA: lt_kunnr       TYPE TABLE OF ty_kunnr,
      ls_kunnr       TYPE ty_kunnr,
      ls_login       TYPE zsd_clogin,
      lv_kunnr       TYPE kunnr,
      lv_count       TYPE i VALUE 0,
      lt_zsd_clogin  TYPE TABLE OF zsd_clogin,
      ls_zsd_clogin  TYPE zsd_clogin.

CONSTANTS: c_default_pwd TYPE zcpass_de VALUE 'demo@123'.

*----------------------------------------------------------
* Display current contents of ZSD_CLOGIN
*----------------------------------------------------------
WRITE: / 'Current contents of ZSD_CLOGIN before processing:'.
SELECT * FROM zsd_clogin INTO TABLE lt_zsd_clogin.
IF lt_zsd_clogin IS INITIAL.
  WRITE: / 'No records found in ZSD_CLOGIN.'.
ELSE.
  WRITE: / 'MANDT', 10 'CUSTOMER_ID', 30 'PASSWORD'.
  WRITE: / '-----', 10 '-----------', 30 '--------'.
  LOOP AT lt_zsd_clogin INTO ls_zsd_clogin.
    WRITE: / ls_zsd_clogin-mandt,
             10 ls_zsd_clogin-customer_id,
             30 ls_zsd_clogin-password.
  ENDLOOP.
ENDIF.
WRITE: /.

*----------------------------------------------------------
* Fetch up to 10 customer numbers
*----------------------------------------------------------
SELECT kunnr FROM kna1 INTO TABLE lt_kunnr UP TO 20 ROWS.
IF lt_kunnr IS INITIAL.
  WRITE: / 'No customers found in KNA1 table.'.
  RETURN.
ELSE.
  WRITE: / 'Found', lines( lt_kunnr ), 'customers in KNA1.'.
ENDIF.

WRITE: / 'Raw KUNNR values retrieved from KNA1:'.
LOOP AT lt_kunnr INTO ls_kunnr.
  WRITE: / 'KUNNR:', ls_kunnr-kunnr.
ENDLOOP.

*----------------------------------------------------------
* Process each KUNNR
*----------------------------------------------------------
CLEAR lv_count.
LOOP AT lt_kunnr INTO ls_kunnr.
  CLEAR: ls_login, lv_kunnr.

  lv_kunnr = ls_kunnr-kunnr.

  IF lv_kunnr IS INITIAL.
    WRITE: / 'Warning: Empty KUNNR.'.
    CONTINUE.
  ENDIF.

  " Ensure ALPHA formatting (leading zeros)
  CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
    EXPORTING
      input  = lv_kunnr
    IMPORTING
      output = lv_kunnr.

  WRITE: / 'Processing Customer ID:', lv_kunnr LEFT-JUSTIFIED NO-ZERO.

  ls_login-customer_id = lv_kunnr.
  ls_login-password    = c_default_pwd.

  " Insert or update the login record
  TRY.
      MODIFY zsd_clogin FROM ls_login.
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
* Display updated ZSD_CLOGIN contents
*----------------------------------------------------------
WRITE: /.
WRITE: / 'Contents of ZSD_CLOGIN after processing:'.
CLEAR lt_zsd_clogin.
SELECT * FROM zsd_clogin INTO TABLE lt_zsd_clogin.
IF lt_zsd_clogin IS INITIAL.
  WRITE: / 'No records found in ZSD_CLOGIN.'.
ELSE.
  WRITE: / 'MANDT', 10 'CUSTOMER_ID', 30 'PASSWORD'.
  WRITE: / '-----', 10 '-----------', 30 '--------'.
  LOOP AT lt_zsd_clogin INTO ls_zsd_clogin.
    WRITE: / ls_zsd_clogin-mandt,
             10 ls_zsd_clogin-customer_id,
             30 ls_zsd_clogin-password.
  ENDLOOP.
ENDIF.
