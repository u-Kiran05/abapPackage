REPORT Z_CREATE_EMPLOYEE_LOGIN.

*----------------------------------------------------------
* Type Declarations
*----------------------------------------------------------
TYPES: BEGIN OF ty_pernr,
         pernr TYPE pernr_d,
       END OF ty_pernr.

*----------------------------------------------------------
* Data Declarations
*----------------------------------------------------------
DATA: lt_pernr       TYPE TABLE OF ty_pernr,
      ls_pernr       TYPE ty_pernr,
      ls_login       TYPE zhcm_elogin,
      lv_pernr       TYPE pernr_d,
      lv_count       TYPE i VALUE 0,
      lt_zhcm_elogin TYPE TABLE OF zhcm_elogin,
      ls_zhcm_elogin TYPE zhcm_elogin.

CONSTANTS: c_default_pwd TYPE zhcm_epass_de VALUE 'demo@123'.

*----------------------------------------------------------
* Display current contents of ZHCM_ELOGIN
*----------------------------------------------------------
WRITE: / 'Current contents of ZHCM_ELOGIN before processing:'.
SELECT * FROM zhcm_elogin INTO TABLE lt_zhcm_elogin.
IF lt_zhcm_elogin IS INITIAL.
  WRITE: / 'No records found in ZHCM_ELOGIN.'.
ELSE.
  WRITE: / 'MANDT', 10 'EMPLOYEE_ID', 30 'EMPLOYEE_PASS'.
  WRITE: / '-----', 10 '------------', 30 '--------------'.
  LOOP AT lt_zhcm_elogin INTO ls_zhcm_elogin.
    WRITE: / ls_zhcm_elogin-mandt,
             10 ls_zhcm_elogin-employee_id,
             30 ls_zhcm_elogin-employee_pass.
  ENDLOOP.
ENDIF.
WRITE: /.

*----------------------------------------------------------
* Fetch up to 20 employees from PA0001
*----------------------------------------------------------
SELECT pernr FROM pa0001 INTO TABLE lt_pernr UP TO 20 ROWS.
IF lt_pernr IS INITIAL.
  WRITE: / 'No employee records found in PA0001.'.
  RETURN.
ELSE.
  WRITE: / 'Found', lines( lt_pernr ), 'employees in PA0001.'.
ENDIF.

*----------------------------------------------------------
* Process each Employee PERNR
*----------------------------------------------------------
CLEAR lv_count.
LOOP AT lt_pernr INTO ls_pernr.
  CLEAR: ls_login, lv_pernr.

  lv_pernr = ls_pernr-pernr.

  IF lv_pernr IS INITIAL.
    WRITE: / 'Warning: Empty Employee ID (PERNR).'.
    CONTINUE.
  ENDIF.

  " Ensure ALPHA formatting
  CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
    EXPORTING
      input  = lv_pernr
    IMPORTING
      output = lv_pernr.

  WRITE: / 'Processing Employee ID:', lv_pernr LEFT-JUSTIFIED NO-ZERO.

  ls_login-employee_id   = lv_pernr.
  ls_login-employee_pass = c_default_pwd.

  " Insert or update login record
  TRY.
      MODIFY zhcm_elogin FROM ls_login.
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
  WRITE: / 'Total employee records processed:', lv_count.
ELSE.
  WRITE: / 'No records processed.'.
ENDIF.

*----------------------------------------------------------
* Display updated contents
*----------------------------------------------------------
WRITE: /.
WRITE: / 'Contents of ZHCM_ELOGIN after processing:'.
CLEAR lt_zhcm_elogin.
SELECT * FROM zhcm_elogin INTO TABLE lt_zhcm_elogin.
IF lt_zhcm_elogin IS INITIAL.
  WRITE: / 'No records found.'.
ELSE.
  WRITE: / 'MANDT', 10 'EMPLOYEE_ID', 30 'EMPLOYEE_PASS'.
  WRITE: / '-----', 10 '------------', 30 '--------------'.
  LOOP AT lt_zhcm_elogin INTO ls_zhcm_elogin.
    WRITE: / ls_zhcm_elogin-mandt,
             10 ls_zhcm_elogin-employee_id,
             30 ls_zhcm_elogin-employee_pass.
  ENDLOOP.
ENDIF.
