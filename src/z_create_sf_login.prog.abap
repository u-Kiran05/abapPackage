*&---------------------------------------------------------------------*
*& Report Z_CREATE_SF_LOGIN
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT Z_CREATE_SF_LOGIN.



*----------------------------------------------------------*
* Type Declarations
*----------------------------------------------------------*
TYPES: BEGIN OF ty_bname,
         bname TYPE xubname,
       END OF ty_bname.

*----------------------------------------------------------*
* Data Declarations
*----------------------------------------------------------*
DATA: lt_bname       TYPE TABLE OF ty_bname,
      ls_bname       TYPE ty_bname,
      ls_login       TYPE zpp_sflogin,
      lv_bname       TYPE xubname,
      lv_count       TYPE i VALUE 0,
      lt_zpp_sflogin TYPE TABLE OF zpp_sflogin,
      ls_zpp_sflogin TYPE zpp_sflogin.

CONSTANTS: c_default_pwd TYPE zpp_pass_de VALUE 'demo@123'.

*----------------------------------------------------------*
* Display current contents of ZPP_SFLOGIN
*----------------------------------------------------------*
WRITE: / 'Current contents of ZPP_SFLOGIN before processing:'.
SELECT * FROM zpp_sflogin INTO TABLE lt_zpp_sflogin.
IF lt_zpp_sflogin IS INITIAL.
  WRITE: / 'No records found in ZPP_SFLOGIN.'.
ELSE.
  WRITE: / 'MANDT', 10 'BNAME', 30 'PASSWORD'.
  WRITE: / '-----', 10 '------', 30 '--------'.
  LOOP AT lt_zpp_sflogin INTO ls_zpp_sflogin.
    WRITE: / ls_zpp_sflogin-mandt,
             10 ls_zpp_sflogin-bname,
             30 ls_zpp_sflogin-pass.
  ENDLOOP.
ENDIF.
WRITE: /.

*----------------------------------------------------------*
* Fetch sample user list (limit to 10 test users from USR02)
*----------------------------------------------------------*
SELECT bname FROM usr02 INTO TABLE lt_bname UP TO 10 ROWS.
IF lt_bname IS INITIAL.
  WRITE: / 'No users found in USR02 table.'.
  RETURN.
ELSE.
  WRITE: / 'Found', lines( lt_bname ), 'users in USR02.'.
ENDIF.

*----------------------------------------------------------*
* Process each user
*----------------------------------------------------------*
CLEAR lv_count.
LOOP AT lt_bname INTO ls_bname.
  CLEAR: ls_login, lv_bname.

  lv_bname = ls_bname-bname.

  IF lv_bname IS INITIAL.
    WRITE: / 'Warning: Empty BNAME.'.
    CONTINUE.
  ENDIF.

  " Ensure ALPHA formatting if needed
  CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
    EXPORTING input = lv_bname
    IMPORTING output = lv_bname.

  WRITE: / 'Processing Shop Floor BNAME:', lv_bname LEFT-JUSTIFIED NO-ZERO.

  ls_login-bname = lv_bname.
  ls_login-pass  = c_default_pwd.

  " Insert or update the login record
  TRY.
      MODIFY zpp_sflogin FROM ls_login.
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

*----------------------------------------------------------*
* Display updated ZPP_SFLOGIN contents
*----------------------------------------------------------*
WRITE: /.
WRITE: / 'Contents of ZPP_SFLOGIN after processing:'.
CLEAR lt_zpp_sflogin.
SELECT * FROM zpp_sflogin INTO TABLE lt_zpp_sflogin.
IF lt_zpp_sflogin IS INITIAL.
  WRITE: / 'No records found in ZPP_SFLOGIN.'.
ELSE.
  WRITE: / 'MANDT', 10 'BNAME', 30 'PASSWORD'.
  WRITE: / '-----', 10 '------', 30 '--------'.
  LOOP AT lt_zpp_sflogin INTO ls_zpp_sflogin.
    WRITE: / ls_zpp_sflogin-mandt,
             10 ls_zpp_sflogin-bname,
             30 ls_zpp_sflogin-pass.
  ENDLOOP.
ENDIF.
